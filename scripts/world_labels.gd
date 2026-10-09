extends Node2D
const WorldLabel = preload("res://scripts/world_label.gd")
var entries: Array = []
var actor_positions: Array[Vector2] = []
@export var enabled := true
@export var building_range := 175.0
@export var npc_range := 95.0
func rebuild(layout: Dictionary, objects: Array):
	for label in entries: remove_child(label); label.queue_free()
	entries.clear(); actor_positions.clear()
	for building in layout.buildings:
		var r := Rect2(building.rect[0],building.rect[1],building.rect[2],building.rect[3])
		var label := WorldLabel.new(); add_child(label)
		var entrance := Vector2(r.get_center().x,r.end.y+28)
		label.configure(building.label,building.label,Vector2(r.get_center().x,r.position.y-8),entrance,"building"); entries.append(label)
	for object in objects:
		if object.kind == "npc": actor_positions.append(object.pos)
		if object.kind not in ["npc","stall"]: continue
		var label := WorldLabel.new(); add_child(label)
		if object.kind == "npc": label.configure(object.id,State.npcs[object.id].name,object.pos+Vector2(0,-56),object.pos,"npc")
		else: label.configure(object.id,"Mara's Wares",object.pos+Vector2(0,-60),object.pos+Vector2(0,45),"building")
		entries.append(label)
func update_labels(player: Vector2, gameplay: bool, hud: Rect2, prompt: Rect2, dt: float):
	var candidates: Array = []; var zoom := get_global_transform_with_canvas().get_scale().abs()
	var viewport := Rect2(Vector2(4,4),get_viewport_rect().size-Vector2(8,8))
	var transform := get_global_transform_with_canvas()
	var actors: Array[Rect2] = []
	for pos in actor_positions+[player]:
		actors.append(Rect2(transform*(pos-Vector2(24,48)),Vector2(48,68)*zoom))
	for label in entries:
		label.target_visible = false
		if not gameplay or not enabled:
			label.modulate.a = 0; label.hide(); continue
		var distance: float = player.distance_to(label.entrance)
		var maximum := npc_range if label.kind == "npc" else building_range
		var safe := false; var rect: Rect2
		for placement in range(4 if label.kind == "building" else 1):
			label.place(zoom,placement); rect = label.screen_rect()
			safe = viewport.encloses(rect) and not rect.intersects(hud.grow(6)) and not rect.intersects(prompt.grow(5))
			if label.kind == "building":
				for actor in actors:
					if rect.intersects(actor): safe = false; break
			if safe: break
		if distance <= maximum and safe: candidates.append({"label":label,"distance":distance,"rect":rect})
		elif not safe: label.modulate.a = 0
	candidates.sort_custom(func(a,b): return a.distance < b.distance)
	var occupied: Array[Rect2] = []
	for entry in candidates:
		var blocked := false
		for other in occupied:
			if entry.rect.grow(4).intersects(other): blocked = true; break
		if not blocked: entry.label.target_visible = true; occupied.append(entry.rect)
	for label in entries:
		# Immediately hide displaced labels; otherwise a fade could briefly overlap a winner.
		if not label.target_visible and candidates.any(func(c): return c.label == label): label.modulate.a = 0
		label.fade(dt)
