extends Node2D
var map := "village"
var objects: Array = []
var textures: Dictionary = {}
var blockers: Array = []
var walls: Array[Rect2] = []
var layout: Dictionary = {}
var map_data: Dictionary
var lights: Array = []
var time := 0.0
var redraw_timer := 0.0
var darkness: CanvasModulate
const MAP_NAMES = {"village":"Hollowmere Village","forest":"Weeping Forest","crypt":"Forgotten Crypt","shrine":"The Veil Shrine"}
func _ready():
	map_data = State.read_data("maps")
	for id in ["grass","stone","dirt","shrine","tree","grave","chest","checkpoint","door","npc","house","water","cobble","mud","moss","ash","well","forge","stall","cart","rock","ruin","torch","banner","sign","reeds","herb"]:
		textures[id] = load("res://assets/"+id+".png")
	darkness = CanvasModulate.new(); add_child(darkness)
func rect(value: Array) -> Rect2: return Rect2(value[0],value[1],value[2],value[3])
func setup(id: String):
	map = id
	layout = map_data[id]
	objects.clear(); walls.clear()
	for b in blockers: b.queue_free()
	blockers.clear()
	for l in lights: l.queue_free()
	lights.clear()
	darkness.color = Color("788393") if id == "village" else (Color("687789") if id == "forest" else Color("727086"))
	for r in [Rect2(0,0,1440,16),Rect2(0,944,1440,16),Rect2(0,0,16,960),Rect2(1424,0,16,960)]: wall(r)
	for r in layout.walls: wall(rect(r))
	for r in layout.water: wall(rect(r))
	for building in layout.buildings: wall(rect(building.rect))
	for object in layout.objects:
		var o: Dictionary = object.duplicate(true)
		o.pos = Vector2(object.pos[0],object.pos[1])
		objects.append(o)
		if o.kind == "tree": wall(Rect2(o.pos-Vector2(8,0),Vector2(16,18)))
	for pos in layout.lights:
		var light := PointLight2D.new(); light.texture = load("res://assets/glow.png")
		light.position = Vector2(pos[0],pos[1]); light.texture_scale = 2.8
		light.color = Color("e2ae74"); light.energy = .75
		add_child(light); lights.append(light)
	queue_redraw()
func safe_position(pos: Vector2) -> Vector2:
	pos = pos.clamp(Vector2(32,32),Vector2(1408,928))
	if walkable(pos): return pos
	for distance in range(24,700,24):
		for angle in range(16):
			var candidate := pos+Vector2.RIGHT.rotated(angle*TAU/16)*distance
			if walkable(candidate): return candidate
	return Vector2(100,480)
func walkable(pos: Vector2) -> bool:
	if pos.x < 30 or pos.y < 30 or pos.x > 1410 or pos.y > 930: return false
	for r in walls:
		if r.grow(13).has_point(pos): return false
	return true
func _process(dt):
	time += dt; redraw_timer += dt
	if redraw_timer > .15: redraw_timer = 0; queue_redraw()
func wall(r: Rect2):
	walls.append(r)
	var body := StaticBody2D.new(); body.collision_layer = 4; body.collision_mask = 0; body.position = r.get_center()
	var shape := CollisionShape2D.new(); var box := RectangleShape2D.new(); box.size = r.size; shape.shape = box
	body.add_child(shape); add_child(body); blockers.append(body)
func nearest(pos: Vector2) -> Dictionary:
	var result: Dictionary = {}; var distance := 65.0
	for object in objects:
		if object.kind not in ["npc","door","checkpoint","chest","herb","shrine","sign"]: continue
		if State.s.flags.get(object.id,false) and object.kind in ["chest","herb"]: continue
		var d: float = pos.distance_to(object.pos)
		if d < distance: result = object; distance = d
	return result
func _draw():
	if layout.is_empty(): return
	var tile: String = "grass" if map == "village" else ("moss" if map == "forest" else "ash")
	for y in range(20):
		for x in range(30):
			var p := Vector2(x*48+24,y*48+24)
			var t := tile
			for road in layout.roads:
				if rect(road).has_point(p): t = "cobble" if map in ["village","crypt","shrine"] else "mud"
			for water in layout.water:
				if rect(water).has_point(p): t = "water"
			var tint := Color(.87,.88,.92) if (x*7+y*11)%5 == 0 else Color.WHITE
			draw_texture_rect(textures[t],Rect2(x*48,y*48,48,48),false,tint)
	for r in layout.walls:
		draw_texture_rect(textures.stone,rect(r),true,Color("85828e"))
		draw_rect(rect(r),Color("181a23"),false,3)
	for building in layout.buildings:
		var r := rect(building.rect)
		draw_texture_rect(textures.house,r,false,Color("aaa0a5"))
		draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y+18),building.label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e2cbaa"))
	# Landmarks: broken sanctuary dais, soot in the boss chamber, and village graves.
	if map == "crypt":
		draw_circle(Vector2(1200,480),145,Color("292431"))
		draw_arc(Vector2(1200,480),140,0,TAU,48,Color("59505d"),3)
	if map == "shrine":
		for radius in [100,135,170]: draw_arc(Vector2(900,480),radius,0,TAU,48,Color("6c657d"),2)
	var sorted := objects.duplicate()
	sorted.sort_custom(func(a,b): return a.pos.y < b.pos.y)
	for o in sorted:
		if State.s.flags.get(o.id,false) and o.kind in ["chest","herb"]: continue
		var tex: String = "checkpoint" if o.kind == "shrine" else o.kind
		if textures.has(tex):
			var size := Vector2(72,72) if o.kind in ["tree","ruin","well","stall"] else Vector2(48,48)
			var tint := Color.WHITE
			if o.kind == "npc": tint = Color.from_hsv(float(State.npcs.keys().find(o.id))/12,.25,1)
			draw_texture_rect(textures[tex],Rect2(o.pos-Vector2(size.x/2,size.y*.75),size),false,tint)
		if o.kind == "trap":
			for i in range(4): draw_line(o.pos+Vector2(i*6-12,8),o.pos+Vector2(i*6-10,-8),Color("9b8580"),2)
		if o.kind == "npc": draw_string(ThemeDB.fallback_font,o.pos+Vector2(-40,-39),State.npcs[o.id].name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e2cbaa"))
	if map in ["forest","shrine"]:
		for i in range(10):
			var p := Vector2(fmod(i*211+time*4,1440),100+(i*113)%780)
			draw_line(p,p+Vector2(160,4),Color(.48,.55,.64,.08),10)
