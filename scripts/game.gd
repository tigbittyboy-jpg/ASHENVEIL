extends Node2D
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const World = preload("res://scripts/world.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Dialogue = preload("res://scripts/dialogue.gd")
var player
var world
var enemies: Node2D
var shots: Node2D
var ui: CanvasLayer
var hud: Label
var toast: Label
var panel: PanelContainer
var rows: VBoxContainer
var dialogue
var dialogue_text: Label
var active_npc := ""
var mode := "title"
var audio: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var bars: Array = []
var toast_time := 0.0
var boss_label: Label
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
	dialogue.reply.connect(func(text):
		if is_instance_valid(dialogue_text): dialogue_text.text = text)
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
	ui = CanvasLayer.new(); add_child(ui)
	hud = Label.new(); hud.position = Vector2(18,12); hud.add_theme_font_size_override("font_size",18); ui.add_child(hud)
	boss_label = Label.new(); boss_label.position = Vector2(330,485); ui.add_child(boss_label)
	toast = Label.new(); toast.position = Vector2(18,510); toast.add_theme_color_override("font_color",Color("e9c58c")); ui.add_child(toast)
	for entry in [["hp",Color("b65a68")],["stamina",Color("8fab81")],["mana",Color("739bbd")]]:
		var bar := ProgressBar.new(); bar.position = Vector2(18+bars.size()*155,108); bar.size = Vector2(145,8); bar.show_percentage = false
		var fill := StyleBoxFlat.new(); fill.bg_color = entry[1]; bar.add_theme_stylebox_override("fill",fill); ui.add_child(bar); bars.append([entry[0],bar])
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
	for entry in bars: entry[1].max_value = State.stat(entry[0]); entry[1].value = State.s[entry[0]]
	if toast_time <= 0: toast.text = ""
	music.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.music))
	ambience.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.ambient))
	audio.volume_db = linear_to_db(maxf(.001,State.s.settings.master*State.s.settings.sfx))
	hud.text = "%s   |   Level %d   Crowns %d\nHP %d/%d   Stamina %d   Mana %d   |   %s\nE Interact · Q Draught · F Ember · I Inventory · J Journal · C Character · Esc Menu" % [World.MAP_NAMES[State.s.map],State.s.level,State.s.crowns,State.s.hp,State.stat("hp"),State.s.stamina,State.s.mana,State.items[State.s.equipment.weapon].name]
	boss_label.text = ""
	for enemy in enemies.get_children():
		if enemy.kind == "boss": boss_label.text = "THE BELLKEEPER   %d / %d   PHASE %d" % [enemy.hp,enemy.max_hp,enemy.phase]
	if mode != "play": return
	var nearby: Dictionary = world.nearest(player.position)
	if not nearby.is_empty(): hud.text += "\n[E] " + str(nearby.get("label",State.npcs[nearby.id].name if nearby.kind == "npc" else nearby.kind.capitalize()))
	if Input.is_action_just_pressed("interact") and not nearby.is_empty(): interact(nearby)
	if Input.is_action_just_pressed("inventory"): inventory()
	if Input.is_action_just_pressed("journal"): journal()
	if Input.is_action_just_pressed("stats"): character()
	if Input.is_action_just_pressed("pause"): pause_menu()
	for object in world.objects:
		if object.kind == "trap" and player.position.distance_to(object.pos) < 22: player.hurt(12,Vector2.ZERO,"Bleeding")
func _unhandled_input(event):
	if event.is_action_pressed("pause") and mode not in ["play","title","death"]: close_menu(); get_viewport().set_input_as_handled()
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
func menu(heading: String, text: String = ""):
	if is_instance_valid(panel):
		panel.hide()
		panel.queue_free()
	mode = "menu"; player.locked = true; enemies.process_mode = Node.PROCESS_MODE_DISABLED; shots.process_mode = Node.PROCESS_MODE_DISABLED
	panel = PanelContainer.new(); panel.position = Vector2(210,78); panel.size = Vector2(570,425); ui.add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color("171d2a"); style.border_color = Color("a48c69"); style.set_border_width_all(2); style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 12; style.content_margin_bottom = 12; panel.add_theme_stylebox_override("panel",style)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(530,390); panel.add_child(scroll)
	rows = VBoxContainer.new(); rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(rows)
	label(heading,25)
	if text != "": label(text,16)
func label(text: String, size: int = 16) -> Label:
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size.x = 505; l.add_theme_font_size_override("font_size",size); rows.add_child(l); return l
func button(text: String, callback: Callable):
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 30; rows.add_child(b)
	b.pressed.connect(func(): sound("menu"); callback.call())
	if rows.get_child_count() <= 3: b.grab_focus()
func close_menu():
	dialogue.cancel()
	if is_instance_valid(panel): panel.queue_free()
	mode = "play"; player.locked = false; enemies.process_mode = Node.PROCESS_MODE_INHERIT; shots.process_mode = Node.PROCESS_MODE_INHERIT
func title():
	menu("ASHEN VEIL","A bell has fallen silent. A wanderer wakes without a name.\nAn original dark fantasy action RPG — Chapter I")
	mode = "title"
	button("New Adventure",func(): State.reset(); load_map("village",Vector2(480,480)); close_menu(); message("Find Captain Ilya. WASD move, mouse attack, Space dodge, E interact."))
	for i in range(4):
		var slot := i
		button("Continue "+("Autosave" if i == 0 else "Slot %d"%i),func():
			if State.load_game(slot): load_map(State.s.map,Vector2(State.s.position[0],State.s.position[1])); close_menu()
			else: message("No valid save in this slot."))
	button("Settings",settings)
	button("Exit",shutdown)
func pause_menu():
	menu("Rest in the Ashes")
	button("Resume",close_menu)
	for i in range(1,4):
		var slot := i; button("Save Slot %d"%i,func(): save(slot))
	button("Settings",settings)
	button("Save and Return to Title",func(): save(0); title())
func inventory():
	menu("Satchel & Equipment","24 distinct item slots. Click equipment to equip; consumables to use. Right below each item is a sale option.")
	for id in State.s.inventory.keys():
		var item: Dictionary = State.items[id]
		var equipped := " [Equipped]" if id in State.s.equipment.values() else ""
		button("%s ×%d%s · %s · ATK %d DEF %d"%[item.name,State.s.inventory[id],equipped,item.rarity,item.get("attack",0),item.get("defense",0)],func():
			if item.slot != "": State.equip(id)
			else: State.use(id)
			inventory())
		label(item.description,13)
		if item.price > 0: button("Sell one for %d Crowns"%maxi(1,int(item.price/2)),func(): State.sell(id); inventory())
	button("Close",close_menu)
func journal():
	menu("The Wanderer’s Journal")
	for id in State.s.quests:
		label(State.quest_defs[id].name+" — "+State.s.quests[id],19)
		label(State.quest_defs[id].text)
		label("Reward: %d Crowns + 60 XP · "%State.quest_defs[id].reward + State.quest_progress(id),14)
	if State.s.quests.is_empty(): label("Seek Captain Ilya in the village.")
	button("Close",close_menu)
func character():
	menu("Character & Paths","Level %d · XP %d/%d · Points %d\nAttack %d · Defense %d · Speed %d"%[State.s.level,State.s.xp,State.s.level*45,State.s.points,State.stat("attack"),State.stat("defense"),State.stat("speed")])
	for id in State.s.attributes:
		button("%s %d — spend one point"%[id,State.s.attributes[id]],func(): State.spend_attribute(id); character())
	for entry in [["Warrior","Cleave","+5 melee damage"],["Warrior","Bulwark","+20 health"],["Rogue","Fleet","+20 movement speed"],["Rogue","Shadow","Longer dodge immunity"],["Occultist","Ember","+8 Ember damage"],["Occultist","Hex","Projectiles weaken enemies"]]:
		var id: String = entry[1]
		button("%s: %s — %s %s"%[entry[0],id,entry[2],"[Learned]" if id in State.s.skills else "(2 points)"],func(): State.unlock(id); character())
	button("Close",close_menu)
func settings():
	menu("Settings","Optional Ollama uses llama3.2 at localhost:11434. Failure falls back to authored dialogue.")
	for id in ["master","music","sfx","ambient"]:
		label(id.capitalize())
		var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = .05; slider.value = State.s.settings[id]; rows.add_child(slider)
		slider.value_changed.connect(func(value): State.s.settings[id] = value)
	button("Ollama: "+str(State.s.settings.ollama),func(): State.s.settings.ollama = not State.s.settings.ollama; settings())
	button("Back",pause_menu)
func talk(id: String):
	active_npc = id
	State.reconcile_quests()
	menu(State.npcs[id].name)
	dialogue_text = label(dialogue.fallback(id,""))
	var line := LineEdit.new()
	line.placeholder_text = "Type a question, then Enter or Send..."
	line.max_length = 300
	rows.add_child(line)
	var submit := func():
		var question := line.text.strip_edges()
		if question == "": return
		var intent: Dictionary = dialogue.intent_for(id,question)
		if not intent.is_empty(): confirm_intent(intent,id); return
		dialogue_text.text = "Listening..."
		dialogue.ask(id,question)
		line.clear()
		line.grab_focus()
	line.text_submitted.connect(func(_question): submit.call())
	button("Send question",submit)
	label("Try: 'who are you', 'forest', 'quest', 'accept quest', 'deliver herbs'.",13)
	match State.npcs[id].role:
		"merchant": button("Browse Wares",shop)
		"smith":
			quest_buttons("iron",id)
			button("Upgrade weapon · %d Crowns + %d iron"%[25*(State.s.upgrades.get(State.s.equipment.weapon,0)+1),State.s.upgrades.get(State.s.equipment.weapon,0)+1],func(): message("Weapon improved." if State.upgrade() else "Need more Crowns or Grave Iron, or maximum upgrade reached."); talk(id))
		"healer":
			quest_buttons("herbs",id)
			button("Healing — 8 Crowns",func(): heal_at_npc(); talk(id))
		"quest": quest_buttons("bell",id); quest_buttons("elites",id)
		"resident": quest_buttons("charm",id)
		"innkeeper": button("Rest — 5 Crowns",func(): rest_at_npc(); talk(id))
	if State.s.memory.get("tovin_helped",false) and id == "tovin": label("You brought him home. I will not forget.")
	if State.s.memory.get("tovin_betrayed",false) and id == "tovin": label("You kept the last piece of him. Leave me alone.")
	button("Leave",close_menu)
	line.grab_focus.call_deferred()
func quest_buttons(quest: String, npc: String):
	var status: String = State.s.quests.get(quest,"not accepted")
	label("%s · %s · Reward %d Crowns + 60 XP"%[State.quest_defs[quest].name,status,State.quest_defs[quest].reward],15)
	if status == "complete": return
	if status == "not accepted": button("Accept: "+State.quest_defs[quest].name,func(): State.accept(quest); talk(npc))
	label(State.quest_progress(quest),14)
	if quest in ["herbs","iron","charm"]:
		button("Return Charm & Claim Reward" if quest == "charm" else "Deliver Items & Claim Reward",func(): State.turn_in(quest); talk(npc))
		if quest == "charm": button("Keep Charm & Claim Reward",func(): State.turn_in(quest,"keep"); talk(npc))
func heal_at_npc():
	if State.s.crowns < 8: message("Healing costs 8 Crowns."); return
	State.s.crowns -= 8; State.s.hp = State.stat("hp"); player.statuses.clear(); message("Wounds healed. −8 Crowns.")
func rest_at_npc():
	if State.s.crowns < 5: message("A room costs 5 Crowns."); return
	State.s.crowns -= 5; State.s.hp = State.stat("hp"); player.statuses.clear(); save(0)
func confirm_intent(intent: Dictionary, npc: String):
	if intent.kind == "purchase": confirm_purchase(intent.item); return
	if intent.kind == "shop": shop(); return
	var heading: String = intent.kind.replace("_"," ").capitalize()
	var details := ""
	if intent.has("quest"):
		details = State.quest_defs[intent.quest].text + "\nReward: %d Crowns + 60 XP"%State.quest_defs[intent.quest].reward
		if intent.kind == "quest_turnin": details += "\n"+State.quest_progress(intent.quest)+"\nChoice: "+intent.choice
	elif intent.kind == "heal": details = "Restore health and cleanse ailments for 8 Crowns."
	elif intent.kind == "rest": details = "Restore health and save for 5 Crowns."
	elif intent.kind == "upgrade": details = "Upgrade the equipped weapon; costs %d Crowns and %d Grave Iron."%[25*(State.s.upgrades.get(State.s.equipment.weapon,0)+1),State.s.upgrades.get(State.s.equipment.weapon,0)+1]
	menu(heading,details)
	button("Confirm",func():
		match intent.kind:
			"quest_accept": State.accept(intent.quest)
			"quest_turnin": State.turn_in(intent.quest,intent.choice)
			"heal": heal_at_npc()
			"rest": rest_at_npc()
			"upgrade": message("Weapon improved." if State.upgrade() else "Insufficient materials or Crowns.")
		talk(npc))
	button("Cancel",func(): talk(npc))
func shop():
	menu("Mara’s Wares","Crowns: %d — Select an item, then confirm the purchase."%State.s.crowns)
	for id in ["potion","ether","tonic","antidote","dagger","axe","staff","bow","hood","mail","gloves","boots","charm","crown"]:
		button("%s — %d Crowns"%[State.items[id].name,State.items[id].price],func():
			menu("Confirm Purchase",State.items[id].name+"\n"+State.items[id].description)
			button("Buy for %d Crowns"%State.items[id].price,func(): message("Purchased." if State.buy(id) else "Insufficient Crowns or full satchel."); shop())
			button("Cancel",shop))
	button("Leave",close_menu)

func _exit_tree():
	if dialogue: dialogue.cancel()
	if ambience: ambience.stop(); ambience.stream = null
	if audio: audio.stop(); audio.stream = null
	if music: music.stop(); music.stream = null

func shutdown():
	music.stop()
	ambience.stop()
	audio.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func confirm_purchase(id: String):
	if not State.items.has(id) or State.items[id].price <= 0: return
	menu("Confirm Purchase",State.items[id].name+"\n"+State.items[id].description)
	button("Buy for %d Crowns"%State.items[id].price,func(): message("Purchased." if State.buy(id) else "Insufficient Crowns or full satchel."); shop())
	button("Cancel",shop)
