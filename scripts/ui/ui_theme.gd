class_name UITheme
extends RefCounted
## GDD §13 UI palette: soft panels, cream backgrounds, forest-green text, sparing coral/gold.

const FOREST := Color("173b31")
const SAGE := Color("dde9d7")
const CREAM := Color("fbf7ed")
const CORAL := Color("e77f6e")
const TEAL := Color("78c9d4")
const GOLD := Color("e4b96b")
const WOOD := Color("8b6749")
const MUTED := Color("6b7a72")

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = build(float(Settings.get_value("text_scale")))
	return _theme


static func rebuild() -> void:
	_theme = build(float(Settings.get_value("text_scale")))


static func box(bg: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), bw: int = 0, pad: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.7
	sb.content_margin_bottom = pad * 0.7
	sb.shadow_color = Color(0.09, 0.23, 0.19, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	return sb


static func build(scale: float) -> Theme:
	var t := Theme.new()
	t.default_font_size = int(26 * scale)
	t.set_color("font_color", "Label", FOREST)
	t.set_color("font_color", "RichTextLabel", FOREST)
	t.set_color("default_color", "RichTextLabel", FOREST)
	t.set_stylebox("panel", "Panel", box(CREAM, 22, SAGE, 3, 18))
	t.set_stylebox("panel", "PanelContainer", box(CREAM, 22, SAGE, 3, 18))
	var btn := box(SAGE, 14, Color(0, 0, 0, 0), 0, 12)
	btn.shadow_size = 0
	var btn_h := box(GOLD.lightened(0.35), 14, GOLD, 2, 12)
	btn_h.shadow_size = 0
	var btn_p := box(GOLD, 14, WOOD, 2, 12)
	btn_p.shadow_size = 0
	var btn_d := box(Color(0.87, 0.87, 0.84), 14, Color(0, 0, 0, 0), 0, 12)
	btn_d.shadow_size = 0
	var btn_f := box(Color(0, 0, 0, 0), 14, CORAL, 3, 12)
	btn_f.shadow_size = 0
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn_h)
	t.set_stylebox("pressed", "Button", btn_p)
	t.set_stylebox("disabled", "Button", btn_d)
	t.set_stylebox("focus", "Button", btn_f)
	t.set_color("font_color", "Button", FOREST)
	t.set_color("font_hover_color", "Button", FOREST)
	t.set_color("font_pressed_color", "Button", FOREST)
	t.set_color("font_focus_color", "Button", FOREST)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, 10, SAGE, 2, 8))
	t.set_color("font_color", "CheckBox", FOREST)
	t.set_color("font_hover_color", "CheckBox", FOREST)
	t.set_color("font_pressed_color", "CheckBox", FOREST)
	t.set_color("font_color", "OptionButton", FOREST)
	t.set_stylebox("normal", "OptionButton", btn)
	t.set_stylebox("hover", "OptionButton", btn_h)
	t.set_stylebox("focus", "OptionButton", btn_f)
	var tab_sel := box(CREAM, 12, GOLD, 2, 12)
	tab_sel.shadow_size = 0
	var tab_un := box(SAGE, 12, Color(0, 0, 0, 0), 0, 12)
	tab_un.shadow_size = 0
	t.set_stylebox("tab_selected", "TabContainer", tab_sel)
	t.set_stylebox("tab_unselected", "TabContainer", tab_un)
	t.set_stylebox("tab_hovered", "TabContainer", btn_h)
	t.set_stylebox("panel", "TabContainer", box(Color(1, 1, 1, 0.55), 14, Color(0, 0, 0, 0), 0, 12))
	t.set_color("font_selected_color", "TabContainer", FOREST)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", FOREST)
	var grab := box(GOLD, 10)
	grab.shadow_size = 0
	t.set_stylebox("slider", "HSlider", box(SAGE, 6, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber_area", "HSlider", box(GOLD, 6, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(CORAL, 6, Color(0, 0, 0, 0), 0, 4))
	return t


static func label(text: String, size: int = 0, color: Color = FOREST, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", int(size * float(Settings.get_value("text_scale"))))
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_constant_override("outline_size", 1)
		l.add_theme_color_override("font_outline_color", color)
	return l


static func button(text: String, cb: Callable, min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(func():
		AudioManager.play_sfx("ui")
		cb.call())
	return b


## A small round "icon" for an item: colour disc + initial (no external art needed).
static func item_icon(id: String, size: int = 44) -> Control:
	var c := PanelContainer.new()
	c.custom_minimum_size = Vector2(size, size)
	var sb := box(ItemDB.color_of(id), int(size / 2.0), FOREST.lightened(0.2), 2, 0)
	sb.shadow_size = 0
	c.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = ItemDB.display_name(id).substr(0, 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(size * 0.5))
	var lum := ItemDB.color_of(id).get_luminance()
	l.add_theme_color_override("font_color", FOREST if lum > 0.55 else CREAM)
	c.add_child(l)
	return c


static func clear(node: Node) -> void:
	for ch in node.get_children():
		node.remove_child(ch)
		ch.queue_free()


## Anchor a control to a preset point and offset it from that anchor (pixels in 1920x1080 canvas).
static func place(c: Control, preset: int, offset: Vector2) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x
	c.offset_bottom = offset.y
