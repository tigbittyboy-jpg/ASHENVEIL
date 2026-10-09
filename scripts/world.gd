extends Node2D
var map := "village"
var objects: Array = []
var textures: Dictionary = {}
var blockers: Array = []
var time := 0.0
var redraw_timer := 0.0
const MAP_NAMES = {"village":"Hollowmere Village","forest":"Weeping Forest","crypt":"Forgotten Crypt","shrine":"The Veil Shrine"}
func _ready():
	for id in ["grass","stone","dirt","shrine","tree","grave","chest","checkpoint","door","npc","house"]: textures[id] = load("res://assets/"+id+".png")
func setup(id: String):
	map = id
	objects.clear()
	for b in blockers: b.queue_free()
	blockers.clear()
	for rect in [Rect2(0,0,1440,16),Rect2(0,944,1440,16),Rect2(0,0,16,960),Rect2(1424,0,16,960)]: wall(rect)
	match map:
		"village":
			var ids := ["mara","brann","sister","tovin","ilya","osric","vesper","nell"]
			for i in range(8):
				var x := 160+(i%4)*310
				var y := 170+(i/4)*600
				wall(Rect2(x-65,y-100,130,70))
				objects.append({"kind":"npc","id":ids[i],"pos":Vector2(x,y)})
			objects.append({"kind":"checkpoint","id":"village","pos":Vector2(650,480)})
			objects.append({"kind":"door","id":"forest","pos":Vector2(1360,480),"label":"Weeping Forest"})
		"forest":
			for i in range(38):
				var p := Vector2(90+(i*137)%1250,90+(i*193)%760)
				if p.distance_to(Vector2(700,480)) > 110 and absf(p.y-480)>65:
					objects.append({"kind":"tree","id":"tree%d"%i,"pos":p})
					wall(Rect2(p-Vector2(10,0),Vector2(20,20)))
			objects.append({"kind":"door","id":"village","pos":Vector2(65,480),"label":"Hollowmere"})
			objects.append({"kind":"door","id":"crypt","pos":Vector2(1360,480),"label":"Crypt — requires Sigil"})
			objects.append({"kind":"checkpoint","id":"forest","pos":Vector2(700,470)})
			for i in range(5): objects.append({"kind":"herb","id":"herb%d"%i,"pos":Vector2(300+i*175,230+(i%2)*410)})
			objects.append({"kind":"chest","id":"forest_charm","pos":Vector2(400,790)})
			objects.append({"kind":"chest","id":"forest_cache","pos":Vector2(1080,190)})
		"crypt":
			for x in [480,960]:
				wall(Rect2(x,16,24,355))
				wall(Rect2(x,585,24,359))
			for i in range(12): objects.append({"kind":"grave","id":"grave%d"%i,"pos":Vector2(150+(i%6)*205,180+(i/6)*540)})
			objects.append({"kind":"door","id":"forest","pos":Vector2(65,480),"label":"Forest"})
			objects.append({"kind":"door","id":"shrine","pos":Vector2(1360,480),"label":"Veil Shrine — Bellkeeper seal"})
			objects.append({"kind":"checkpoint","id":"crypt","pos":Vector2(580,480)})
			objects.append({"kind":"chest","id":"crypt_cache","pos":Vector2(780,780)})
			objects.append({"kind":"trap","id":"trap1","pos":Vector2(730,430)})
			objects.append({"kind":"trap","id":"trap2","pos":Vector2(820,530)})
		"shrine":
			objects.append({"kind":"door","id":"crypt","pos":Vector2(65,480),"label":"Crypt"})
			objects.append({"kind":"shrine","id":"ending","pos":Vector2(900,480)})
			objects.append({"kind":"checkpoint","id":"shrine","pos":Vector2(500,480)})
	queue_redraw()
func _process(dt):
	time += dt
	redraw_timer += dt
	if redraw_timer > .15:
		redraw_timer = 0
		queue_redraw()
func wall(rect: Rect2):
	var body := StaticBody2D.new()
	body.collision_layer = 4
	body.collision_mask = 0
	body.position = rect.position+rect.size/2
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	body.add_child(shape)
	add_child(body)
	blockers.append(body)
func nearest(pos: Vector2) -> Dictionary:
	var nearest_object: Dictionary = {}
	var distance := 65.0
	for object in objects:
		if object.kind in ["tree","grave","trap"]: continue
		if State.s.flags.get(object.id,false) and object.kind in ["chest","herb"]: continue
		var d: float = pos.distance_to(object.pos)
		if d < distance: nearest_object = object; distance = d
	return nearest_object
func _draw():
	var tile: String = "grass" if map in ["village","forest"] else ("stone" if map == "crypt" else "shrine")
	for y in range(20):
		for x in range(30):
			var t := "dirt" if map in ["village","forest"] and y in [9,10] else tile
			draw_texture_rect(textures[t],Rect2(x*48,y*48,48,48),false)
	for b in blockers:
		if not is_instance_valid(b) or not b.get_child(0).shape is RectangleShape2D: continue
		var size: Vector2 = b.get_child(0).shape.size
		if size.x > 30 and size.y > 30:
			if map == "village": draw_texture_rect(textures.house,Rect2(b.position-size/2-Vector2(10,45),size+Vector2(20,45)),false)
			else:
				draw_texture_rect(textures.stone,Rect2(b.position-size/2,size),true)
	for o in objects:
		if State.s.flags.get(o.id,false) and o.kind in ["chest","herb"]: continue
		var tex: String = "checkpoint" if o.kind in ["herb","shrine"] else o.kind
		if textures.has(tex):
			var tint := Color("aad8b3") if o.kind == "herb" else Color.WHITE
			if o.kind == "npc": tint = Color.from_hsv(float(State.npcs.keys().find(o.id))/12.0,.25,1.0)
			draw_texture_rect(textures[tex],Rect2(o.pos-Vector2(24,36),Vector2(48,48)),false,tint)
		if o.kind == "trap":
			for i in range(4): draw_line(o.pos+Vector2(i*6-12,8),o.pos+Vector2(i*6-10,-8),Color("c9b6aa"),2)
		if o.kind == "npc":
			draw_string(ThemeDB.fallback_font,o.pos+Vector2(-45,-40),State.npcs[o.id].name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e2cbaa"))

	# Ambient lantern halos and drifting fog remain independent of collision.
	for o in objects:
		if o.kind in ["checkpoint","shrine","npc"]:
			for i in range(3): draw_circle(o.pos,20+i*14,Color(.8,.67,.4,.018))
	if map in ["forest","shrine"]:
		for i in range(10):
			var p := Vector2(fmod(i*211+time*7,1440),100+(i*113)%780)
			draw_line(p,p+Vector2(120,4),Color(.58,.67,.72,.08),8)
