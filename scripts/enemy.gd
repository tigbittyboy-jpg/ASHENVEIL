extends CharacterBody2D
signal killed(enemy)
signal projectile(origin: Vector2, direction: Vector2, damage: float, effect: String)
signal summon(origin: Vector2)
var kind := "wanderer"
var stable_id := ""
var elite := false
var target
var home := Vector2.ZERO
var hp := 1.0
var max_hp := 1.0
var state := "Patrol"
var timer := 0.0
var phase := 1
var attack_style := 0
var attack_direction := Vector2.ZERO
var attack_origin := Vector2.ZERO
var attack_radius := 52.0
var windup_duration := .6
var sprite: Sprite2D
var data: Dictionary
func _ready():
	data = State.enemies[kind]
	max_hp = data.hp*(2.0 if elite else 1.0)
	hp = max_hp
	home = position
	collision_layer = 2
	collision_mask = 4
	var c := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18 if kind == "boss" else 12
	c.shape = shape
	add_child(c)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/"+kind+".png")
	sprite.scale = Vector2.ONE*(1.15 if kind == "boss" else 1.0)
	add_child(sprite)
func _physics_process(dt):
	if not is_instance_valid(target) or target.locked: return
	timer -= dt
	var delta: Vector2 = target.global_position-global_position
	var distance: float = delta.length()
	if kind == "boss":
		var next_phase := 3 if hp < max_hp*.25 else (2 if hp < max_hp*.65 else 1)
		if next_phase > phase:
			phase = next_phase
			State.notice.emit("The Bellkeeper — phase %d" % phase)
			if phase == 2: summon.emit(position+Vector2(75,0)); summon.emit(position-Vector2(75,0))
	match state:
		"Stunned":
			velocity = Vector2.ZERO
			if timer <= 0: state = "Chase"
		"Attack":
			velocity = Vector2.ZERO
			if timer <= 0:
				if kind in ["cultist","wraith"]:
					projectile.emit(position,attack_direction,data.attack,"Curse" if kind == "wraith" else "Burning")
				elif kind == "boss":
					if target.position.distance_to(attack_origin) <= attack_radius: target.hurt(data.attack+(phase-1)*2,delta.normalized())
					if phase >= 2 and attack_style != 0:
						for i in range(6): projectile.emit(attack_origin,Vector2.RIGHT.rotated(i*TAU/6+.35),7,"")
				elif distance < attack_radius: target.hurt(data.attack,delta.normalized(),"Poison" if kind == "hound" else "")
				state = "Recover"
				timer = [1.5,1.3,1.15][phase-1] if kind == "boss" else 1.1
		"Recover":
			velocity = Vector2.ZERO
			if timer <= 0: state = "Chase"
		"Retreat":
			velocity = (home-position).normalized()*data.speed
			if position.distance_to(home) < 15: state = "Patrol"; hp = minf(max_hp,hp+dt*10)
		_:
			var visible := true
			var query := PhysicsRayQueryParameters2D.create(global_position,target.global_position,4)
			visible = get_world_2d().direct_space_state.intersect_ray(query).is_empty()
			if position.distance_to(home) > 440 and kind != "boss": state = "Retreat"
			elif distance < (330 if kind == "boss" else 240) and visible:
				state = "Chase"
				var reach := 200 if kind in ["cultist","wraith"] else (84 if kind == "boss" else 42)
				if distance < reach:
					state = "Attack"
					attack_style = (attack_style+1)%3
					attack_radius = (82.0 if attack_style == 0 else 64.0) if kind == "boss" else (55.0 if kind == "hound" else 48.0)
					windup_duration = [1.05,.95,.85][phase-1] if kind == "boss" else (.85 if kind == "guardian" else .6)
					timer = windup_duration
					attack_origin = position
					velocity = Vector2.ZERO
					attack_direction = delta.normalized()
				else: velocity = delta.normalized()*data.speed*(1.0+phase*.15)
			else:
				state = "Patrol"
				velocity = Vector2(sin(Time.get_ticks_msec()/1300.0+home.x),cos(Time.get_ticks_msec()/1500.0))*data.speed*.22
	move_and_slide()
	sprite.flip_h = delta.x < 0
	sprite.position.y = sin(Time.get_ticks_msec()/90.0)*1.5 if velocity.length()>5 else 0
	queue_redraw()
func hurt(amount: float, direction: Vector2, magic: bool = false):
	if hp <= 0: return
	var armor := 7 if kind == "guardian" else 0
	if kind == "knight" and state == "Recover" and not magic: armor = 10
	hp -= State.damage(amount,armor)
	if kind != "boss": position += direction*8
	if state != "Attack": state = "Stunned"; timer = .16
	if hp <= 0:
		state = "Dead"
		killed.emit(self)
		queue_free()
func _draw():
	if hp < max_hp:
		draw_rect(Rect2(-20,-32,40,3),Color("292838"))
		draw_rect(Rect2(-20,-32,40*maxf(0,hp)/max_hp,3),Color("d29c7c"))
	if state == "Attack":
		var radius := attack_radius
		draw_circle(attack_origin-position if kind == "boss" else Vector2.ZERO,radius,Color(0.8,0.3,0.25,.18))
		draw_arc(attack_origin-position if kind == "boss" else Vector2.ZERO,radius,0,TAU,32,Color("e09b68"),2)
