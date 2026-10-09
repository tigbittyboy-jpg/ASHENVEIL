extends Node
var game
func capture(file: String):
	await get_tree().create_timer(.4).timeout
	print("CAPTURE ",file," window=",get_window().size," viewport=",get_viewport().get_visible_rect().size)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/"+file+".png")
func _ready():
	State.reset()
	game = load("res://scenes/main.tscn").instantiate(); add_child(game)
	await get_tree().create_timer(.4).timeout
	game.close_menu()
	await capture("hollowmere")
	game.talk("brann","past")
	await capture("dialogue")
	for id in State.quest_defs: State.accept(id)
	game.journal("iron")
	await capture("journal")
	game.inventory()
	await capture("inventory")
	game.close_menu(); game.load_map("forest",Vector2(590,480)); game.player.locked = true; game.enemies.process_mode = Node.PROCESS_MODE_DISABLED
	await capture("forest")
	game.close_menu(); game.load_map("crypt",Vector2(1130,480)); game.player.locked = true
	game.enemies.process_mode = Node.PROCESS_MODE_DISABLED
	await capture("bellkeeper")
	game.close_menu(); game.load_map("shrine",Vector2(880,480)); game.player.locked = true
	await capture("shrine")
	game.close_menu(); game.load_map("village",Vector2(480,480)); game.talk("mara")
	get_window().size = Vector2i(800,450)
	await capture("dialogue-small")
	game.journal("bell")
	await capture("journal-small")
	get_window().size = Vector2i(1600,900)
	game.talk("sister","work")
	await capture("dialogue-large")
	game.shutdown()
