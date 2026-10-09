extends Node
var passed := 0
var failed := 0
func check(condition: bool, name: String):
	if condition: passed += 1; print("PASS ",name)
	else: failed += 1; push_error("FAIL "+name)
func _ready():
	get_tree().create_timer(70).timeout.connect(func(): push_error("Test runner timed out"); get_tree().quit(2))
	await get_tree().process_frame
	State.reset()
	check(State.items.size() == 20,"content: twelve equipment and eight consumables/materials")
	check(State.npcs.size() == 8 and State.enemies.size() == 7,"content: eight NPCs and six enemy types plus boss")
	check(State.damage(10,20) == 1,"damage has minimum floor")
	check(State.damage(20,4,true) < State.damage(20,4),"blocking reduces damage")
	check(not State.add_item("potion",-1),"negative item quantity rejected")
	check(not State.remove_item("potion",0),"zero removal rejected")
	check(State.add_item("potion",2) and State.s.inventory.potion == 5,"inventory stacking")
	check(not State.sell("rust_sword"),"equipped weapon cannot be sold")
	check(not State.sell("axe"),"nonexistent item cannot be sold")
	State.s.crowns = 0
	check(not State.buy("axe") and not State.s.inventory.has("axe"),"insufficient currency cannot buy")
	State.s.crowns = 100
	check(State.buy("axe") and State.s.crowns == 35,"valid purchase deducts price")
	var before := State.stat("attack")
	check(State.equip("axe") and State.stat("attack") > before,"equipment changes attack")
	check(not State.equip("bow"),"cannot equip absent item")
	check(not State.upgrade(),"upgrade without materials rejected")
	State.add_item("ore",3)
	before = State.stat("attack")
	check(State.upgrade() and State.stat("attack") == before+4,"upgrade increases damage and consumes costs")
	State.s.hp = 10
	check(State.use("potion") and State.s.hp == 65,"consumable restores health")
	check(not State.use("ore"),"materials cannot be consumed")
	State.gain_xp(100)
	check(State.s.level == 2 and State.s.points == 3,"XP levels and awards points")
	before = State.stat("hp")
	check(State.spend_attribute("Vitality") and State.stat("hp") == before+12,"attribute affects health")
	check(State.unlock("Ember") and not State.unlock("Ember"),"skill cost and duplicate prevention")
	State.accept("herbs")
	State.add_item("herb",3)
	check(State.turn_in("herbs"),"validated quest turn-in rewards and consumes items")
	var crowns: int = State.s.crowns
	check(not State.reward("herbs") and State.s.crowns == crowns,"duplicate quest rewards rejected")
	check(not State.reward("bell"),"unaccepted quest cannot reward")
	State.s.memory["tovin_helped"] = true
	State.s.flags["boss"] = true
	check(State.save_game(3),"save writes atomically")
	var snapshot := JSON.stringify(State.s)
	State.reset()
	check(State.load_game(3) and State.s == JSON.parse_string(snapshot),"save restores all state including equipment and memory")
	check(not State.load_game(99),"missing slot rejected")
	var malformed := State.s.duplicate(true); malformed.position = ["bad",null]
	check(not State.valid_save(malformed),"malformed position rejected without execution")
	malformed = State.s.duplicate(true); malformed.attributes = {}
	check(not State.valid_save(malformed),"missing attribute schema rejected")
	var corrupt := State.s.duplicate(true); corrupt.inventory["unknown"] = 2
	check(not State.valid_save(corrupt),"invalid item ID in save rejected")
	State.save_game(3)
	var f := FileAccess.open("user://slot_3.json",FileAccess.WRITE); f.store_string("broken"); f.close()
	check(State.load_game(3),"corrupt primary recovers from backup")
	State.reset()
	var g = load("res://scenes/main.tscn").instantiate()
	add_child(g)
	await get_tree().process_frame
	check(g.mode == "title","title screen loads")
	g.close_menu()
	var start: Vector2 = g.player.position
	Input.action_press("right")
	await get_tree().create_timer(.25).timeout
	Input.action_release("right")
	check(g.player.position.x > start.x+15,"input moves CharacterBody2D")
	g.player.position = Vector2(1400,480)
	Input.action_press("right")
	await get_tree().create_timer(.3).timeout
	Input.action_release("right")
	check(g.player.position.x < 1420,"world boundary collision")
	g.talk("ilya")
	check(g.mode == "dialogue" and g.player.locked,"NPC interaction opens paused choice dialogue")
	State.accept("bell"); State.accept("elites")
	check(g.dialogue.node_for("mara","past").text != g.dialogue.node_for("brann","past").text,"NPC histories have distinct authored voices")
	check(not g.dialogue.has_method("ask") and g.dialogue.find_children("*","HTTPRequest",true,false).is_empty(),"dialogue has no AI or HTTP execution path")
	g.close_menu()
	g.load_map("forest",Vector2(100,480))
	await get_tree().physics_frame
	check(g.enemies.get_child_count() == 10,"forest spawns enemies and two elites")
	g.interact({"kind":"door","id":"crypt"})
	check(State.s.map == "forest","crypt locked without sigil")
	var enemy = g.enemies.get_child(0)
	g.player.position = enemy.position+Vector2(30,0)
	enemy.state = "Attack"; enemy.timer = .01
	var hp: float = State.s.hp
	await get_tree().create_timer(.1).timeout
	check(State.s.hp < hp,"enemy attacks player")
	g.player.immunity = 1
	hp = State.s.hp; g.player.hurt(100,Vector2.ZERO)
	check(State.s.hp == hp,"invulnerability prevents damage")
	g.player.immunity = 0
	g.player.position = enemy.position+Vector2(30,0)
	before = enemy.hp
	g.attack(g.player.position,Vector2.LEFT,false)
	check(enemy.hp < before,"directional melee damages enemy")
	for e in g.enemies.get_children():
		if e.stable_id in ["sentinel","lost_hound"]: e.hurt(9999,Vector2.ZERO)
	await get_tree().process_frame
	check(State.s.inventory.get("key",0) == 1,"sentinel defeat drops crypt sigil")
	g.interact({"kind":"chest","id":"forest_charm"})
	g.interact({"kind":"chest","id":"forest_charm"})
	check(State.s.inventory.get("charm",0) == 1,"chest rewards exactly once")
	g.interact({"kind":"door","id":"crypt"})
	await get_tree().physics_frame
	check(State.s.map == "crypt","sigil unlocks crypt transition")
	for e in g.enemies.get_children():
		if e.stable_id == "crypt_knight": e.hurt(9999,Vector2.ZERO)
	await get_tree().process_frame
	check(State.s.quests.elites == "complete","all three elite encounters complete side quest")
	var boss
	for e in g.enemies.get_children():
		if e.kind == "boss": boss = e
	g.player.position = Vector2(1150,480)
	boss.hp = boss.max_hp*.5
	await get_tree().create_timer(.03).timeout
	check(boss.phase == 2,"boss phase two transition")
	boss.hp = boss.max_hp*.2
	await get_tree().create_timer(.03).timeout
	check(boss.phase == 3,"boss phase three transition")
	boss.hurt(9999,Vector2.ZERO)
	await get_tree().process_frame
	check(State.s.flags.get("boss",false) and State.s.inventory.has("bellblade"),"boss defeat persists and awards unique weapon")
	g.close_menu()
	g.interact({"kind":"door","id":"shrine"})
	check(State.s.map == "shrine","boss unlocks shrine")
	g.interact({"kind":"shrine","id":"ending"})
	check(State.s.flags.get("ending",false) and State.s.quests.bell == "complete","chapter conclusion completes main quest")
	check(State.load_game(0) and State.s.flags.get("ending",false),"chapter completion survives autosave restoration")
	g.close_menu()
	State.s.hp = 1; g.player.immunity = 0; g.player.hurt(20,Vector2.ZERO)
	check(g.mode == "death","player death shows respawn interface")
	g.close_menu()
	g.close_menu()
	State.reset()
	State.accept("herbs")
	var gold: int = State.s.crowns
	check(not State.turn_in("herbs") and State.s.crowns == gold,"missing quest items cannot claim a reward")
	check(not State.reward("herbs"),"unfinished quest cannot bypass objectives")
	State.add_item("herb",3)
	g.talk("sister")
	await get_tree().process_frame
	check(g.ui.panel.find_children("*","LineEdit",true,false).is_empty(),"NPC dialogue contains no text input")
	var focus = get_viewport().gui_get_focus_owner()
	check(focus is Button and focus.get_parent().get_parent() is ScrollContainer,"conversation choice receives keyboard focus")
	g.select_dialogue({"next":"work"})
	g.select_dialogue({"next":"work","action":{"kind":"turn_in","quest":"herbs"}})
	check(State.s.quests.herbs == "complete" and State.s.crowns == gold+35 and not State.s.inventory.has("herb"),"dialogue turn-in consumes materials and pays exact Crowns")
	check("35 Crowns" in g.dialogue_text.text,"quest receipt remains visible in the conversation")
	check(not State.turn_in("herbs") and State.s.crowns == gold+35,"repeated turn-in cannot duplicate rewards")
	State.add_item("charm"); State.equip("charm"); State.accept("charm")
	check(State.turn_in("charm") and not State.s.equipment.has("accessory") and State.valid_save(State.s),"returning an equipped quest charm keeps equipment and saves valid")
	State.s.flags.sentinel = true; State.s.flags.lost_hound = true; State.s.flags.crypt_knight = true
	State.accept("elites")
	check(State.s.quests.elites == "complete","accepting elite quest after victories still pays once")
	State.s.flags.ending = true; State.accept("bell")
	check(State.s.quests.bell == "complete","late main-quest acceptance recovers the ending reward")
	State.add_item("ore",3); State.accept("iron")
	gold = State.s.crowns
	check(State.turn_in("iron") and State.s.crowns == gold+40 and not State.s.inventory.has("ore"),"iron delivery consumes exact materials and pays once")
	State.s.quests.erase("charm"); State.add_item("charm"); State.equip("charm")
	gold = State.s.crowns
	check(State.turn_in("charm","keep") and State.s.equipment.accessory == "charm" and State.s.crowns == gold+40,"keep-charm branch preserves equipment and rewards")
	check(State.save_game(2) and State.load_game(2) and not State.turn_in("charm","keep"),"turn-in uniqueness survives save restoration")
	var legacy := State.s.duplicate(true); legacy.settings["ollama"] = true
	check(State.valid_save(legacy),"legacy version-one conversation preferences remain loadable")
	var legacy_file := FileAccess.open("user://slot_1.json",FileAccess.WRITE); legacy_file.store_string(JSON.stringify(legacy)); legacy_file.close()
	check(State.load_game(1) and State.s.inventory == legacy.inventory and State.s.memory == legacy.memory and State.s.quests == legacy.quests,"loading legacy saves preserves inventory, relationships and quest progress")
	check(State.valid_save(State.s) and not State.s.settings.has("ollama"),"new offline saves require no AI preference")
	State.s.memory.tovin_helped = true
	check("brought him home" in g.dialogue.node_for("tovin","root").text,"relationships change authored greetings")
	State.s.flags.boss = true
	check("anvil sounds louder" in g.dialogue.node_for("brann","root").text,"boss defeat changes NPC dialogue")
	State.s.flags.erase("boss"); State.s.memory.nell_spoken = true
	check("chair is still warm" in g.dialogue.node_for("nell","root").text,"previous conversations change greetings")
	check(g.dialogue.execute("mara",{"kind":"turn_in","quest":"iron"}).begins_with("That request"),"authored actions validate NPC quest ownership")
	for npc in State.npcs:
		var tree: Dictionary = g.dialogue.trees[npc]
		var valid := true
		for node_id in tree.nodes:
			for option in tree.nodes[node_id].choices:
				if not tree.nodes.has(option.next): valid = false
		check(valid,"stable dialogue links for "+npc)
		g.talk(npc)
		await get_tree().process_frame
		check(g.dialogue_text.text != "" and g.ui.panel.find_children("*","TextureRect",true,false).size() > 0,"portrait and authored opening for "+npc)
	g.talk("brann","work")
	var options: Array = g.dialogue.node_for("brann","work").choices
	check(not options.any(func(c): return c.get("action",{}).get("kind","") == "accept"),"completed quests cannot be accepted again")
	State.reset(); g.talk("brann","work")
	g.select_dialogue({"next":"work","action":{"kind":"accept","quest":"iron"}})
	check(State.s.quests.iron == "active","dialogue acceptance activates existing quest state")
	var no_reward: int = State.s.crowns
	g.select_dialogue({"next":"work","action":{"kind":"turn_in","quest":"iron"}})
	check(State.s.crowns == no_reward and "Not yet" in g.dialogue_text.text,"dialogue missing-material response preserves currency")
	g.talk("mara"); g.select_dialogue({"next":"root","action":{"kind":"shop"}})
	check(g.service_npc == "mara" and g.player.locked,"shop service keeps movement and attacks locked")
	g.confirm_purchase("potion")
	await get_tree().process_frame
	var buy: Button
	for control in g.ui.panel.find_children("*","Button",true,false):
		if control.text == "Buy": buy = control
	var old_count: int = State.s.inventory.potion
	buy.pressed.emit()
	check(State.s.inventory.potion == old_count+1 and State.s.crowns == no_reward-State.items.potion.price,"explicit shop confirmation performs one validated purchase")
	g.return_to_npc()
	check(g.mode == "dialogue" and g.active_npc == "mara" and g.player.locked,"service Back returns to conversation")
	g.talk("brann"); State.add_item("ore",3); State.s.crowns = 100
	g.select_dialogue({"next":"root","action":{"kind":"upgrade"}})
	await get_tree().process_frame
	for control in g.ui.panel.find_children("*","Button",true,false):
		if control.text == "Improve weapon": control.pressed.emit(); break
	check(State.s.upgrades.get("rust_sword",0) == 1 and State.s.crowns == 75,"forge choice opens working validated upgrades")
	g.return_to_npc(); g.talk("sister"); State.s.hp = 10
	g.select_dialogue({"next":"root","action":{"kind":"heal"}})
	await get_tree().process_frame
	for control in g.ui.panel.find_children("*","Button",true,false):
		if control.text == "Accept healing": control.pressed.emit(); break
	check(State.s.hp == State.stat("hp") and g.mode == "dialogue" and State.s.crowns == 67,"healing pays once and returns to dialogue")
	g.talk("nell"); g.select_dialogue({"next":"root","action":{"kind":"rest"}})
	await get_tree().process_frame
	for control in g.ui.panel.find_children("*","Button",true,false):
		if control.text == "Take a room": control.pressed.emit(); break
	check(State.s.crowns == 62 and State.load_game(0),"inn service restores and saves through its choice")
	g.talk("mara","past")
	var escape := InputEventKey.new(); escape.physical_keycode = KEY_ESCAPE; escape.keycode = KEY_ESCAPE; escape.pressed = true
	Input.parse_input_event(escape); await get_tree().process_frame
	escape.pressed = false; Input.parse_input_event(escape)
	check(g.mode == "dialogue" and g.dialogue_node == "root","Escape backs out of a nested dialogue branch")
	g.select_dialogue({"next":"root","action":{"kind":"goodbye"}})
	check(g.mode == "play" and not g.player.locked,"Goodbye restores gameplay input")
	g.close_menu(); State.reset(); g.load_map("village",Vector2(480,480))
	await get_tree().process_frame
	g.close_menu()
	g.player.immunity = 0; g.player.stun_resistance = 0
	g.player.hurt(8,Vector2.ZERO,"Stun")
	check(g.player.statuses.get("Stun",0) <= .2 and g.player.immunity >= .9,"stun is brief and protected by longer hit immunity")
	await get_tree().create_timer(.3).timeout
	check(not g.player.statuses.has("Stun"),"stun expires before the next damaging hit can land")
	g.player.immunity = 0; g.player.hurt(8,Vector2.ZERO,"Stun")
	check(not g.player.statuses.has("Stun"),"repeat stun rejected during recovery resistance")
	g.player.immunity = 0; g.player.statuses.Stun = .2; g.player.statuses.Slow = .8
	Input.action_press("dodge")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("dodge")
	check(not g.player.statuses.has("Stun") and not g.player.statuses.has("Slow"),"dodge breaks stun and slow")
	check(not g.world.walkable(Vector2(100,100)),"flooded village edge blocks movement")
	check(g.world.layout.buildings.size() == 4 and g.world.layout.water.size() == 1,"town has distinct functional buildings and geography")
	check(g.world.darkness.color.r < .6,"world darkness is separated from the UI")
	for id in ["village","forest","crypt","shrine"]:
		g.world.setup(id)
		for object in g.world.objects:
			if object.kind in ["npc","checkpoint","door"]: check(g.world.walkable(object.pos),"accessible "+id+" "+object.id)
	check(g.world.walkable(g.world.safe_position(Vector2(0,0))),"old or unsafe spawn positions relocate to open ground")
	g.queue_free()
	await get_tree().process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
