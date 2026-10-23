class_name TouchControls
extends Control
## Phone / tablet controls (multi-touch): a floating virtual joystick on the left, swipe-to-look
## and pinch-to-zoom on the right, a thumb-arc of action buttons and a compact menu row.
## Buttons feed the same InputMap actions the keyboard uses, so every gameplay rule (fishing,
## flight, dialogue, rituals) behaves identically. Notch-safe; scales to the physical screen.

signal button_pressed(id: String)

const DEADZONE := 0.12
const SPRINT_AT := 0.9
const MOVE_ACTIONS := ["move_left", "move_right", "move_forward", "move_back"]

var k := 1.0                     # control scale
var insets := Vector4.ZERO
var buttons: Array = []          # Array[Dictionary]
var stick_rest := Vector2.ZERO   # resting centre of the joystick
var stick_center := Vector2.ZERO
var stick_radius := 130.0
var stick_vec := Vector2.ZERO    # -1..1 output
var stick_finger := -1
var look_fingers: Dictionary = {}  # index -> position
var _pinch_dist := 0.0
var _held_actions: Dictionary = {}
var _t := 0.0
var _focus_prompt := ""
var _focus_enabled := false
var _connected_scanner: Object = null
var _menu_y := 0.0
var _swap_tex: Dictionary = {}
var _ripples: Array = []
var _was_active := false
var look_delta_total := 0.0       # tutorial reads how much the player has looked around


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_buttons()
	get_viewport().size_changed.connect(_layout)
	Settings.settings_changed.connect(_layout)
	for id in ["mnki", "swan"]:
		_swap_tex[id] = load("res://assets/characters/portraits/%s_happy.png" % id)
	_layout()


func _build_buttons() -> void:
	buttons.clear()
	for spec in [
		# id, icon, kind (tap | hold | menu), action, base radius, label
		["act", "act", "tap", "interact", 92.0, ""],
		["jump", "jump", "hold", "jump", 62.0, "Jump"],
		["descend", "down", "hold", "descend", 58.0, "Down"],
		["seed", "seed", "tap", "cycle_seed", 50.0, "Seed"],
		["swap", "swap", "tap", "switch_character", 58.0, ""],
		["wings", "wings", "tap", "fly", 58.0, "Fly"],
		["together", "heart", "menu", "together", 36.0, ""],
		["journal", "book", "menu", "journal", 36.0, ""],
		["inventory", "bag", "menu", "inventory", 36.0, ""],
		["map", "map", "menu", "map", 36.0, ""],
		["pause", "pause", "menu", "pause", 34.0, ""],
	]:
		buttons.append({"id": spec[0], "icon": spec[1], "kind": spec[2], "action": spec[3], "base_r": spec[4],
			"r": spec[4], "label": spec[5], "pos": Vector2.ZERO, "show": true, "finger": -1, "press_t": 0.0})


func button(id: String) -> Dictionary:
	for b in buttons:
		if b.id == id:
			return b
	return {}


## Recompute every position from the current canvas size, notch insets and scale.
func _layout() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	k = MobileUI.control_scale(vp)
	insets = MobileUI.safe_insets(vp)
	var s := vp.get_visible_rect().size
	var m := 28.0 * k
	var left := insets.x + m
	var right := s.x - insets.z - m
	var top := insets.y + m * 0.8
	var bottom := s.y - insets.w - m
	for b in buttons:
		b.r = float(b.base_r) * k
	stick_radius = 132.0 * k
	stick_rest = Vector2(left + stick_radius + 40.0 * k, bottom - stick_radius - 26.0 * k)
	if stick_finger < 0:
		stick_center = stick_rest
	# Thumb arc around the main action button.
	var act := button("act")
	act.pos = Vector2(right - act.r - 34.0 * k, bottom - act.r - 30.0 * k)
	var arc := 196.0 * k
	_place("jump", act.pos, 180.0, arc)
	_place("descend", act.pos, 218.0, arc + 6.0 * k)
	_place("seed", act.pos, 218.0, arc + 6.0 * k)
	_place("swap", act.pos, 254.0, arc)
	_place("wings", act.pos, 290.0, arc)
	# Top-left pause; menu row sits under the minimap (top-right), see HUD.minimap_rect().
	var pause := button("pause")
	pause.pos = Vector2(left + pause.r, top + pause.r)
	var mm := minimap_rect()
	var row := ["together", "journal", "inventory", "map"]
	var r := float(button("map").r)
	var gap := 14.0 * k
	var total := row.size() * r * 2.0 + (row.size() - 1) * gap
	var x0 := mm.end.x - total + r  # right-aligned under the minimap, never into the notch
	_menu_y = mm.end.y + 18.0 * k + r
	for i in row.size():
		button(row[i]).pos = Vector2(x0 + i * (r * 2.0 + gap), _menu_y)
	queue_redraw()


func _place(id: String, center: Vector2, deg: float, dist: float) -> void:
	var a := deg_to_rad(deg)
	button(id).pos = center + Vector2(cos(a), sin(a)) * dist


## Where the HUD should draw the minimap so the menu row lines up under it (canvas units).
func minimap_rect() -> Rect2:
	return TouchControls.minimap_rect_for(get_viewport())


static func minimap_rect_for(vp: Viewport) -> Rect2:
	if vp == null:
		return Rect2(0, 0, 260, 260)
	var touch := MobileUI.touch_enabled()
	var k := MobileUI.control_scale(vp) if touch else 1.0
	var ins := MobileUI.safe_insets(vp)
	var s := vp.get_visible_rect().size
	var d := (250.0 * k) if touch else 250.0
	var m := 28.0 * k
	return Rect2(Vector2(s.x - ins.z - m - d, ins.y + m * 0.8), Vector2(d, d))


func active() -> bool:
	return MobileUI.touch_enabled() and GameState.in_world and not GameState.is_ui_blocking() \
		and GameState.player != null and not (GameState.ui != null and GameState.ui.hud.force_hidden)


# --- Input -------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	var was := MobileUI.touch_enabled()
	MobileUI.note_event(event)
	if was != MobileUI.touch_enabled():
		_layout()
	if not active():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_down(event.index, event.position):
				get_viewport().set_input_as_handled()
		else:
			touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		if touch_move(event.index, event.position, event.relative):
			get_viewport().set_input_as_handled()


func _passthrough(pos: Vector2) -> bool:
	for n in get_tree().get_nodes_in_group("touch_passthrough"):
		var c := n as Control
		if c and c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


## Returns true when the touch was claimed by the touch layer.
func touch_down(index: int, pos: Vector2) -> bool:
	for b in buttons:
		if b.show and b.finger < 0 and pos.distance_to(b.pos) <= float(b.r) + 14.0 * k:
			b.finger = index
			b.press_t = 1.0
			_ripples.append({"pos": b.pos, "r": float(b.r), "t": 0.0})
			MobileUI.vibrate(10 if b.kind == "menu" else 14)
			if b.kind == "hold" or b.kind == "tap":
				_send_action(String(b.action), true)
			button_pressed.emit(String(b.id))
			queue_redraw()
			return true
	if _passthrough(pos):
		return false
	var s := get_viewport().get_visible_rect().size
	var in_stick_zone := pos.x < s.x * 0.45 and pos.y > s.y * 0.34
	if in_stick_zone and stick_finger < 0:
		stick_finger = index
		# Floating stick: spawn under the thumb, kept fully on screen.
		stick_center = Vector2(clampf(pos.x, insets.x + stick_radius * 0.8, s.x * 0.45), clampf(pos.y, s.y * 0.34 + stick_radius * 0.5, s.y - insets.w - stick_radius * 0.8))
		_update_stick(pos)
		return true
	look_fingers[index] = pos
	if look_fingers.size() == 2:
		var v: Array = look_fingers.values()
		_pinch_dist = (v[0] as Vector2).distance_to(v[1])
	return true


func touch_move(index: int, pos: Vector2, relative: Vector2) -> bool:
	if index == stick_finger:
		_update_stick(pos)
		return true
	if look_fingers.has(index):
		look_fingers[index] = pos
		var rig := _rig()
		if look_fingers.size() >= 2:
			var v: Array = look_fingers.values()
			var dist := (v[0] as Vector2).distance_to(v[1])
			if rig and _pinch_dist > 0.0:
				rig.touch_zoom((_pinch_dist - dist) * 0.018)
			_pinch_dist = dist
		elif rig:
			var sens := 0.2 * float(Settings.get_value("touch_look_sensitivity"))
			rig.touch_look(relative * sens)
			look_delta_total += absf(relative.x * sens)
		return true
	for b in buttons:
		if b.finger == index:
			return true  # a finger that slid off a button keeps it until lifted (forgiving)
	return false


func touch_up(index: int, pos: Vector2) -> void:
	if index == stick_finger:
		stick_finger = -1
		stick_vec = Vector2.ZERO
		_apply_stick()
	look_fingers.erase(index)
	if look_fingers.size() < 2:
		_pinch_dist = 0.0
	for b in buttons:
		if b.finger != index:
			continue
		b.finger = -1
		if b.kind == "hold" or b.kind == "tap":
			_send_action(String(b.action), false)
		elif b.kind == "menu" and pos.distance_to(b.pos) <= float(b.r) * 1.8:
			_open_menu(String(b.action))
	queue_redraw()


func _update_stick(pos: Vector2) -> void:
	var v := (pos - stick_center) / stick_radius
	if v.length() > 1.0:
		# Drag-follow: pulling far past the rim slides the stick along, like most phone games.
		var over := (pos - stick_center).length() - stick_radius * 1.25
		if over > 0.0:
			stick_center += (pos - stick_center).normalized() * over
		v = v.normalized()
	var l := v.length()
	stick_vec = Vector2.ZERO if l < DEADZONE else v.normalized() * ((l - DEADZONE) / (1.0 - DEADZONE))
	_apply_stick()


func _apply_stick() -> void:
	# Input.get_vector() applies the actions' own 0.2 deadzone again; pre-compensate so the
	# hero's speed follows the thumb exactly (half push = half speed).
	var out := stick_vec
	var l := stick_vec.length()
	if l > 0.0:
		var dz := InputMap.action_get_deadzone("move_forward")
		out = stick_vec / l * minf(dz + (1.0 - dz) * l, 1.0)
	var strengths := {
		"move_right": maxf(out.x, 0.0), "move_left": maxf(-out.x, 0.0),
		"move_back": maxf(out.y, 0.0), "move_forward": maxf(-out.y, 0.0)}
	for a in strengths:
		var v: float = strengths[a]
		if v > 0.01:
			Input.action_press(a, v)
		elif Input.is_action_pressed(a) and not _key_held(a):
			Input.action_release(a)
	var sprint := bool(Settings.get_value("stick_sprint")) and stick_vec.length() >= SPRINT_AT
	var p := GameState.player as MnkiController
	if Settings.get_value("run_toggle") and p:
		p._run_toggled = sprint
	elif sprint:
		Input.action_press("run")
		_held_actions["run"] = true
	elif _held_actions.has("run"):
		_held_actions.erase("run")
		Input.action_release("run")


func _key_held(action: String) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and Input.is_physical_key_pressed((ev as InputEventKey).physical_keycode):
			return true
	return false


func _send_action(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	# Deferred: never re-enter input dispatch from inside the touch handler.
	Input.parse_input_event.call_deferred(ev)
	if pressed:
		_held_actions[action] = true
	else:
		_held_actions.erase(action)


func _open_menu(which: String) -> void:
	var ui = GameState.ui
	if ui == null:
		return
	AudioManager.play_sfx("ui")
	match which:
		"pause": ui.pause.open()
		"together": ui._toggle(ui.together)
		"journal": ui._toggle(ui.journal)
		"inventory": ui._toggle(ui.inventory)
		"map": ui._toggle(ui.map)


func release_all() -> void:
	stick_finger = -1
	stick_vec = Vector2.ZERO
	stick_center = stick_rest
	look_fingers.clear()
	_pinch_dist = 0.0
	for a in MOVE_ACTIONS:
		if not _key_held(a):
			Input.action_release(a)
	for a in _held_actions.keys():
		Input.action_release(a)
	_held_actions.clear()
	for b in buttons:
		b.finger = -1


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all()


func _rig() -> CameraRig:
	var p := GameState.player as MnkiController
	return p.rig if p else null


# --- Per-frame state ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	var on := active()
	visible = on
	if not on:
		if _was_active:
			release_all()
		_was_active = false
		return
	if not _was_active:
		_layout()
	_was_active = true
	_t += delta
	var p := GameState.player as MnkiController
	if p and p.scanner and _connected_scanner != p.scanner:
		_connected_scanner = p.scanner
		p.scanner.focus_changed.connect(func(target, prompt: String, enabled: bool):
			_focus_prompt = prompt if target != null else ""
			_focus_enabled = enabled)
	var flying := p != null and p.flight_mode != "grounded"
	var swan := p != null and p.character_id == "swan"
	button("jump").icon = "rise" if flying else "jump"
	button("jump").label = "Rise" if flying else "Jump"
	button("descend").show = flying
	button("seed").show = not flying and GameState.get_selected_seed() != ""
	button("wings").show = swan
	button("wings").label = ("Land" if p.flight_mode == "flying" else "Hover") if flying else "Fly"
	button("swap").show = not flying
	if stick_finger < 0:
		stick_center = stick_center.lerp(stick_rest, 1.0 - exp(-14.0 * delta))
	for b in buttons:
		b.press_t = maxf(0.0, float(b.press_t) - delta * 5.0)
		if not b.show and b.finger >= 0:
			if b.kind != "menu":
				_send_action(String(b.action), false)
			b.finger = -1
	for rp in _ripples:
		rp.t += delta * 2.6
	_ripples = _ripples.filter(func(rp): return rp.t < 1.0)
	queue_redraw()


func act_label() -> String:
	var p := GameState.player as MnkiController
	if p and p.state == "fishing":
		return "Reel!" if p.fishing_spot and p.fishing_spot.state == "bite" else "Wait..."
	if _focus_prompt == "":
		return ""
	var words := _focus_prompt.split(" ", false)
	return words[0] if words.size() > 0 else ""


# --- Drawing -----------------------------------------------------------------------------------

func _draw() -> void:
	var op := float(Settings.get_value("touch_opacity"))
	var forest := Color(UITheme.FOREST, 0.42 * op)
	var cream := Color(UITheme.CREAM, 0.92 * op)
	# Joystick
	var engaged := stick_finger >= 0
	var ring_a := (0.95 if engaged else 0.55) * op
	var sc := stick_center
	draw_circle(sc, stick_radius, Color(UITheme.FOREST, 0.28 * ring_a))
	draw_arc(sc, stick_radius, 0, TAU, 64, Color(UITheme.CREAM, 0.75 * ring_a), 4.0 * k, true)
	draw_arc(sc, stick_radius * 0.62, 0, TAU, 48, Color(UITheme.CREAM, 0.18 * ring_a), 2.0 * k, true)
	for i in 4:
		var a := i * PI / 2.0
		var d := Vector2(cos(a), sin(a))
		var lit := stick_vec.dot(d) > 0.4
		var tip := sc + d * stick_radius * 0.84
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([tip + d * 10.0 * k, tip + n * 11.0 * k, tip - n * 11.0 * k]), Color(UITheme.GOLD if lit else UITheme.CREAM, (0.95 if lit else 0.5) * ring_a))
	var sprinting := engaged and stick_vec.length() >= SPRINT_AT and bool(Settings.get_value("stick_sprint"))
	if sprinting:
		draw_arc(sc, stick_radius + 7.0 * k, 0, TAU, 64, Color(UITheme.GOLD, 0.9 * op), 6.0 * k, true)
	var knob := sc + stick_vec * stick_radius * 0.72 + (stick_vec.normalized() * stick_radius * 0.08 * DEADZONE if stick_vec != Vector2.ZERO else Vector2.ZERO)
	var kr := 58.0 * k
	draw_circle(knob + Vector2(0, 5.0 * k), kr, Color(0, 0, 0, 0.16 * ring_a))
	draw_circle(knob, kr, Color(UITheme.CREAM, 0.9 * ring_a))
	draw_circle(knob - Vector2(kr * 0.22, kr * 0.25), kr * 0.55, Color(1, 1, 1, 0.35 * ring_a))
	draw_arc(knob, kr, 0, TAU, 40, Color(UITheme.GOLD if sprinting else UITheme.SAGE, ring_a), 4.0 * k, true)
	if sprinting:
		TouchIcons.draw(self, "run", knob, kr * 0.5, Color(UITheme.FOREST, 0.85))
	# Ripples
	for rp in _ripples:
		draw_arc(rp.pos, float(rp.r) * (1.0 + float(rp.t) * 0.45), 0, TAU, 40, Color(UITheme.CREAM, (1.0 - float(rp.t)) * 0.7 * op), 4.0 * k, true)
	# Buttons
	var font := get_theme_default_font()
	for b in buttons:
		if not b.show:
			continue
		var r := float(b.r) * (1.0 - float(b.press_t) * 0.08)
		var held: bool = b.finger >= 0
		var fill := forest
		var icon_col := cream
		var border := Color(UITheme.CREAM, 0.7 * op)
		match String(b.id):
			"act":
				var ready := _focus_prompt != "" and _focus_enabled
				var p := GameState.player as MnkiController
				var bite := p != null and p.state == "fishing" and p.fishing_spot != null and p.fishing_spot.state == "bite"
				if ready or bite:
					var pulse := 0.5 + 0.5 * sin(_t * (9.0 if bite else 4.0))
					draw_circle(b.pos, r + (10.0 + pulse * 8.0) * k, Color(UITheme.CORAL if bite else UITheme.GOLD, 0.28 * op))
					fill = Color(UITheme.CORAL, 0.92 * op)
					border = Color(UITheme.CREAM, op)
				else:
					fill = Color(UITheme.FOREST, 0.5 * op)
			"wings":
				fill = Color(UITheme.GOLD.darkened(0.15), 0.78 * op)
			"swap":
				fill = Color(UITheme.CREAM, 0.88 * op)
		if held:
			fill = fill.lightened(0.18)
		draw_circle(b.pos + Vector2(0, 4.0 * k), r, Color(0, 0, 0, 0.14 * op))
		draw_circle(b.pos, r, fill)
		draw_arc(b.pos, r, 0, TAU, 48, border, (3.0 if b.kind == "menu" else 4.0) * k, true)
		if b.id == "swap":
			_draw_swap(b.pos, r)
			continue
		var icon_r := r * (0.42 if b.id == "act" else 0.5)
		var icon_c: Vector2 = b.pos - (Vector2(0, r * 0.14) if b.id == "act" and act_label() != "" else Vector2.ZERO)
		TouchIcons.draw(self, String(b.icon), icon_c, icon_r, icon_col)
		var text := act_label() if b.id == "act" else String(b.label)
		if text != "" and b.kind != "menu":
			var fs := int((22.0 if b.id == "act" else 17.0) * k)
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
			var ty: float = b.pos.y + r * (0.62 if b.id == "act" else 0.0) + fs * 0.35
			if b.id != "act":
				ty = b.pos.y + r + fs + 4.0 * k
				draw_string_outline(font, Vector2(b.pos.x - tw * 0.5, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(6 * k), Color(UITheme.FOREST, 0.7 * op))
			draw_string(font, Vector2(b.pos.x - tw * 0.5, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cream)
	# Flight altitude pill next to the wings
	var pl := GameState.player as MnkiController
	if pl and pl.flight_mode != "grounded":
		var w := button("wings")
		var txt := "%.0f m" % pl.global_position.y
		var fs := int(20 * k)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at: Vector2 = w.pos - Vector2(tw * 0.5, float(w.r) + 18.0 * k)
		draw_rect(Rect2(at - Vector2(10, fs) * k * Vector2(1, 0.95), Vector2(tw + 20.0 * k, fs * 1.4)), Color(UITheme.FOREST, 0.6 * op))
		draw_string(font, at + Vector2(0, fs * 0.1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cream)


func _draw_swap(c: Vector2, r: float) -> void:
	var p := GameState.player as MnkiController
	var other := "swan" if p == null or p.character_id == "mnki" else "mnki"
	var tex: Texture2D = _swap_tex.get(other)
	if tex:
		# Head-and-shoulders crop of the friend you will switch to.
		var ts := tex.get_size()
		var src := Rect2(ts.x * 0.18, ts.y * 0.02, ts.x * 0.64, ts.x * 0.64)
		var d := r * 1.5
		draw_texture_rect_region(tex, Rect2(c - Vector2(d, d) * 0.5 + Vector2(0, -r * 0.06), Vector2(d, d)), src)
	var badge := c + Vector2(r * 0.68, r * 0.68)
	draw_circle(badge, r * 0.36, Color(UITheme.FOREST, 0.92))
	TouchIcons.draw(self, "swap", badge, r * 0.3, UITheme.CREAM)
