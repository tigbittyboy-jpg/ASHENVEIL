extends Node
var g
var boss
var elapsed := 0.0
var swings := 0
var potion_time := 0.0
var finished := false
func _ready():
	seed(122)
	State.reset()
	for i in range(6): State.s.flags["crypt%d"%i] = true
	State.s.flags.crypt_knight = true
	g = load("res://scenes/main.tscn").instantiate(); add_child(g)
	g.close_menu(); g.load_map("crypt",Vector2(1100,480))
	for e in g.enemies.get_children():
		if e.kind == "boss": boss = e
	process_physics_priority = -10
	Engine.time_scale = 4
func release_controls():
	for action in ["left","right","up","down","dodge"]: Input.action_release(action)
func _physics_process(dt):
	if finished: return
	elapsed += dt; potion_time -= dt
	release_controls()
	if State.s.flags.get("boss",false): complete(true); return
	if g.mode == "death" or elapsed > 110: complete(false); return
	var hero = g.player
	var delta: Vector2 = boss.position-hero.position
	var distance := delta.length()
	var move := Vector2.ZERO
	if boss.state == "Attack":
		if distance < boss.attack_radius+32:
			move = -delta.normalized()
			if boss.timer < .45 and hero.dodge_time <= 0 and State.s.stamina >= 18: Input.action_press("dodge")
	else:
		if distance > 62: move = delta.normalized()
	# Preserve real movement/collision. If a retreat would hit a wall, sidestep.
	if not g.world.walkable(hero.position+move*40): move = Vector2(-move.y,move.x)
	if move.x < -.1: Input.action_press("left",absf(move.x))
	if move.x > .1: Input.action_press("right",absf(move.x))
	if move.y < -.1: Input.action_press("up",absf(move.y))
	if move.y > .1: Input.action_press("down",absf(move.y))
	var target = boss
	for enemy in g.enemies.get_children():
		if enemy.kind != "boss" and hero.position.distance_to(enemy.position) < 75: target = enemy; break
	if hero.cooldown <= 0 and State.s.stamina >= 9 and hero.position.distance_to(target.position) <= 82:
		hero.cooldown = State.items.rust_sword.speed
		State.s.stamina -= State.items.rust_sword.cost
		g.attack(hero.position,(target.position-hero.position).normalized(),false)
		swings += 1
	if State.s.hp < 45 and potion_time <= 0 and State.s.inventory.get("potion",0)>0:
		State.use("potion"); potion_time = 2
func complete(success: bool):
	finished = true; release_controls(); Engine.time_scale = 1
	print("BOSS PLAYTEST: %s · %.1f simulated seconds · %d sword attacks · %.0f HP · %d potions remaining"%["PASS" if success else "FAIL",elapsed,swings,State.s.hp,State.s.inventory.get("potion",0)])
	if success:
		g.close_menu()
		g.interact({"kind":"door","id":"shrine"})
		g.interact({"kind":"shrine","id":"ending"})
		if not State.s.flags.get("ending",false): success = false
	g.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if success else 1)
