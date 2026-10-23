class_name WaypointMarkers
extends Control
## On-screen waypoint pins (HUD): each active waypoint is projected from the 3D world. On screen
## it floats above the goal with its distance; off screen (or behind the camera) it slides to
## the safe edge of the screen and turns into an arrow pointing the way.

var _t := 0.0
var _arrived: Dictionary = {}  # kind -> seconds of "arrived" sparkle left
var _far: Dictionary = {}      # kind -> was outside the arrival radius
var last_positions: Dictionary = {}  # kind -> {pos, on_screen} (read by tests / tutorial)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	for kname in _arrived.keys():
		_arrived[kname] -= delta
		if _arrived[kname] <= 0.0:
			_arrived.erase(kname)
	queue_redraw()


func _draw() -> void:
	last_positions.clear()
	if not bool(Settings.get_value("waypoints")):
		return
	var p := GameState.player as MnkiController
	if p == null or p.rig == null or p.rig.camera == null:
		return
	var cam := p.rig.camera
	var vs := get_viewport_rect().size
	var ins := MobileUI.safe_insets(get_viewport())
	var hs := MobileUI.hud_scale()
	var pad := 70.0 * hs
	var safe := Rect2(Vector2(ins.x + pad, ins.y + pad + 40.0), vs - Vector2(ins.x + ins.z + pad * 2.0, ins.y + ins.w + pad * 2.0 + 40.0))
	var full := safe
	if MobileUI.touch_enabled():
		# Keep edge arrows out of the thumb zones (joystick low-left, buttons low-right).
		safe.size.y = vs.y * 0.56 - safe.position.y
	var font := get_theme_default_font()
	for w in Waypoints.active(get_tree()):
		var kind := String(w.kind)
		var goal: Vector3 = w.pos
		var col: Color = w.color
		var flat := Vector2(goal.x - p.global_position.x, goal.z - p.global_position.z).length()
		if flat < Waypoints.ARRIVE_DIST:
			if _far.get(kind, false):
				_arrived[kind] = 1.2
				MobileUI.vibrate(25)
				if kind == "pin":
					Waypoints.custom_pin = null
					GameState.notify.call_deferred("You reached your pin.", "discovery")
			_far[kind] = false
			continue
		_far[kind] = true
		var anchor := goal + Vector3(0, 2.4, 0)
		var behind := cam.is_position_behind(anchor)
		var sp := cam.unproject_position(anchor)
		var on_screen := not behind and full.has_point(sp)
		var drop := 0.0 if Settings.get_value("reduced_motion") else sin(_t * 3.0) * 5.0
		if on_screen:
			_pin(sp + Vector2(0, drop), col, kind, hs)
			var txt := "%d m" % int(round(flat))
			var fs := int(20 * hs)
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lp := sp + Vector2(-tw * 0.5, 30.0 * hs + drop)
			draw_string_outline(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(7 * hs), Color(UITheme.CREAM, 0.95))
			draw_string(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.FOREST)
		else:
			# Direction on screen from centre toward the goal (flip when behind the camera).
			var c := vs * 0.5
			var d := sp - c
			if behind:
				d = -d
				if d.length() < 1.0:
					d = Vector2(0, 1)
			d = d.normalized()
			var edge := _edge_point(c, d, safe)
			var a := edge
			draw_circle(a, 30.0 * hs, Color(UITheme.CREAM, 0.92))
			draw_arc(a, 30.0 * hs, 0, TAU, 32, col, 4.0 * hs, true)
			var n := Vector2(-d.y, d.x)
			var tip := a + d * 44.0 * hs
			draw_colored_polygon(PackedVector2Array([tip, a + d * 26.0 * hs + n * 15.0 * hs, a + d * 26.0 * hs - n * 15.0 * hs]), col)
			_glyph(a, col, kind, 17.0 * hs)
			var txt := "%d m" % int(round(flat))
			var fs := int(17 * hs)
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lp := a + Vector2(-tw * 0.5, -36.0 * hs) if d.y > 0.5 else a + Vector2(-tw * 0.5, 52.0 * hs)
			draw_string_outline(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(6 * hs), Color(UITheme.CREAM, 0.95))
			draw_string(font, lp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.FOREST)
			sp = a
		last_positions[kind] = {"pos": sp, "on_screen": on_screen, "distance": flat}
	for kind in _arrived:
		var a := float(_arrived[kind])
		var c := vs * 0.5 + Vector2(0, -vs.y * 0.18)
		var col := Waypoints.QUEST_COLOR if kind == "quest" else Waypoints.PIN_COLOR
		draw_arc(c, 40.0 + (1.2 - a) * 60.0, 0, TAU, 40, Color(col, a / 1.2), 5.0, true)


func _edge_point(c: Vector2, d: Vector2, r: Rect2) -> Vector2:
	var tx := INF
	var ty := INF
	if absf(d.x) > 0.0001:
		tx = ((r.end.x if d.x > 0 else r.position.x) - c.x) / d.x
	if absf(d.y) > 0.0001:
		ty = ((r.end.y if d.y > 0 else r.position.y) - c.y) / d.y
	return c + d * minf(tx, ty)


func _pin(at: Vector2, col: Color, kind: String, hs: float) -> void:
	var r := 22.0 * hs
	var head := at - Vector2(0, r * 1.25)
	draw_circle(at + Vector2(0, 3), 6.0 * hs, Color(0, 0, 0, 0.18))
	draw_colored_polygon(PackedVector2Array([at, head + Vector2(-r * 0.78, r * 0.62), head + Vector2(r * 0.78, r * 0.62)]), col)
	draw_circle(head, r, col)
	draw_arc(head, r, 0, TAU, 32, Color.WHITE, 3.0 * hs, true)
	_glyph(head, Color.WHITE, kind, r * 0.62)


func _glyph(c: Vector2, col: Color, kind: String, s: float) -> void:
	if kind == "quest":
		# "!" mark
		draw_rect(Rect2(c + Vector2(-s * 0.16, -s * 0.85), Vector2(s * 0.32, s * 1.05)), col if col != Color.WHITE else Color.WHITE)
		draw_circle(c + Vector2(0, s * 0.62), s * 0.2, col)
	else:
		# flag
		draw_line(c + Vector2(-s * 0.45, s * 0.8), c + Vector2(-s * 0.45, -s * 0.85), col, maxf(s * 0.18, 2.0), true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.85), c + Vector2(s * 0.75, -s * 0.45), c + Vector2(-s * 0.4, -s * 0.05)]), col)
