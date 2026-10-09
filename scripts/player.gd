extends CharacterBody2D
signal attacked(origin: Vector2, direction: Vector2, magic: bool)
signal died
signal cleansed
var facing := Vector2.DOWN
var cooldown := 0.0
var immunity := 0.0
var dodge_time := 0.0
var blocking := false
var locked := false
var statuses: Dictionary = {}
var tick := 0.0
var sprite: Sprite2D
var animate_time := 0.0
func _ready():
	collision_layer = 1
	collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11
	shape.shape = circle
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/player.png")
	sprite.scale = Vector2(1.5,1.5)
	add_child(sprite)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1440
	camera.limit_bottom = 960
	add_child(camera)
func _physics_process(dt):
	cooldown = maxf(0,cooldown-dt)
	immunity = maxf(0,immunity-dt)
	dodge_time = maxf(0,dodge_time-dt)
	sprite.modulate = Color(1,1,1,0.5) if immunity > 0 else Color.WHITE
	if locked: velocity = Vector2.ZERO; return
	var move := Input.get_vector("left","right","up","down")
	if move.length() > 0: facing = move.normalized()
	blocking = Input.is_action_pressed("secondary") and State.s.stamina > 1
	var speed := State.stat("speed")
	if Input.is_action_pressed("sprint") and move.length() > 0 and State.s.stamina > 1:
		speed *= 1.5
		State.s.stamina -= dt*20
	if Input.is_action_just_pressed("dodge") and State.s.stamina >= 24 and dodge_time == 0:
		State.s.stamina -= 24
		dodge_time = 0.25
		immunity = 0.32 if "Shadow" not in State.s.skills else 0.5
	if dodge_time > 0: velocity = facing*420
	else: velocity = move*speed*(0.55 if blocking else 1.0)*(0.5 if statuses.has("Slow") else 1.0)
	if statuses.has("Stun"): velocity = Vector2.ZERO
	move_and_slide()
	animate_time += dt
	sprite.position.y = sin(animate_time*16)*2 if velocity.length()>5 else 0
	sprite.flip_h = facing.x < -.1
	position = position.clamp(Vector2(30,30),Vector2(1410,930))
	if Input.is_action_just_pressed("attack") and cooldown <= 0:
		var weapon: Dictionary = State.items[State.s.equipment.weapon]
		if State.s.stamina >= weapon.cost:
			State.s.stamina -= weapon.cost
			cooldown = weapon.speed
			facing = (get_global_mouse_position()-global_position).normalized() if Input.get_connected_joypads().is_empty() else facing
			attacked.emit(global_position,facing,false)
	if Input.is_action_just_pressed("magic") and cooldown <= 0 and State.s.mana >= 12:
		State.s.mana -= 12
		cooldown = 0.5
		attacked.emit(global_position,facing,true)
	if Input.is_action_just_pressed("quick"): State.use("potion")
	State.s.stamina = minf(State.stat("stamina"),State.s.stamina+dt*18)
	State.s.mana = minf(State.stat("mana"),State.s.mana+dt*2)
	tick += dt
	for effect in statuses.keys():
		statuses[effect] -= dt
		if statuses[effect] <= 0: statuses.erase(effect)
	if tick >= 1:
		tick = 0
		for effect in ["Poison","Burning","Bleeding","Curse"]:
			if statuses.has(effect): hurt(3,Vector2.ZERO)
	queue_redraw()
func hurt(amount: float, direction: Vector2, effect: String = ""):
	if immunity > 0 or locked: return
	State.s.hp -= State.damage(amount,State.stat("defense"),blocking)
	if blocking: State.s.stamina = maxf(0,State.s.stamina-10)
	immunity = .55
	position += direction*12
	if effect != "": statuses[effect] = 4.0
	if State.s.hp <= 0:
		locked = true
		died.emit()
func _draw():
	if cooldown > 0:
		draw_arc(Vector2.ZERO,38,facing.angle()-.65,facing.angle()+.65,12,Color("ead8ab"),3)
	if blocking: draw_arc(Vector2.ZERO,24,facing.angle()-.8,facing.angle()+.8,10,Color("8bc9d0"),3)
