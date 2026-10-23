extends Control
## Title menu (GDD §12): Continue, New Game (confirms overwrite), Settings, Credits, Quit.
## Background is the official MNKISWAN couple artwork supplied by the owner.

var _settings: SettingsPanel
var _confirm: PanelContainer
var _credits: PanelContainer
var _buttons: VBoxContainer
var _t := 0.0
var _bg: TextureRect


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.in_world = false
	GameState.clear_ui()
	var bgc := ColorRect.new()
	bgc.color = UITheme.CREAM
	bgc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bgc)
	_bg = TextureRect.new()
	_bg.texture = load("res://assets/characters/title_couple.jpg")
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UITheme.place(_bg, Control.PRESET_CENTER_RIGHT, Vector2(-1120, -470))
	_bg.custom_minimum_size = Vector2(1100, 840)
	add_child(_bg)
	var left := VBoxContainer.new()
	UITheme.place(left, Control.PRESET_CENTER_LEFT, Vector2(110, -400))
	left.custom_minimum_size = Vector2(640, 800)
	left.add_theme_constant_override("separation", 14)
	add_child(left)
	var t1 := UITheme.label("MNKISWAN", 104, Color("d8302b"), true)
	t1.add_theme_constant_override("outline_size", 18)
	t1.add_theme_color_override("font_outline_color", Color.WHITE)
	left.add_child(t1)
	var t2 := UITheme.label("COZY WORLD", 54, UITheme.FOREST, true)
	left.add_child(t2)
	left.add_child(UITheme.label("Two friends. One village. A whole sky to explore.", 26, UITheme.MUTED))
	left.add_child(UITheme.label("Play as Mnki & Swan · Switch with C · Swan flies with F", 21, UITheme.FOREST))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	left.add_child(spacer)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	left.add_child(_buttons)
	var summary := SaveManager.save_summary()
	if summary != "":
		_add_btn("Continue  (%s)" % summary, func(): SceneRouter.go_world(true))
	_add_btn("New Game", _new_game)
	_add_btn("Settings", func(): _settings.open())
	_add_btn("Credits", func(): _credits.visible = true)
	_add_btn("Quit", func(): get_tree().quit())
	(_buttons.get_child(0) as Button).call_deferred("grab_focus")
	var ver := UITheme.label("Days Together · v0.4.0 · Single-player", 18, UITheme.MUTED)
	UITheme.place(ver, Control.PRESET_BOTTOM_LEFT, Vector2(24, -44))
	add_child(ver)
	_build_confirm()
	_build_credits()
	_settings = SettingsPanel.new()
	add_child(_settings)


func _add_btn(text: String, cb: Callable) -> void:
	var b := UITheme.button(text, cb, 520)
	b.custom_minimum_size.y = 72
	b.add_theme_font_size_override("font_size", 32)
	_buttons.add_child(b)


func _new_game() -> void:
	if SaveManager.has_save():
		_confirm.visible = true
		return
	SceneRouter.go_world(false)


func _build_confirm() -> void:
	_confirm = PanelContainer.new()
	UITheme.place(_confirm, Control.PRESET_CENTER, Vector2(-380, -150))
	_confirm.custom_minimum_size = Vector2(760, 300)
	_confirm.visible = false
	add_child(_confirm)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_confirm.add_child(v)
	var l := UITheme.label("Start a new game? Your current saved progress will be replaced when the new game first saves.", 26)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 700
	v.add_child(l)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	h.add_child(UITheme.button("Yes, start fresh", func():
		_confirm.visible = false
		SceneRouter.go_world(false), 320))
	h.add_child(UITheme.button("Keep my save", func(): _confirm.visible = false, 320))


func _build_credits() -> void:
	_credits = PanelContainer.new()
	UITheme.place(_credits, Control.PRESET_CENTER, Vector2(-520, -340))
	_credits.custom_minimum_size = Vector2(1040, 680)
	_credits.visible = false
	add_child(_credits)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_credits.add_child(v)
	v.add_child(UITheme.label("Credits", 44, UITheme.FOREST, true))
	var text := "MNKISWAN, Mnki and Swan are an original creative universe and IP by the MNKISWAN creator. Character art and designs © their owner.\n\nGame design: MNKISWAN Cozy World GDD v1.0 (22 Oct 2026).\nEngine: Godot Engine 4.7.2 (MIT licence) — godotengine.org.\nCharacter consistency: MNKISWAN Character Consistency Kit v1.0 (official sticker references).\n\nThis build uses procedural, original placeholder 3D models, music and sound effects generated in-engine. Final hero models, animation and audio replace them in production.\n\nThanks for playing — be gentle with the chickens."
	var l := UITheme.label(text, 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 980
	v.add_child(l)
	v.add_child(UITheme.button("Close", func(): _credits.visible = false, 200))


func _process(delta: float) -> void:
	_t += delta
	if _bg and not Settings.get_value("reduced_motion"):
		_bg.pivot_offset = _bg.size * 0.5
		_bg.rotation = sin(_t * 0.6) * 0.008
		_bg.scale = Vector2.ONE * (1.0 + sin(_t * 0.9) * 0.008)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if _settings.visible:
			_settings.close()
		_confirm.visible = false
		_credits.visible = false
