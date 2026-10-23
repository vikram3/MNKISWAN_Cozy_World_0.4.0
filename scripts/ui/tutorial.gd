class_name Tutorial
extends Control
## First-play guide: six short, skippable steps that finish themselves when the player actually
## does the thing (walk, look, follow the waypoint, interact, open a menu, meet Swan). Text and
## highlights adapt to touch or keyboard. Never blocks input; hides while menus/dialogue are up.
## Replay from Settings → Touch & HUD.

signal finished(skipped: bool)

const STEPS := [
	{"id": "move", "title": "Take a walk",
		"touch": "Drag anywhere on the left side to walk. Push the stick to its edge to run.",
		"keys": "Walk with {move}. Hold {run} to run.", "focus": "stick"},
	{"id": "look", "title": "Look around",
		"touch": "Swipe on the right side to turn the camera. Pinch with two fingers to zoom.",
		"keys": "Move the mouse to look around. Scroll to zoom.", "focus": "look"},
	{"id": "waypoint", "title": "Follow the pin",
		"touch": "The coral pin marks your next goal — it's on the minimap too. Off screen, an arrow points the way.",
		"keys": "The coral pin marks your next goal — it's on the minimap too. Off screen, an arrow points the way.", "focus": "minimap"},
	{"id": "interact", "title": "Say hello",
		"touch": "When the big button glows, tap it to talk, gather, farm or fish. Swan is waiting for you!",
		"keys": "When a prompt appears, press {interact} to talk, gather, farm or fish. Swan is waiting for you!", "focus": "act"},
	{"id": "menus", "title": "Your things",
		"touch": "Shared moments, journal, bag and map live under the minimap. Tap the map to drop your own pin.",
		"keys": "{together} together · {journal} journal · {inventory} bag · {map} map. Click the big map to drop your own pin.", "focus": "menus"},
	{"id": "swan", "title": "Two friends, one sky",
		"touch": "Tap your friend's portrait to switch. As Swan, tap Fly to spread your wings!",
		"keys": "Press {switch_character} to switch friends. As Swan, press {fly} to spread your wings!", "focus": "swap"},
]

var step := -1
var running := false
var _t := 0.0           # time in the current step
var _start_pos := Vector3.ZERO
var _start_look := 0.0
var _start_dist := -1.0
var _card: PanelContainer
var _title: Label
var _body: Label
var _dots: HBoxContainer
var _next: Button
var _skip: Button
var _anim := 0.0
var _seen_dialogue := false
var _start_char := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_PASS
	_card.add_to_group("touch_passthrough")
	var sb := UITheme.box(Color(UITheme.CREAM, 0.97), 22, UITheme.GOLD, 3, 20)
	_card.add_theme_stylebox_override("panel", sb)
	add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_card.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_title = UITheme.label("", 30, UITheme.CORAL, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 6)
	head.add_child(_dots)
	for i in STEPS.size():
		var d := PanelContainer.new()
		d.custom_minimum_size = Vector2(14, 14)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_dots.add_child(d)
	_body = UITheme.label("", 24)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = 620
	v.add_child(_body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_skip = UITheme.button("Skip tutorial", func(): finish(true))
	_skip.add_theme_font_size_override("font_size", 20)
	row.add_child(_skip)
	_next = UITheme.button("Next", func(): _advance())
	_next.add_theme_font_size_override("font_size", 20)
	row.add_child(_next)
	visible = false


func start() -> void:
	running = true
	step = -1
	_advance()


func _advance() -> void:
	step += 1
	_t = 0.0
	if step >= STEPS.size():
		finish(false)
		return
	var p := GameState.player as MnkiController
	if p:
		_start_pos = p.global_position
		_start_char = p.character_id
		_start_look = p.rig.yaw_radians() if p.rig else 0.0
	_start_dist = _quest_distance()
	_seen_dialogue = false
	AudioManager.play_sfx("chime" if step > 0 else "ui")
	_refresh_text()


func finish(skipped: bool) -> void:
	if not running:
		return
	running = false
	visible = false
	Settings.set_value("tutorial_done", true)
	GameState.notify("Tutorial skipped — replay it anytime in Settings." if skipped else "Tutorial complete! Replay it anytime in Settings.", "discovery")
	finished.emit(skipped)


func current_id() -> String:
	return "" if step < 0 or step >= STEPS.size() else String(STEPS[step].id)


func _refresh_text() -> void:
	if step < 0 or step >= STEPS.size():
		return
	var s: Dictionary = STEPS[step]
	_title.text = "%s" % s.title
	var txt := String(s.touch if MobileUI.touch_enabled() else s.keys)
	txt = txt.replace("{move}", "WASD").replace("{run}", Settings.binding_label("run").get_slice(" / ", 0))
	for a in ["interact", "together", "journal", "inventory", "map", "switch_character", "fly"]:
		txt = txt.replace("{%s}" % a, Settings.binding_label(a).get_slice(" / ", 0))
	_body.text = txt
	for i in _dots.get_child_count():
		var d := _dots.get_child(i) as PanelContainer
		var col := UITheme.CORAL if i == step else (UITheme.GOLD if i < step else UITheme.SAGE)
		var dsb := UITheme.box(col, 7, Color(0, 0, 0, 0), 0, 0)
		dsb.shadow_size = 0
		d.add_theme_stylebox_override("panel", dsb)


func _quest_distance() -> float:
	var p := GameState.player as Node3D
	var q = Waypoints.quest_target(get_tree())
	if p == null or q == null:
		return -1.0
	return Vector2(p.global_position.x - q.x, p.global_position.z - q.z).length()


func _touch() -> TouchControls:
	return GameState.ui.touch if GameState.ui else null


func _process(delta: float) -> void:
	if not running:
		visible = false
		return
	var p := GameState.player as MnkiController
	var hud_ok: bool = GameState.ui != null and not GameState.ui.hud.force_hidden
	if GameState.top_ui() == "dialogue":
		_seen_dialogue = true
	visible = p != null and hud_ok and not GameState.is_ui_blocking()
	_anim += delta
	if not visible:
		# Opening any menu during the "menus" step counts as done.
		if current_id() == "menus" and GameState.top_ui() in ["inventory", "journal", "map", "together"]:
			_t = 999.0
		return
	_t += delta
	_layout()
	_next.visible = _t > (4.0 if current_id() in ["waypoint", "menus", "swan"] else 7.0)
	var done := false
	match current_id():
		"move":
			done = p.global_position.distance_to(_start_pos) > 4.0
		"look":
			done = absf(angle_difference(_start_look, p.rig.yaw_radians())) > deg_to_rad(50.0)
		"waypoint":
			var d := _quest_distance()
			done = _t > 9.0 or (_start_dist > 0.0 and d >= 0.0 and _start_dist - d > 6.0)
		"interact":
			done = _seen_dialogue or p.state == "fishing"
		"menus":
			done = _t >= 999.0
		"swan":
			done = p.character_id != _start_char or p.flight_mode != "grounded"
	if done and _t > 0.6:
		_advance()
	queue_redraw()


func _layout() -> void:
	var vs := get_viewport_rect().size
	var ins := MobileUI.safe_insets(get_viewport())
	var hs := MobileUI.hud_scale()
	_card.scale = Vector2.ONE * hs
	_card.reset_size()
	var w := _card.size.x * hs
	var y := ins.y + 20.0 + 150.0 * hs + 70.0
	_card.position = Vector2(clampf(vs.x * 0.5 - w * 0.5, ins.x + 20.0, vs.x - ins.z - 20.0 - w), y)


## Pulsing highlight around whatever the current step talks about.
func _draw() -> void:
	if not visible:
		return
	var touch := MobileUI.touch_enabled()
	var tc := _touch()
	var pulse := 0.5 + 0.5 * sin(_anim * 4.0)
	var col := Color(UITheme.GOLD, 0.55 + pulse * 0.4)
	var vs := get_viewport_rect().size
	match String(STEPS[step].focus) if step >= 0 and step < STEPS.size() else "":
		"stick":
			if touch and tc:
				_ring(tc.stick_center, tc.stick_radius + 14.0 + pulse * 10.0, col)
				# ghost thumb sliding up and to the right
				var g := tc.stick_center + Vector2(sin(_anim * 1.6), -absf(cos(_anim * 1.6))) * tc.stick_radius * 0.6
				draw_circle(g, 26.0 * tc.k, Color(1, 1, 1, 0.45))
		"look":
			if touch:
				var a := Vector2(vs.x * 0.62, vs.y * 0.5)
				var t := fmod(_anim * 0.7, 1.0)
				var g := a + Vector2(lerpf(-120.0, 160.0, t), 0)
				draw_circle(g, 30.0, Color(1, 1, 1, 0.5 * (1.0 - t)))
				draw_line(a + Vector2(-120, 0), g, Color(1, 1, 1, 0.3 * (1.0 - t)), 10.0, true)
		"minimap":
			var hud = GameState.ui.hud if GameState.ui else null
			if hud and hud.minimap.visible:
				var r: Rect2 = hud.minimap.get_global_rect()
				_ring(r.get_center(), r.size.x * 0.5 + 10.0 + pulse * 8.0, col)
		"act":
			if touch and tc:
				var b := tc.button("act")
				_ring(b.pos, float(b.r) + 14.0 + pulse * 10.0, col)
		"menus":
			if touch and tc:
				for id in ["together", "journal", "inventory", "map"]:
					var b := tc.button(id)
					_ring(b.pos, float(b.r) + 6.0 + pulse * 6.0, col)
		"swap":
			if touch and tc and tc.button("swap").show:
				var b := tc.button("swap")
				_ring(b.pos, float(b.r) + 12.0 + pulse * 8.0, col)


func _ring(c: Vector2, r: float, col: Color) -> void:
	draw_arc(c, r, 0, TAU, 64, col, 6.0, true)
	draw_arc(c, r + 9.0, 0, TAU, 64, Color(col, col.a * 0.35), 3.0, true)
