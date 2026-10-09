extends RefCounted
const FONT = preload("res://assets/fonts/PixelifySans.ttf")
const SMALL = 16
const HEADING = 24
const TITLE = 32
static func font_size(requested: int) -> int:
	return TITLE if requested >= 28 else (HEADING if requested >= 18 else SMALL)
static func theme() -> Theme:
	var result := Theme.new(); result.default_font = FONT; result.default_font_size = SMALL
	result.set_constant("line_spacing","Label",4)
	result.set_color("font_shadow_color","Label",Color("080a10"))
	result.set_constant("shadow_offset_x","Label",1); result.set_constant("shadow_offset_y","Label",1)
	return result
