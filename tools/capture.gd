extends Node
func _ready():
	var game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(.4).timeout
	game.close_menu()
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/hollowmere.png")
	game.load_map("crypt",Vector2(1130,480))
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/bellkeeper.png")
	game.shutdown()
