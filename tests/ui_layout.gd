extends Node
var passed := 0
var failed := 0
var game
func check(condition: bool, title: String):
	if condition: passed += 1; print("PASS UI ",title)
	else: failed += 1; push_error("FAIL UI "+title)
func settle():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
func key(code: int):
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventKey.new(); event.keycode = code; event.physical_keycode = code
	Input.parse_input_event(event)
	await settle()
func _ready():
	get_tree().create_timer(40).timeout.connect(func(): push_error("UI test timeout"); get_tree().quit(2))
	State.reset(); game = load("res://scenes/main.tscn").instantiate(); add_child(game)
	for id in State.quest_defs: State.accept(id)
	for id in State.items: State.add_item(id)
	for resolution in [Vector2i(800,450),Vector2i(1152,648),Vector2i(1600,900),Vector2i(1024,768)]:
		get_window().size = resolution
		for entry in [["title",game.title],["pause",game.pause_menu],["help",game.help_menu],["settings",game.settings],["inventory",game.inventory],["journal",game.journal],["character",game.character],["dialogue",func(): game.talk("mara")],["shop",game.shop],["forge",game.upgrade_menu],["healing",game.heal_menu],["inn",game.rest_menu],["purchase",func(): game.confirm_purchase("potion")]]:
			entry[1].call(); await settle()
			var panel: Rect2 = game.ui.panel.get_global_rect()
			var screen := Rect2(Vector2.ZERO,game.ui.root.size)
			check(screen.encloses(panel),"%s panel fits %s"%[entry[0],resolution])
			check(panel.encloses(game.ui.header.get_global_rect()),"%s heading remains inside panel %s"%[entry[0],resolution])
			var bounded := true
			for button in game.ui.panel.find_children("*","Button",true,false):
				var rect: Rect2 = button.get_global_rect()
				if rect.position.x < panel.position.x or rect.end.x > panel.end.x+1: bounded = false
			check(bounded,"%s buttons fit panel width %s"%[entry[0],resolution])
	game.close_menu(); await settle()
	check(game.ui.hud.visible and game.ui.hud.size.y < 125,"compact HUD returns during gameplay")
	var bars: Array = game.ui.bar_entries
	check(bars[0][1].get_global_rect().end.y <= bars[1][1].get_global_rect().position.y and bars[1][1].get_global_rect().end.y <= bars[2][1].get_global_rect().position.y,"HUD resource bars never overlap")
	game.talk("mara"); await settle()
	check(not game.ui.hud.visible,"menu hides HUD instead of overlapping it")
	var first = get_viewport().gui_get_focus_owner()
	check(first is Button and first.text == "Who are you?","opening dialogue selects first response")
	await key(KEY_DOWN)
	var next = get_viewport().gui_get_focus_owner()
	check(next is Button and next != first,"arrow key navigates dialogue responses")
	await key(KEY_ENTER)
	check(game.dialogue_node == "past","Enter selects a nested authored branch")
	await key(KEY_ESCAPE)
	check(game.mode == "dialogue" and game.dialogue_node == "root","Escape returns from branch to greeting")
	await key(KEY_ESCAPE)
	check(game.mode == "play" and not game.player.locked,"Escape closes dialogue without reopening pause")
	game.talk("mara"); await settle()
	var scroll: ScrollContainer = game.rows.get_child(1)
	check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page,"long choice lists scroll")
	var target = get_viewport().gui_get_focus_owner()
	# OS input positions are physical pixels; controls use the logical canvas.
	var point: Vector2 = get_viewport().get_final_transform()*target.get_global_rect().get_center()
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.position = point; click.global_position = point; click.pressed = true
	Input.parse_input_event(click); await get_tree().process_frame
	click = InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.position = point; click.global_position = point
	Input.parse_input_event(click); await settle()
	check(game.dialogue_node == "identity","mouse click selects authored response")
	game.close_menu(); game.queue_free(); await settle()
	print("UI RESULT: %d passed, %d failed"%[passed,failed]); get_tree().quit(1 if failed else 0)
