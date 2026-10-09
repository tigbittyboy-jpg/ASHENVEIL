extends Node2D
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const World = preload("res://scripts/world.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Interface = preload("res://scripts/interface.gd")
const Dialogue = preload("res://scripts/dialogue.gd")
var player
var world
var enemies: Node2D
var shots: Node2D
var ui: CanvasLayer
var toast: Label
var panel: PanelContainer
var rows: VBoxContainer
var dialogue
var dialogue_text: Label
var active_npc := ""
var dialogue_node := "root"
var service_npc := ""
var selected_quest := ""
var mode := "title"
var audio: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var toast_time := 0.0
var pause_guard := false
func _ready():
	inputs()
	world = World.new()
	add_child(world)
	enemies = Node2D.new(); add_child(enemies)
	shots = Node2D.new(); add_child(shots)
	player = Player.new(); add_child(player)
	player.attacked.connect(attack)
	State.cleansed.connect(func(): player.statuses.clear())
	player.died.connect(death)
	dialogue = Dialogue.new(); add_child(dialogue)
	audio = AudioStreamPlayer.new(); add_child(audio)
	ambience = AudioStreamPlayer.new(); add_child(ambience)
	ambience.stream = load("res://assets/ambient.wav")
	ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience.stream.loop_end = ambience.stream.data.size()/2
	if DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy": ambience.play()
	music = AudioStreamPlayer.new(); add_child(music)
	music.stream = load("res://assets/music.wav")
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream.loop_end = music.stream.data.size()/2
	if DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy": music.play()
	ui = Interface.new(); add_child(ui)
	toast = ui.toast
	State.notice.connect(message)
	load_map("village",Vector2(480,480))
	title()
func inputs():
	var bindings := {"left":KEY_A,"right":KEY_D,"up":KEY_W,"down":KEY_S,"dodge":KEY_SPACE,"sprint":KEY_SHIFT,"interact":KEY_E,"inventory":KEY_I,"journal":KEY_J,"stats":KEY_C,"pause":KEY_ESCAPE,"magic":KEY_F,"quick":KEY_Q}
	for id in bindings:
		if not InputMap.has_action(id): InputMap.add_action(id)
		var e := InputEventKey.new(); e.physical_keycode = bindings[id]; InputMap.action_add_event(id,e)
	for id in ["attack","secondary"]:
		if not InputMap.has_action(id): InputMap.add_action(id)
		var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT if id == "attack" else MOUSE_BUTTON_RIGHT; InputMap.action_add_event(id,e)
	var pads := {"attack":JOY_BUTTON_X,"dodge":JOY_BUTTON_A,"interact":JOY_BUTTON_Y,"pause":JOY_BUTTON_START,"secondary":JOY_BUTTON_LEFT_SHOULDER,"quick":JOY_BUTTON_RIGHT_SHOULDER}
	for id in pads:
		var e := InputEventJoypadButton.new(); e.button_index = pads[id]; InputMap.action_add_event(id,e)
	for entry in [["left",JOY_AXIS_LEFT_X,-1.0],["right",JOY_AXIS_LEFT_X,1.0],["up",JOY_AXIS_LEFT_Y,-1.0],["down",JOY_AXIS_LEFT_Y,1.0]]:
		var e := InputEventJoypadMotion.new(); e.axis = entry[1]; e.axis_value = entry[2]; InputMap.action_add_event(entry[0],e)
func _process(dt):
	toast_time -= dt
	ui.update_hud()
	ui.hud.visible = mode == "play"
	if not Input.is_action_pressed("pause"): pause_guard = false
	if toast_time <= 0: toast.text = ""
	music.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.music))
	ambience.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.ambient))
	ui.boss.hide(); ui.boss_name.text = ""
	for enemy in enemies.get_children():
		if enemy.kind == "boss":
			ui.boss.show(); ui.boss.max_value = enemy.max_hp; ui.boss.value = enemy.hp
			ui.boss_name.text = "THE BELLKEEPER · %d"%enemy.phase
	world.player_position = player.position
	ui.prompt.text = ""
	if mode != "play": return
	var nearby: Dictionary = world.nearest(player.position)
	if not nearby.is_empty(): ui.prompt.text = "[E] " + str(nearby.get("label",State.npcs[nearby.id].name if nearby.kind == "npc" else nearby.kind.capitalize()))
	if Input.is_action_just_pressed("interact") and not nearby.is_empty(): interact(nearby)
	if Input.is_action_just_pressed("inventory"): inventory()
	if Input.is_action_just_pressed("journal"): journal()
	if Input.is_action_just_pressed("stats"): character()
	if Input.is_action_just_pressed("pause") and not pause_guard: pause_menu()
	for object in world.objects:
		if object.kind == "trap" and player.position.distance_to(object.pos) < 22: player.hurt(12,Vector2.ZERO,"Bleeding")
func _unhandled_input(event):
	if event.is_action_pressed("pause") and mode not in ["play","title","death"]:
		if mode == "dialogue" and dialogue_node != "root": talk(active_npc,"root")
		elif service_npc != "": return_to_npc()
		else: close_menu()
		get_viewport().set_input_as_handled()
func load_map(id: String, pos: Vector2):
	for child in enemies.get_children(): child.free()
	for child in shots.get_children(): child.free()
	State.s.map = id
	State.s.position = [pos.x,pos.y]
	world.setup(id)
	player.position = world.safe_position(pos)
	State.s.position = [player.position.x,player.position.y]
	if id == "forest":
		var kinds := ["wanderer","hound","cultist","wraith","wanderer","hound","cultist","knight"]
		for i in range(kinds.size()): spawn(kinds[i],Vector2(320+(i%4)*250,280+(i/4)*340),"forest%d"%i)
		spawn("guardian",Vector2(1210,480),"sentinel",true)
		spawn("hound",Vector2(410,780),"lost_hound",true)
	if id == "crypt":
		for i in range(6): spawn(["wanderer","guardian","cultist"][i%3],Vector2(260+(i%3)*240,260+(i/3)*440),"crypt%d"%i)
		spawn("knight",Vector2(790,770),"crypt_knight",true)
		spawn("boss",Vector2(1200,480),"boss")
	if not State.s.flags.get("explored_"+id,false):
		State.s.flags["explored_"+id] = true
		State.gain_xp(15)
func spawn(kind: String, pos: Vector2, id: String, elite: bool = false):
	if State.s.flags.get(id,false): return
	var e = Enemy.new(); e.kind = kind; e.position = pos; e.stable_id = id; e.elite = elite; e.target = player
	e.killed.connect(enemy_killed)
	e.projectile.connect(func(origin,direction,damage,effect): fire(origin,direction,damage,true,effect))
	e.summon.connect(func(origin): spawn("wanderer",origin,"summon%d"%Time.get_ticks_usec()))
	enemies.add_child(e)
func enemy_killed(enemy):
	State.s.flags[enemy.stable_id] = true
	State.gain_xp(int(enemy.data.xp)*(2 if enemy.elite else 1))
	State.s.crowns += 8 if not enemy.elite else 30
	State.add_item("ore")
	if enemy.stable_id == "sentinel": State.add_item("key"); message("Crypt Sigil recovered. The eastern gate will open.")
	if enemy.stable_id == "boss":
		State.add_item("bellblade")
		State.s.memory["village_bell"] = true
		State.s.hp = State.stat("hp")
		save(0)
		menu("The Bellkeeper Falls","The last toll dissolves into dust. Beyond the arena, the Veil Shrine opens.\nThe villagers will remember what you have done.")
		button("Take the Bellkeeper Blade",close_menu)
	State.reconcile_quests()
	sound("loot")
func attack(origin: Vector2, direction: Vector2, magic: bool):
	sound("swing")
	var weapon: Dictionary = State.items[State.s.equipment.weapon]
	if magic or weapon.kind in ["staff","bow"]:
		fire(origin+direction*22,direction,State.stat("attack")+(State.s.attributes.Intelligence*3 + (8 if "Ember" in State.s.skills else 0) if magic else 0),false,"")
		return
	for enemy in enemies.get_children():
		var delta: Vector2 = enemy.position-origin
		if delta.length() <= weapon.reach and delta.normalized().dot(direction) > .3:
			var amount := State.stat("attack")
			if randf() < .08+State.s.attributes.Dexterity*.015: amount *= 1.7
			var ray := PhysicsRayQueryParameters2D.create(origin,enemy.position,4)
			if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
			enemy.hurt(amount,direction)
			sound("hit")
func fire(origin: Vector2, direction: Vector2, damage: float, hostile: bool, effect: String):
	var p = Projectile.new(); p.position = origin; p.direction = direction; p.damage = damage; p.hostile = hostile; p.effect = "Hex" if not hostile and "Hex" in State.s.skills else effect; p.game = self; shots.add_child(p)
func interact(object: Dictionary):
	if object.kind in ["chest","herb"] and State.s.flags.get(object.id,false): return
	match object.kind:
		"sign": menu("Weathered words",object.text); button("Close",close_menu)
		"npc": talk(object.id)
		"checkpoint":
			State.s.checkpoint = {"map":State.s.map,"position":[player.position.x,player.position.y]}
			State.s.hp = State.stat("hp"); State.s.mana = State.stat("mana"); player.statuses.clear(); save(0); message("Checkpoint attuned. Health restored; autosave written.")
		"door":
			if object.id == "crypt" and State.s.map == "forest" and State.s.inventory.get("key",0) == 0: message("The crypt requires the forest sentinel’s sigil."); return
			if object.id == "shrine" and not State.s.flags.get("boss",false): message("The Bellkeeper seals this passage."); return
			var order := ["village","forest","crypt","shrine"]
			load_map(object.id,Vector2(100,480) if order.find(object.id)>order.find(State.s.map) else Vector2(1280,480))
		"chest":
			var id := "charm" if object.id == "forest_charm" else "potion"
			if State.add_item(id):
				State.s.flags[object.id] = true; State.s.crowns += 25; State.add_item("ore",2); message("Found "+State.items[id].name+", iron and 25 Crowns."); sound("loot"); world.queue_redraw()
		"herb":
			if State.add_item("herb"): State.s.flags[object.id] = true; world.queue_redraw(); message("Weeping Herb gathered.")
		"shrine":
			State.s.flags["ending"] = true; State.accept("bell"); State.reconcile_quests(); save(0)
			menu("CHAPTER I — THE VEIL REMEMBERS","Within the crystal is your own face.\nYou were the keeper who rang the first bell.\n\nVesper’s voice follows you: ‘A curse can be inherited. A choice cannot.’\n\nThe roads beyond Hollowmere await another chapter.")
			button("Remain in Hollowmere",close_menu)
func save(slot: int):
	State.s.position = [player.position.x,player.position.y]
	message("Saved slot %d"%slot if State.save_game(slot) else "Save failed — check disk permissions")
func death():
	menu("The Veil Takes You","Your checkpoint remembers. Your discoveries remain, but you lose ten Crowns.")
	mode = "death"
	button("Awaken at checkpoint",func():
		State.s.crowns = maxi(0,State.s.crowns-10); State.s.hp = State.stat("hp"); player.statuses.clear()
		var p: Array = State.s.checkpoint.position
		load_map(State.s.checkpoint.map,Vector2(p[0],p[1])); close_menu())
func message(text: String): toast.text = text; toast_time = 9
func sound(id: String):
	if AudioServer.get_driver_name() == "Dummy": return
	var voice := AudioStreamPlayer.new(); add_child(voice)
	voice.stream = load("res://assets/"+id+".wav")
	voice.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.sfx))
	voice.finished.connect(voice.queue_free)
	voice.play()
func menu(heading: String, text: String = "", size: Vector2 = Vector2(650,410), scrolling: bool = true):
	mode = "menu"; player.locked = true; enemies.process_mode = Node.PROCESS_MODE_DISABLED; shots.process_mode = Node.PROCESS_MODE_DISABLED
	rows = ui.open(heading,size,scrolling); panel = ui.panel
	if text != "": label(text)
func label(text: String, size: int = 14) -> Label: return ui.text(rows,text,size)
func button(text: String, callback: Callable, enabled: bool = true) -> Button:
	return ui.button(rows,text,func(): sound("menu"); callback.call(),enabled)
func close_menu():
	pause_guard = Input.is_action_pressed("pause")
	ui.close(); service_npc = ""; active_npc = ""
	mode = "play"; player.locked = false; enemies.process_mode = Node.PROCESS_MODE_INHERIT; shots.process_mode = Node.PROCESS_MODE_INHERIT
func title():
	service_npc = ""
	menu("ASHEN VEIL","A bell has fallen silent. A wanderer wakes without a name.",Vector2(440,385))
	mode = "title"
	button("New Adventure",func(): State.reset(); load_map("village",Vector2(480,480)); close_menu(); message("Find Ilya in the square. Controls are in the pause menu."))
	for i in range(4):
		var slot := i
		button("Continue "+("Autosave" if i == 0 else "Slot %d"%i),func():
			if State.load_game(slot): load_map(State.s.map,Vector2(State.s.position[0],State.s.position[1])); close_menu()
			else: message("No valid save in this slot."))
	button("Settings",settings); button("Exit",shutdown)
func pause_menu():
	service_npc = ""
	menu("Rest in the Ashes","",Vector2(440,380))
	button("Resume",close_menu)
	for i in range(1,4):
		var slot := i; button("Save Slot %d"%i,func(): save(slot))
	button("Controls & Help",help_menu); button("Settings",settings)
	button("Save and Return to Title",func(): save(0); title())
func help_menu():
	menu("Controls & Help","WASD / left stick — move\nLeft mouse / X — attack\nRight mouse / left shoulder — block\nSpace / A — dodge\nShift — sprint\nE / Y — interact\nQ / right shoulder — healing draught\nF — ember\nI — inventory · J — journal · C — character\nEsc / Start — pause or go back\n\nMenus: arrows or D-pad to select, Enter / A to confirm.\nBlue crystals heal and autosave. Speak to Ilya in the square to begin. Look for orange enemy warnings; dodge clear, then strike during recovery.")
	button("Back",pause_menu)
func two_columns(left_width: float = 225) -> Array:
	var columns := HBoxContainer.new(); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; rows.add_child(columns)
	var left_scroll := ScrollContainer.new(); left_scroll.custom_minimum_size.x = left_width; left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(left_scroll)
	var left := VBoxContainer.new(); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; left_scroll.add_child(left)
	var right_scroll := ScrollContainer.new(); right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; columns.add_child(right_scroll)
	var right := VBoxContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right_scroll.add_child(right)
	return [left,right]
func inventory(selected: String = ""):
	menu("Satchel & Equipment","%d / 24 item kinds · %d Crowns"%[State.s.inventory.size(),State.s.crowns],Vector2(700,425),false)
	var columns := two_columns(); var left: VBoxContainer = columns[0]; var right: VBoxContainer = columns[1]
	var chosen := selected if State.s.inventory.has(selected) else (str(State.s.inventory.keys()[0]) if not State.s.inventory.is_empty() else "")
	for id in State.s.inventory:
		ui.button(left,("◆ " if id == chosen else "")+State.items[id].name+" ×%d"%State.s.inventory[id],func(): inventory(id))
	if chosen != "":
		var item: Dictionary = State.items[chosen]
		ui.item_title(right,chosen); ui.text(right,item.rarity+" · "+(item.slot if item.slot != "" else "material / consumable"),12)
		ui.text(right,item.description)
		var current: String = State.s.equipment.get(item.slot,"")
		var comparison := ""
		for stat in ["attack","defense"]:
			var change: int = int(item.get(stat,0))-int(State.items[current].get(stat,0) if current != "" else 0)
			comparison += "%s %d  (%+d vs equipped)\n"%[stat.capitalize(),item.get(stat,0),change]
		ui.text(right,comparison)
		if item.slot != "": ui.button(right,"Equipped" if chosen == current else "Equip",func(): State.equip(chosen); inventory(chosen),chosen != current)
		elif item.get("effect","") != "": ui.button(right,"Use",func(): State.use(chosen); inventory(chosen))
		if item.price > 0: ui.button(right,"Sell one · %d Crowns"%maxi(1,int(item.price/2)),func(): State.sell(chosen); inventory(chosen),chosen not in State.s.equipment.values())
		ui.text(right,"Equipped",15)
		for slot in ["weapon","head","chest","gloves","boots","accessory"]: ui.text(right,slot.capitalize()+": "+State.items[State.s.equipment[slot]].name if State.s.equipment.has(slot) else slot.capitalize()+": —",12)
	button("Back to conversation" if service_npc != "" else "Close",return_to_npc if service_npc != "" else close_menu)
func journal(selected: String = ""):
	menu("The Wanderer's Journal","",Vector2(730,425),false)
	var columns := two_columns(235); var left: VBoxContainer = columns[0]; var right: VBoxContainer = columns[1]
	selected_quest = selected if State.s.quests.has(selected) else (str(State.s.quests.keys()[0]) if not State.s.quests.is_empty() else "")
	for status in ["active","complete"]:
		ui.text(left,status.capitalize(),14)
		for id in State.s.quests:
			if State.s.quests[id] == status: ui.button(left,("◆ " if id == selected_quest else "")+State.quest_defs[id].name,func(): journal(id))
	if selected_quest != "":
		var quest: Dictionary = State.quest_defs[selected_quest]
		ui.text(right,quest.name,18); ui.text(right,State.s.quests[selected_quest].to_upper(),12); ui.text(right,quest.text)
		ui.text(right,"Objectives",15); ui.text(right,State.quest_progress(selected_quest)); ui.text(right,"Reward",15)
		ui.text(right,"%d Crowns · 60 XP"%quest.reward)
	else: ui.text(right,"Speak with Captain Ilya in the square. Your accepted quests will appear here.")
	button("Close",close_menu)
func character():
	menu("Character & Paths","Level %d · XP %d/%d · Points %d\nAttack %d · Defense %d · Speed %d"%[State.s.level,State.s.xp,State.s.level*45,State.s.points,State.stat("attack"),State.stat("defense"),State.stat("speed")])
	for id in State.s.attributes: button("%s %d · spend one point"%[id,State.s.attributes[id]],func(): State.spend_attribute(id); character(),State.s.points>0)
	for entry in [["Warrior","Cleave","+5 melee damage"],["Warrior","Bulwark","+20 health"],["Rogue","Fleet","+20 speed"],["Rogue","Shadow","Longer dodge immunity"],["Occultist","Ember","+8 magic damage"],["Occultist","Hex","Projectile stun"]]:
		var id: String = entry[1]
		button("%s · %s · %s%s"%[entry[0],id,entry[2]," [Learned]" if id in State.s.skills else " (2 points)"],func(): State.unlock(id); character(),id not in State.s.skills and State.s.points>=2)
	button("Close",close_menu)
func settings():
	var from_title := mode == "title"
	menu("Settings","This chapter runs entirely offline.",Vector2(450,350))
	for id in ["master","music","sfx","ambient"]:
		label(id.capitalize()); var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = .05; slider.value = State.s.settings[id]; rows.add_child(slider)
		slider.value_changed.connect(func(value): State.s.settings[id] = value)
	button("Back",title if from_title else pause_menu)
func talk(id: String, node: String = "root", response: String = ""):
	active_npc = id; dialogue_node = node; service_npc = ""; State.reconcile_quests()
	var data: Dictionary = dialogue.node_for(id,node)
	menu(State.npcs[id].name+" · "+State.npcs[id].role.capitalize(),"",Vector2(640,355),false); mode = "dialogue"
	var conversation := HBoxContainer.new(); rows.add_child(conversation)
	var portrait := TextureRect.new(); portrait.texture = load("res://assets/portraits/"+id+".png") if ResourceLoader.exists("res://assets/portraits/"+id+".png") else load("res://assets/npc.png")
	portrait.custom_minimum_size = Vector2(90,100); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; conversation.add_child(portrait)
	dialogue_text = ui.text(conversation,response if response != "" else data.text)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; rows.add_child(scroll)
	var choices := VBoxContainer.new(); choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(choices)
	for choice in data.choices:
		ui.button(choices,choice.text,func(): select_dialogue(choice))
	if node != "root": ui.button(choices,"Goodbye.",close_menu)
	State.s.memory[id+"_spoken"] = true
func select_dialogue(choice: Dictionary):
	var npc := active_npc
	var action: Dictionary = choice.get("action",{})
	if action.is_empty(): talk(npc,choice.next); return
	if action.kind in ["accept","turn_in"]:
		talk(npc,choice.next,dialogue.execute(npc,action)); return
	var services := {"mara":["shop","sell"],"brann":["upgrade"],"sister":["heal"],"nell":["rest"]}
	if action.kind != "goodbye" and action.kind not in services.get(npc,[]): return
	service_npc = npc
	match action.kind:
		"goodbye": close_menu()
		"shop": shop()
		"sell": inventory()
		"upgrade": upgrade_menu()
		"heal": heal_menu()
		"rest": rest_menu()
func return_to_npc():
	var npc := service_npc
	if npc != "": talk(npc)
	else: close_menu()
func upgrade_menu():
	var level: int = State.s.upgrades.get(State.s.equipment.weapon,0)
	menu("Brann's Forge",State.items[State.s.equipment.weapon].name+" · Upgrade +%d\nNext improvement: +4 attack\nCost: %d Crowns and %d Grave Iron"%[level,25*(level+1),level+1],Vector2(480,280))
	button("Improve weapon",func(): message("Weapon improved." if State.upgrade() else "Insufficient Crowns or iron."); upgrade_menu(),level<5 and State.s.crowns>=25*(level+1) and State.s.inventory.get("ore",0)>=level+1)
	button("Back to Brann",return_to_npc)
func heal_menu():
	menu("Elowen's Care","Restore health and cleanse ailments · 8 Crowns",Vector2(450,240))
	button("Accept healing",func(): heal_at_npc(); return_to_npc(),State.s.crowns>=8); button("Back",return_to_npc)
func heal_at_npc():
	if State.s.crowns < 8: message("Healing costs 8 Crowns."); return
	State.s.crowns -= 8; State.s.hp = State.stat("hp"); player.statuses.clear(); message("Wounds healed. −8 Crowns.")
func rest_menu():
	menu("The Last Hearth","Rest, recover and save · 5 Crowns",Vector2(450,240))
	button("Take a room",func(): rest_at_npc(); return_to_npc(),State.s.crowns>=5); button("Back",return_to_npc)
func rest_at_npc():
	if State.s.crowns < 5: message("A room costs 5 Crowns."); return
	State.s.crowns -= 5; State.s.hp = State.stat("hp"); player.statuses.clear(); save(0)
func shop(selected: String = "potion"):
	menu("Mara's Wares","%d Crowns"%State.s.crowns,Vector2(690,420),false)
	var columns := two_columns(); var left: VBoxContainer = columns[0]; var right: VBoxContainer = columns[1]
	for id in ["potion","ether","tonic","antidote","dagger","axe","staff","bow","hood","mail","gloves","boots","charm","crown"]:
		ui.button(left,("◆ " if selected == id else "")+State.items[id].name,func(): shop(id))
	var item: Dictionary = State.items[selected]
	ui.item_title(right,selected); ui.text(right,item.description); ui.text(right,"Price: %d Crowns\nAttack %d · Defense %d"%[item.price,item.get("attack",0),item.get("defense",0)])
	ui.button(right,"Purchase...",func(): confirm_purchase(selected),State.s.crowns>=item.price)
	button("Back to Mara",return_to_npc)
func confirm_purchase(id: String):
	if not State.items.has(id) or State.items[id].price<=0: return
	menu("Confirm Purchase",State.items[id].name+" · %d Crowns"%State.items[id].price,Vector2(420,230))
	button("Buy",func(): message("Purchased." if State.buy(id) else "Insufficient Crowns or full satchel."); shop(id),State.s.crowns>=State.items[id].price)
	button("Cancel",func(): shop(id))
func _exit_tree():
	if ambience: ambience.stop(); ambience.stream = null
	if audio: audio.stop(); audio.stream = null
	if music: music.stop(); music.stream = null
func shutdown():
	music.stop(); ambience.stop(); audio.stop()
	await get_tree().process_frame; await get_tree().process_frame; get_tree().quit()
