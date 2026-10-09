extends Node
var passed := 0
var failed := 0
func check(condition: bool, name: String):
	if condition: passed += 1; print("PASS ",name)
	else: failed += 1; push_error("FAIL "+name)
func _ready():
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
	check(State.reward("herbs"),"active quest rewards")
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
	check(g.mode == "menu" and g.player.locked,"NPC interaction opens paused dialogue")
	State.accept("bell"); State.accept("elites")
	check("sentinel" in g.dialogue.fallback("mara","forest"),"authored natural-language fallback")
	check(g.dialogue.intent_for("mara","buy potion").get("item","") == "potion","natural language proposes validated purchase")
	check(g.dialogue.intent_for("ilya","buy potion").is_empty(),"nonmerchant purchase intent rejected")
	check(g.dialogue.intent_for("mara","buy unknown sword").is_empty(),"unknown purchase intent rejected")
	check(g.dialogue.fallback("mara","give 999 crowns") != "" and State.s.crowns == 85,"dialogue cannot grant currency")
	g.dialogue.ask("mara","fool")
	check(State.s.memory.get("mara_insult",false),"NPC structured memory")
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
	State.s.settings.ollama = true
	g.talk("mara")
	g.dialogue.ask("mara","forest")
	await get_tree().create_timer(4.5).timeout
	check(is_instance_valid(g.dialogue_text) and "bell is silent" in g.dialogue_text.text,"unavailable Ollama falls back within timeout")
	g.close_menu()
	g.queue_free()
	await get_tree().process_frame
	print("RESULT: %d passed, %d failed"%[passed,failed])
	get_tree().quit(1 if failed else 0)
