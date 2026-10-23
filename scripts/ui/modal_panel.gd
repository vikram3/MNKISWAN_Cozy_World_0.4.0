class_name ModalPanel
extends Control
## Base for full-screen modal UI panels. Opening pushes onto GameState's UI stack (which pauses
## time, frees the mouse and blocks gameplay input); closing pops it. Esc/right-click closes.

var panel_id := "panel"
var title_text := ""
var root_box: PanelContainer
var content: VBoxContainer
var _title_label: Label
var _dim: ColorRect


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	theme = UITheme.get_theme()
	_dim = ColorRect.new()
	_dim.color = Color(0.09, 0.23, 0.19, 0.35)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	root_box = PanelContainer.new()
	root_box.custom_minimum_size = panel_size()
	center.add_child(root_box)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	root_box.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	_title_label = UITheme.label(title_text, 38, UITheme.FOREST, true)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title_label)
	head.add_child(UITheme.button("Close (Esc)", close))
	var sep := ColorRect.new()
	sep.color = UITheme.SAGE
	sep.custom_minimum_size.y = 3
	outer.add_child(sep)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	outer.add_child(content)
	build_content()


func panel_size() -> Vector2:
	return Vector2(1300, 820)


func set_title(t: String) -> void:
	title_text = t
	if _title_label:
		_title_label.text = t


## Override to create static widgets.
func build_content() -> void:
	pass


## Override to refresh dynamic content each time the panel opens.
func refresh() -> void:
	pass


func open() -> void:
	if visible:
		return
	visible = true
	GameState.push_ui(panel_id)
	AudioManager.play_sfx("ui")
	refresh()


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.pop_ui(panel_id)
	AudioManager.play_sfx("ui_back")
	closed()


func closed() -> void:
	pass


func scroll_box(parent: Control, min_h: int = 520) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = min_h
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	sc.add_child(v)
	parent.add_child(sc)
	return v
