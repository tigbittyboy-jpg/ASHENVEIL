extends Node2D
var direction := Vector2.RIGHT
var speed := 240.0
var damage := 10.0
var hostile := false
var effect := ""
var life := 2.0
var game
func _process(dt):
	var old := global_position
	global_position += direction*speed*dt
	life -= dt
	var query := PhysicsRayQueryParameters2D.create(old,global_position,4)
	if life <= 0 or not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): queue_free(); return
	if hostile:
		if game.player.global_position.distance_to(global_position) < 18:
			game.player.hurt(damage,direction,effect)
			queue_free()
	else:
		for enemy in game.enemies.get_children():
			if enemy.global_position.distance_to(global_position) < 24:
				enemy.hurt(damage,direction,true)
				if effect == "Hex": enemy.state = "Stunned"; enemy.timer = .6
				queue_free()
				break
func _draw():
	draw_circle(Vector2.ZERO,5,Color("b877c0") if hostile else Color("ebbb79"))
	draw_line(-direction*12,Vector2.ZERO,Color("e1d0a9"),2)
