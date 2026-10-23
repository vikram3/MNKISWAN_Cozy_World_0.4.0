class_name SettingsPanel
extends ModalPanel
## Settings (GDD §12 accessibility): separate volume sliders, mouse sensitivity, invert-Y, run
## hold/toggle, easier fishing, reduced motion, window mode, text size, key remapping, reset.

var _listening_action := ""
var _remap_buttons: Dictionary = {}
var _status: Label


func _init() -> void:
	super._init()
	panel_id = "settings"
	title_text = "Settings"


func panel_size() -> Vector2:
	return Vector2(1300, 900)


func build_content() -> void:
	_status = UITheme.label("", 20, UITheme.CORAL)
	content.add_child(_status)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tabs)
	var gen := VBoxContainer.new()
	gen.name = "Audio & Camera"
	gen.add_theme_constant_override("separation", 12)
	tabs.add_child(gen)
	_slider(gen, "Master volume", "master_volume", 0.0, 1.0)
	_slider(gen, "Music", "music_volume", 0.0, 1.0)
	_slider(gen, "Ambience", "ambience_volume", 0.0, 1.0)
	_slider(gen, "Effects", "sfx_volume", 0.0, 1.0)
	_slider(gen, "Mouse sensitivity", "mouse_sensitivity", 0.05, 0.8)
	_check(gen, "Invert camera Y", "invert_y")
	_check(gen, "Reduced motion (camera smoothing & UI effects)", "reduced_motion")
	var acc := VBoxContainer.new()
	acc.name = "Gameplay & Display"
	acc.add_theme_constant_override("separation", 12)
	tabs.add_child(acc)
	_check(acc, "Run is a toggle (instead of hold)", "run_toggle")
	_check(acc, "Easier fishing (wider bite window)", "fishing_easy")
	_check(acc, "Mnki and Swan chat during quiet moments", "idle_conversations")
	_check(acc, "Quiet HUD (hide the quest reminder)", "quiet_hud")
	var pace := HBoxContainer.new()
	pace.add_child(UITheme.label("Minutes per day", 24))
	var days := OptionButton.new()
	for minutes in [12, 24, 36, 60]: days.add_item(str(minutes))
	days.selected = [12, 24, 36, 60].find(int(Settings.get_value("day_minutes")))
	days.item_selected.connect(func(i): Settings.set_value("day_minutes", [12, 24, 36, 60][i]))
	pace.add_child(days)
	acc.add_child(pace)
	var wm := HBoxContainer.new()
	acc.add_child(wm)
	var wl := UITheme.label("Window mode", 24)
	wl.custom_minimum_size.x = 360
	wm.add_child(wl)
	var ob := OptionButton.new()
	for m in ["windowed", "borderless", "fullscreen"]:
		ob.add_item(m.capitalize())
	ob.selected = ["windowed", "borderless", "fullscreen"].find(String(Settings.get_value("window_mode")))
	ob.item_selected.connect(func(i): Settings.set_value("window_mode", ["windowed", "borderless", "fullscreen"][i]))
	wm.add_child(ob)
	_slider(acc, "Text size (applies when menus reopen)", "text_scale", 0.85, 1.4)
	var keys := VBoxContainer.new()
	keys.name = "Controls"
	tabs.add_child(keys)
	keys.add_child(UITheme.label("Click a binding, then press a key (Esc cancels).", 20, UITheme.MUTED))
	var list := scroll_box(keys, 560)
	for action in Settings.ACTIONS:
		if action in ["pause", "cancel"]:
			continue
		var row := HBoxContainer.new()
		var l := UITheme.label(String(Settings.ACTIONS[action][0]), 22)
		l.custom_minimum_size.x = 380
		row.add_child(l)
		var b := UITheme.button(Settings.binding_label(action), func(): _listen(action), 320)
		_remap_buttons[action] = b
		row.add_child(b)
		list.add_child(row)
	var foot := HBoxContainer.new()
	content.add_child(foot)
	foot.add_child(UITheme.button("Reset to defaults", func():
		Settings.reset_defaults()
		_status.text = "Defaults restored."
		_refresh_keys(), 300))


func _slider(parent: Control, text: String, key: String, mn: float, mx: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var l := UITheme.label(text, 24)
	l.custom_minimum_size.x = 460
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = 0.01
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(480, 32)
	var val := UITheme.label("%d%%" % int(s.value * 100) if mx <= 1.0 else "%.2f" % s.value, 22)
	s.value_changed.connect(func(v):
		Settings.set_value(key, v)
		val.text = "%d%%" % int(v * 100) if mx <= 1.0 else "%.2f" % v
		if key == "text_scale":
			UITheme.rebuild())
	row.add_child(s)
	row.add_child(val)


func _check(parent: Control, text: String, key: String) -> void:
	var c := CheckBox.new()
	c.text = text
	c.add_theme_font_size_override("font_size", 24)
	c.button_pressed = bool(Settings.get_value(key))
	c.toggled.connect(func(on): Settings.set_value(key, on))
	parent.add_child(c)


func _listen(action: String) -> void:
	_listening_action = action
	(_remap_buttons[action] as Button).text = "Press a key..."


func _refresh_keys() -> void:
	for a in _remap_buttons:
		(_remap_buttons[a] as Button).text = Settings.binding_label(a)


func _input(event: InputEvent) -> void:
	if _listening_action == "" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode != KEY_ESCAPE:
			Settings.rebind(_listening_action, event.physical_keycode)
			_status.text = "%s is now %s" % [String(Settings.ACTIONS[_listening_action][0]), OS.get_keycode_string(event.physical_keycode)]
		_listening_action = ""
		_refresh_keys()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and _listening_action != "":
		pass


func refresh() -> void:
	_status.text = ""
	_refresh_keys()
