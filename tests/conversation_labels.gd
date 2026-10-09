extends Node
const Dialogue = preload("res://scripts/dialogue.gd")
const Typography = preload("res://scripts/typography.gd")
var passed := 0
var failed := 0
func check(ok: bool, title: String):
	if ok: passed += 1; print("PASS CONTEXT ",title)
	else: failed += 1; push_error("FAIL CONTEXT "+title)
func option(d, next: String) -> Dictionary:
	for c in d.node_for(d.context.npc,d.context.node).choices:
		if c.next == next: return c
	return {}
func settle():
	await get_tree().process_frame; await get_tree().process_frame; await get_tree().process_frame
func _ready():
	get_tree().create_timer(30).timeout.connect(func(): push_error("Context test timeout"); get_tree().quit(2))
	State.reset()
	var d := Dialogue.new(); add_child(d)
	for npc in State.npcs:
		d.begin(npc)
		check(d.context.npc == npc and d.context.history.is_empty(),npc+" starts with clean context")
		check(option(d,"king").is_empty(),npc+" king question locked before mention")
		d.enter("identity"); d.enter("past")
		check(d.context.previous == "identity" and d.context.topic == "history",npc+" keeps prior branch and topic")
		check(not option(d,"king").is_empty(),npc+" history unlocks relevant king follow-up")
		var king: Dictionary = option(d,"king"); d.record_question(king.id)
		d.enter(king.next)
		check(d.context.node == "king" and d.context.questions.has(king.id),npc+" records exact selected question")
		d.back()
		check(d.context.node == "past",npc+" Back returns to the actual previous topic")
		check(d.knowledge(npc).get("learned_"+npc+"_history",false),npc+" background knowledge is persistent")
		d.end(); check(d.context.is_empty(),npc+" Goodbye clears temporary context")
		d.begin(npc); check(not option(d,"king").is_empty(),npc+" learned follow-ups remain on reopen")
		check(not d.enter("missing_node") and d.node_for(npc,"missing_node").is_empty(),npc+" missing target never becomes greeting")
		check(d.choice("other_npc:0").is_empty(),npc+" foreign or stale choices rejected")
		# Exercise every explicit node and visible choice in the runtime resolver.
		var routes_ok := true
		State.s.flags.boss = true; State.s.flags.sentinel = true
		for node in d.trees[npc].nodes:
			d.enter(node,false)
			for choice in d.node_for(npc,node).choices:
				if d.choice(choice.id) != choice: routes_ok = false
				if choice.next in d.trees[npc].nodes and d.node_for(npc,choice.next).text == "": routes_ok = false
		check(routes_ok,npc+" runtime choice IDs resolve only to authored local nodes")
	check(State.save_game(2),"dialogue discoveries save using existing schema")
	var discoveries: Dictionary = State.s.memory.dialogue_knowledge.duplicate(true)
	State.reset(); check(State.load_game(2) and State.s.memory.dialogue_knowledge == discoveries,"all NPC discoveries survive save/load")
	State.reset(); d.begin("brann"); d.enter("past")
	check(d.knowledge("mara").is_empty(),"NPC knowledge never leaks to another villager")
	for i in range(60): d.enter("king"); d.enter("stay"); d.enter("past")
	check(d.context.history.size()<=24,"cyclic topic revisits keep navigation history bounded")
	var game = load("res://scenes/main.tscn").instantiate(); add_child(game); game.close_menu()
	game.load_map("village",Vector2(235,740)); await settle()
	check(game.world.labels.entries.size() == 13,"four real buildings, market and eight NPC labels")
	for resolution in [Vector2i(800,450),Vector2i(1152,648),Vector2i(1600,900)]:
		get_window().size = resolution
		for zoom in [.9,1.2,1.5]:
			get_viewport().get_camera_2d().zoom = Vector2(zoom,zoom)
			await settle()
			game.world.labels.update_labels(game.player.position,true,game.ui.hud.get_global_rect(),game.ui.prompt.get_global_rect(),1)
			var occupied: Array[Rect2] = []; var valid := true; var shown := false
			for label in game.world.labels.entries:
				if label.target_visible:
					shown = true
					var rect: Rect2 = label.screen_rect()
					if rect.intersects(game.ui.hud.get_global_rect()) or not Rect2(Vector2.ZERO,game.ui.root.size).encloses(rect): valid = false
					for prior in occupied:
						if rect.intersects(prior): valid = false
					occupied.append(rect)
			check(valid and shown,"world labels avoid HUD, viewport and each other %s zoom %.1f"%[resolution,zoom])
	get_viewport().get_camera_2d().zoom = Vector2(1.2,1.2)
	game.talk("brann"); await settle()
	check(not game.world.labels.entries.any(func(l): return l.visible),"menus suppress world labels immediately")
	game.close_menu(); game.load_map("village",Vector2(700,400)); await settle()
	var forge
	for label in game.world.labels.entries:
		if label.identity == "Brann's Forge": forge = label
	check(not forge.target_visible,"distant building labels are hidden")
	var position_before: Vector2 = forge.global_position
	game.player.position += Vector2(80,30); await settle()
	check(forge.global_position == position_before,"camera movement does not detach world labels from buildings")
	check(Typography.FONT.antialiasing == TextServer.FONT_ANTIALIASING_NONE and not Typography.FONT.allow_system_fallback,"pixel font disables smoothing and OS fallback")
	game.inventory(); await settle()
	var consistent := true
	for control in game.ui.root.find_children("*","Control",true,false):
		if control is Label or control is Button:
			if control.get_theme_font("font") != Typography.FONT: consistent = false
	check(consistent,"all current interface text inherits the bundled pixel font")
	var glyphs := true
	for code in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 >+−×•·—‘’'":
		if not Typography.FONT.has_char(code.unicode_at(0)): glyphs = false
	check(glyphs,"pixel font supplies game punctuation and UI symbols")
	game.queue_free(); d.queue_free(); await settle()
	print("CONTEXT RESULT: %d passed, %d failed"%[passed,failed]); get_tree().quit(1 if failed else 0)
