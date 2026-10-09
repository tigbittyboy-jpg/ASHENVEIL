extends PanelContainer
const Typography = preload("res://scripts/typography.gd")
var anchor := Vector2.ZERO
var entrance := Vector2.ZERO
var identity := ""
var kind := "building"
var visibility_range := 175.0
var target_visible := false
func configure(id: String, text: String, at: Vector2, near: Vector2, category: String):
	identity = id; name = "WorldLabel_"+id; anchor = at; entrance = near; kind = category
	visibility_range = 95.0 if category == "npc" else 175.0
	theme = Typography.theme(); mouse_filter = Control.MOUSE_FILTER_IGNORE; z_index = 100
	var background := StyleBoxFlat.new(); background.bg_color = Color("10131de8"); background.border_color = Color("75634a")
	background.set_border_width_all(1); background.content_margin_left = 5; background.content_margin_right = 5; background.content_margin_top = 2; background.content_margin_bottom = 2
	add_theme_stylebox_override("panel",background)
	var caption := Label.new(); caption.text = text; caption.add_theme_color_override("font_color",Color("f0dfbb")); caption.use_parent_material = true; caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(caption)
	var unlit := CanvasItemMaterial.new(); unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED; material = unlit
	modulate.a = 0; hide()
func place(zoom: Vector2, placement: int = 0):
	size = get_combined_minimum_size(); scale = Vector2.ONE/zoom
	var at := anchor
	if kind == "building":
		if placement == 1: at = entrance+Vector2(0,70)
		elif placement == 2: at = entrance+Vector2(120,12)
		elif placement == 3: at = entrance+Vector2(-120,12)
	position = at-Vector2(size.x*scale.x/2,size.y*scale.y)
func screen_rect() -> Rect2:
	var transform := get_global_transform_with_canvas()
	return Rect2(transform*Vector2.ZERO,size*transform.get_scale().abs())
func fade(dt: float):
	modulate.a = move_toward(modulate.a,1.0 if target_visible else 0.0,dt*10)
	visible = modulate.a > 0
