extends CanvasLayer
const Typography = preload("res://scripts/typography.gd")
var root: Control
var center: CenterContainer
var panel: PanelContainer
var body: VBoxContainer
var header: Label
var bar_entries: Array = []
var hud: PanelContainer
var info: Label
var weapon: Label
var prompt: Label
var toast: Label
var boss: ProgressBar
var boss_name: Label
var theme_ui: Theme
var desired := Vector2(650,410)
func box(color: String, border: String, margin: int = 10) -> StyleBoxFlat:
	var b := StyleBoxFlat.new(); b.bg_color = Color(color); b.border_color = Color(border); b.set_border_width_all(1)
	b.content_margin_left = margin; b.content_margin_right = margin; b.content_margin_top = margin; b.content_margin_bottom = margin
	return b
func _ready():
	theme_ui = Typography.theme()
	theme_ui.set_color("font_color","Label",Color("dfd3ba"))
	theme_ui.set_stylebox("panel","PanelContainer",box("11151eff","75634a",12))
	for pair in [["normal","20212af5","67563e"],["hover","30303df5","ad9466"],["pressed","393542f5","cfb37d"],["focus","292735f5","d3b781"],["disabled","141720f5","34333b"]]:
		theme_ui.set_stylebox(pair[0],"Button",box(pair[1],pair[2],6))
	theme_ui.set_color("font_color","Button",Color("dfd3ba")); theme_ui.set_color("font_disabled_color","Button",Color("77747a"))
	theme_ui.set_constant("separation","VBoxContainer",7); theme_ui.set_constant("separation","HBoxContainer",12)
	root = Control.new(); root.name = "ScreenUI"; root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.theme = theme_ui; add_child(root)
	root.resized.connect(resize_menu)
	hud = PanelContainer.new(); hud.name = "CompactHUD"; hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); hud.position = Vector2(12,12); hud.custom_minimum_size = Vector2(276,106); root.add_child(hud)
	var contents := VBoxContainer.new(); contents.add_theme_constant_override("separation",3); hud.add_child(contents)
	info = text(contents,"",13)
	for entry in [["HP","hp","a84756"],["SP","stamina","6f8d60"],["MP","mana","586ca5"]]:
		var row := HBoxContainer.new(); contents.add_child(row)
		var caption := text(row,entry[0],11); caption.custom_minimum_size.x = 24; caption.size_flags_horizontal = Control.SIZE_FILL
		var bar := ProgressBar.new(); bar.custom_minimum_size = Vector2(120,7); bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bar.show_percentage = false
		bar.add_theme_stylebox_override("background",box("252630","35343d",0)); bar.add_theme_stylebox_override("fill",box(entry[2],entry[2],0)); row.add_child(bar)
		var value := text(row,"",11); value.custom_minimum_size.x = 65; value.size_flags_horizontal = Control.SIZE_FILL; bar_entries.append([entry[1],bar,value])
	weapon = text(contents,"",11)
	prompt = Label.new(); prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); prompt.offset_left = -220; prompt.offset_right = 220; prompt.offset_top = -45; prompt.offset_bottom = -24; root.add_child(prompt)
	toast = Label.new(); toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); toast.offset_left = 16; toast.offset_right = -20; toast.offset_top = -25; toast.offset_bottom = -4; root.add_child(toast)
	var boss_panel := VBoxContainer.new(); boss_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); boss_panel.offset_left = -305; boss_panel.offset_right = -15; boss_panel.offset_top = 12; boss_panel.offset_bottom = 57; root.add_child(boss_panel)
	boss_name = text(boss_panel,"",24); boss = ProgressBar.new(); boss.show_percentage = false; boss.custom_minimum_size.y = 7; boss.add_theme_stylebox_override("fill",box("9d7053","9d7053",0)); boss_panel.add_child(boss); boss.hide()
	center = CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); center.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(center)
func text(parent: Node, value: String, size: int = 14) -> Label:
	var l := Label.new(); l.text = value; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",Typography.font_size(size)); l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(l); return l
func button(parent: Node, value: String, callback: Callable, enabled: bool = true) -> Button:
	var b := Button.new(); b.text = value; b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; b.custom_minimum_size.y = 28; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.disabled = not enabled; parent.add_child(b); b.pressed.connect(callback); return b
func close():
	if is_instance_valid(panel):
		center.remove_child(panel); panel.hide(); panel.queue_free()
	panel = null
func open(title: String, size: Vector2 = Vector2(650,410), scrolling: bool = true) -> VBoxContainer:
	close(); desired = size
	panel = PanelContainer.new(); panel.name = "MenuPanel"; center.add_child(panel)
	var frame := VBoxContainer.new(); frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL; panel.add_child(frame)
	header = text(frame,title,32 if title.begins_with("ASHEN VEIL") or title.begins_with("CHAPTER") else 24); header.name = "MenuHeading"
	var separator := HSeparator.new(); frame.add_child(separator)
	if scrolling:
		var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; frame.add_child(scroll)
		body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(body)
	else:
		body = VBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; frame.add_child(body)
	resize_menu()
	focus_first.call_deferred()
	return body
func resize_menu():
	if is_instance_valid(panel): panel.custom_minimum_size = Vector2(minf(desired.x,root.size.x-36),minf(desired.y,root.size.y-44))
func update_hud():
	info.text = "LV %d     %d CROWNS"%[State.s.level,State.s.crowns]
	for entry in bar_entries:
		entry[1].max_value = State.stat(entry[0]); entry[1].value = State.s[entry[0]]; entry[2].text = "%d/%d"%[State.s[entry[0]],State.stat(entry[0])]
	weapon.text = State.items[State.s.equipment.weapon].name+"   •   Draught ×%d"%State.s.inventory.get("potion",0)

func focus_first():
	if not is_instance_valid(panel): return
	var available: Array = panel.find_children("*","Button",true,false)
	for b in available:
		if not b.disabled and b.text.begins_with("> "): b.grab_focus(); return
	for b in available:
		if not b.disabled: b.grab_focus(); return

func item_title(parent: Node, id: String):
	var item: Dictionary = State.items[id]
	var row := HBoxContainer.new(); parent.add_child(row)
	var art: String = item.get("kind","")
	if item.slot == "accessory": art = "charm"
	elif item.slot == "" and item.get("effect","") != "": art = "potion"
	elif id == "ore": art = "ore"
	if art != "" and ResourceLoader.exists("res://assets/icons/"+art+".png"):
		var icon := TextureRect.new(); icon.texture = load("res://assets/icons/"+art+".png"); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.custom_minimum_size = Vector2(40,40); row.add_child(icon)
	text(row,item.name,18)
