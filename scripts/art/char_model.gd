class_name CharModel
extends Node3D
## Base for procedurally built chibi characters. Provides the shared rig (pivots at hips,
## shoulders, neck, tail/wing roots — matching the canon's "stable pivots" rule), a face kit
## (eyes, blink, happy-eyes, mouths, blush) and procedural animation:
## idle breathing, walk/run, jump, gather, pet/feed, fish, celebrate, wave, think.
## Models face +Z. Feet rest at y = 0.

const SKIN_LINE := 0.012

var body: Node3D          # bobbing root
var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var tail: Node3D = null
var wing_l: Node3D = null
var wing_r: Node3D = null
var hair_back: Node3D = null

var eyes_open: Array = []
var eyes_happy: Array = []
var eye_wink_target: Node3D = null
var mouth_smile: Node3D
var mouth_open: Node3D
var mouth_o: Node3D

var _target_speed := 0.0
var _opacity := 1.0
var _geometry: Array[GeometryInstance3D] = []
var speed_norm := 0.0
var grounded := true
var action := ""
var action_t := 0.0
var action_dur := 0.0
var expression := "neutral"
var _expr_timer := 0.0
var _blink_t := 2.0
var _phase := 0.0
var _time := 0.0
var _idle_variant_t := 6.0
var head_look := Vector2.ZERO   # yaw/pitch offsets (radians) for look-at


func _init() -> void:
	body = CharParts.pivot(self, Vector3.ZERO, "Body")


# --- Face kit -----------------------------------------------------------------------------------

## z on a sphere surface of radius r at (x, y) relative to its centre.
static func surface_z(r: float, x: float, y: float) -> float:
	return sqrt(max(r * r - x * x - y * y, 0.0))


func build_face(h: Node3D, r: float, eye_y: float, eye_dx: float, eye_w: float, eye_h: float, iris: Color, blush: Color, mouth_y: float) -> void:
	for side in [-1.0, 1.0]:
		var x: float = eye_dx * side
		var z := surface_z(r, x, eye_y) + 0.003
		var eye := CharParts.pivot(h, Vector3(x, eye_y, z))
		eye.rotation.y = atan2(x, z) * 0.8
		var dark := Color("2b1408")
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 24), CharParts.mat(dark), Vector3.ZERO, Vector3.ZERO, Vector3(eye_w, eye_h, 0.012))
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 24), CharParts.mat(Color("fff3dd")), Vector3(0, -0.004, 0.008), Vector3.ZERO, Vector3(eye_w * 0.92, eye_h * 0.90, 0.010))
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 24), CharParts.mat(iris, 0, 0, 0.3), Vector3(-side * 0.006, -0.005, 0.016), Vector3.ZERO, Vector3(eye_w * 0.73, eye_h * 0.86, 0.008))
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 20), CharParts.mat(Color("2c1716"), 0, 0, 0.2), Vector3(-side * 0.006, 0.009, 0.022), Vector3.ZERO, Vector3(eye_w * 0.40, eye_h * 0.59, 0.004))
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 12), CharParts.unshaded(Color.WHITE), Vector3(eye_w * 0.26, eye_h * 0.38, 0.026), Vector3.ZERO, Vector3(eye_w * 0.24, eye_h * 0.22, 0.003))
		CharParts.add(eye, CharParts.sphere_mesh(1.0, 10), CharParts.unshaded(Color("fff4d2")), Vector3(-eye_w * 0.25, -eye_h * 0.4, 0.024), Vector3.ZERO, Vector3(eye_w * 0.12, eye_h * 0.1, 0.003))
		eyes_open.append(eye)
		# Happy closed eyes: ^ ^ arcs (sticker style)
		var arc_pts := PackedVector3Array()
		for i in 9:
			var a := PI * float(i) / 8.0
			arc_pts.append(Vector3(cos(a) * eye_w * 1.05, sin(a) * eye_h * 0.55 - eye_h * 0.15, 0.0))
		var happy := CharParts.pivot(h, Vector3(x, eye_y, z + 0.012))
		happy.rotation.y = eye.rotation.y
		CharParts.add(happy, CharParts.tube_mesh(arc_pts, 0.016, 0.016, 6), CharParts.mat(dark))
		happy.visible = false
		eyes_happy.append(happy)
		# Blush
		var bx: float = (eye_dx + eye_w * 0.6) * side
		var by := eye_y - eye_h * 1.25
		var bz := surface_z(r, bx, by) - 0.012
		var bl := CharParts.add(h, CharParts.sphere_mesh(1.0, 12), CharParts.unshaded(blush), Vector3(bx, by, bz), Vector3(0, rad_to_deg(atan2(bx, bz)), 0), Vector3(0.055, 0.03, 0.012))
		bl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eye_wink_target = eyes_open[0]
	# Small sculpted nose and eyebrows keep the face readable in three-quarter view.
	CharParts.sphere(h, 0.019, Color("edb495"), Vector3(0, -0.09, surface_z(r, 0, -0.09)), Vector3(0.8, 0.7, 0.8), 0.0)
	for side in [-1.0, 1.0]:
		var brow := PackedVector3Array()
		for i in 9:
			var t := float(i) / 8.0
			var x: float = side * (eye_dx - eye_w * 0.85 + t * eye_w * 1.6)
			var y := eye_y + eye_h * 1.25 + sin(t * PI) * 0.014
			brow.append(Vector3(x, y, surface_z(r, x, y) + 0.006))
		CharParts.tube(h, brow, 0.009, 0.005, Color("623727"), 0)
	# Mouths
	var mz := surface_z(r, 0.0, mouth_y) - 0.008
	mouth_smile = CharParts.pivot(h, Vector3(0, mouth_y, mz))
	var sm := PackedVector3Array()
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		sm.append(Vector3(cos(a) * 0.04, sin(a) * 0.022, 0.0))
	CharParts.add(mouth_smile, CharParts.tube_mesh(sm, 0.008, 0.008, 6), CharParts.mat(Color("6b2a1e")))
	mouth_open = CharParts.pivot(h, Vector3(0, mouth_y - 0.008, mz - 0.004))
	CharParts.add(mouth_open, CharParts.sphere_mesh(1.0, 14), CharParts.mat(Color("8f2b25")), Vector3.ZERO, Vector3.ZERO, Vector3(0.05, 0.038, 0.02))
	CharParts.add(mouth_open, CharParts.sphere_mesh(1.0, 12), CharParts.mat(Color("f08f8f")), Vector3(0, -0.016, 0.008), Vector3.ZERO, Vector3(0.03, 0.014, 0.012))
	CharParts.add(mouth_open, CharParts.box_mesh(Vector3(0.06, 0.012, 0.01)), CharParts.unshaded(Color.WHITE), Vector3(0, 0.022, 0.012))
	mouth_o = CharParts.pivot(h, Vector3(0, mouth_y - 0.01, mz))
	CharParts.add(mouth_o, CharParts.sphere_mesh(1.0, 12), CharParts.mat(Color("8f2b25")), Vector3.ZERO, Vector3.ZERO, Vector3(0.022, 0.026, 0.015))
	set_expression("neutral")


func set_expression(e: String, hold: float = 0.0) -> void:
	expression = e
	_expr_timer = hold
	var happy := e == "happy"
	for n in eyes_open:
		var en: Node3D = n
		en.visible = not happy
		en.scale = Vector3.ONE
	for n in eyes_happy:
		var eh: Node3D = n
		eh.visible = happy
	if e == "wink" and eyes_happy.size() == 2:
		eyes_open[0].visible = false
		eyes_happy[0].visible = true
	if mouth_smile:
		mouth_smile.visible = e in ["neutral", "thinking"]
		mouth_open.visible = e in ["happy", "wink", "excited"]
		mouth_o.visible = e == "surprised"


# --- Animation API ------------------------------------------------------------------------------

func set_locomotion(speed: float, run_speed: float, is_grounded: bool) -> void:
	_target_speed = clampf(speed / max(run_speed, 0.01), 0.0, 1.2)
	grounded = is_grounded


## dur < 0 loops until clear_action().
func play_action(a: String, dur: float = 0.7) -> void:
	action = a
	action_t = 0.0
	action_dur = dur
	match a:
		"celebrate", "wave":
			set_expression("happy", max(dur, 1.0))
		"gather", "pet", "feed", "brush", "shop", "harvest", "plant", "water":
			set_expression("happy" if a in ["pet", "harvest"] else "neutral", dur + 0.4)
		"think":
			set_expression("thinking", dur)
		"surprised":
			set_expression("surprised", dur)


func clear_action() -> void:
	action = ""
	action_t = 0.0


func is_busy() -> bool:
	return action != "" and action_dur > 0.0 and action not in ["wave", "celebrate", "think"]


func set_opacity(alpha: float) -> void:
	if is_equal_approx(alpha, _opacity): return
	_opacity = alpha
	if _geometry.is_empty():
		for child in find_children("*", "GeometryInstance3D", true, false):
			_geometry.append(child)
	for mesh in _geometry: mesh.transparency = 1.0 - alpha

func _process(delta: float) -> void:
	speed_norm = lerpf(speed_norm, _target_speed, 1.0 - exp(-10.0 * delta))
	_time += delta
	_animate(delta)
	_update_face(delta)


func _update_face(delta: float) -> void:
	if _expr_timer > 0.0:
		_expr_timer -= delta
		if _expr_timer <= 0.0:
			set_expression("neutral")
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = randf_range(2.2, 5.0)
	var blink := 1.0
	if _blink_t < 0.12:
		blink = 0.12
	if expression != "happy":
		for e in eyes_open:
			var en: Node3D = e
			en.scale.y = lerpf(en.scale.y, blink, 1.0 - exp(-54.977 * delta))


func _animate(delta: float) -> void:
	var s := speed_norm
	var swing := 0.0
	if s > 0.05 and grounded:
		_phase += delta * (5.5 + 6.5 * s)
		swing = sin(_phase)
	else:
		_phase = lerpf(_phase, round(_phase / PI) * PI, 1.0 - exp(-6.322 * delta))
	var leg_amp := deg_to_rad(10.0 + 28.0 * s)
	var arm_amp := deg_to_rad(8.0 + 30.0 * s)
	var target_body_y := absf(sin(_phase)) * 0.035 * s
	var breathe := sin(_time * 2.2) * 0.012
	var lean := deg_to_rad(4.0 + 8.0 * s) * minf(s * 3.0, 1.0)

	var la := swing * leg_amp
	var ra := -swing * leg_amp
	var arm_lx := -swing * arm_amp
	var arm_rx := swing * arm_amp
	var arm_lz := deg_to_rad(8.0)
	var arm_rz := -deg_to_rad(8.0)
	var crouch := 0.0
	var head_x := 0.0
	var head_y := 0.0
	var head_z := sin(_time * 0.9) * deg_to_rad(2.0)
	var hop := 0.0

	if not grounded:
		la = deg_to_rad(-25.0)
		ra = deg_to_rad(10.0)
		arm_lz = deg_to_rad(45.0)
		arm_rz = -deg_to_rad(45.0)
		arm_lx = 0.0
		arm_rx = 0.0

	if action != "":
		action_t += delta
		var k := 1.0 if action_dur <= 0.0 else clampf(action_t / action_dur, 0.0, 1.0)
		var bell := (0.65 + sin(action_t * 2.5) * 0.35) if action_dur <= 0 else sin(k * PI)
		match action:
			"gather", "harvest":
				arm_rx = -deg_to_rad(120.0) * bell
				arm_lx = -deg_to_rad(80.0) * bell
				head_x = deg_to_rad(-12.0) * bell
				lean += deg_to_rad(10.0) * bell
			"plant", "water":
				crouch = 0.12 * bell
				arm_rx = -deg_to_rad(70.0) * bell
				arm_lx = -deg_to_rad(40.0) * bell
				head_x = deg_to_rad(18.0) * bell
				lean += deg_to_rad(18.0) * bell
			"pet", "feed", "brush":
				crouch = 0.14 * bell
				arm_rx = -deg_to_rad(75.0) * bell + sin(action_t * 14.0) * deg_to_rad(8.0) * bell
				arm_lx = -deg_to_rad(30.0) * bell
				head_x = deg_to_rad(15.0) * bell
				lean += deg_to_rad(12.0) * bell
			"shop":
				arm_rx = -deg_to_rad(70.0) * bell
				arm_lx = -deg_to_rad(70.0) * bell
				lean += deg_to_rad(8.0) * bell
			"celebrate":
				arm_lz = deg_to_rad(150.0) * bell + arm_lz * (1.0 - bell)
				arm_rz = -deg_to_rad(150.0) * bell + arm_rz * (1.0 - bell)
				arm_lx = 0.0
				arm_rx = 0.0
				hop = absf(sin(action_t * 9.0)) * 0.1 * bell
			"wave":
				arm_rz = -deg_to_rad(140.0) * bell
				arm_rx = 0.0
				body.rotation.z = 0.0
				head_z = deg_to_rad(8.0) * bell
				arm_rz += sin(action_t * 12.0) * deg_to_rad(18.0) * bell
			"fish":
				arm_rx = -deg_to_rad(55.0)
				arm_lx = -deg_to_rad(45.0)
				arm_lz = deg_to_rad(-12.0)
				head_x = deg_to_rad(10.0)
			"fish_cast":
				arm_rx = -deg_to_rad(150.0) * (1.0 - k) - deg_to_rad(55.0) * k
				arm_lx = -deg_to_rad(45.0)
			"think":
				arm_rx = -deg_to_rad(100.0) * bell
				arm_rz = deg_to_rad(20.0) * bell
				head_z = deg_to_rad(10.0) * bell
			"sit", "read":
				crouch = 0.2
				la = deg_to_rad(80.0)
				ra = deg_to_rad(80.0)
				if action == "read":
					arm_lx = -0.9; arm_rx = -0.9; head_x = 0.18
			"farm":
				lean = 0.18 + bell * 0.15
				arm_rx = -0.7 - bell * 0.4
				arm_lx = -0.5 - bell * 0.35
				head_x = 0.15
			"eat":
				arm_rx = -0.6 - bell * 0.9
				arm_lx = -0.65
				head_x = bell * 0.08
			"chat", "affection":
				arm_rx = -0.35 - bell * 0.45
				head_z = sin(action_t * 1.4) * 0.07
				arm_lx = -0.4 if action == "affection" else -0.1
			"dance":
				arm_lz = 0.7 + bell * 0.3; arm_rz = -arm_lz
				la = sin(action_t * 3.0) * 0.22; ra = -la
				hop = absf(sin(action_t * 3.0)) * 0.055
			"play_ball":
				arm_lx = -0.6 - bell * 0.6; arm_rx = arm_lx
				head_x = -bell * 0.1
			"breathe":
				arm_lz = 0.2; arm_rz = -0.2
				head_x = -0.08
			"surprised":
				hop = 0.06 * bell
				arm_lz = deg_to_rad(40.0) * bell
				arm_rz = -deg_to_rad(40.0) * bell
		if action_dur > 0.0 and action_t >= action_dur:
			action = ""

	body.position.y = lerpf(body.position.y, target_body_y + hop - crouch, 1.0 - exp(-21.4 * delta))
	body.rotation.x = lerpf(body.rotation.x, lean, 1.0 - exp(-9.751 * delta))
	if torso:
		torso.scale = Vector3(1.0 + breathe * 0.5, 1.0 + breathe, 1.0 + breathe * 0.5)
	if leg_l:
		leg_l.rotation.x = lerpf(leg_l.rotation.x, -la, 1.0 - exp(-25.847 * delta))
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -ra, 1.0 - exp(-25.847 * delta))
	if arm_l:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_lx, 1.0 - exp(-17.261 * delta))
		arm_r.rotation.x = lerpf(arm_r.rotation.x, arm_rx, 1.0 - exp(-17.261 * delta))
		arm_l.rotation.z = lerpf(arm_l.rotation.z, arm_lz, 1.0 - exp(-17.261 * delta))
		arm_r.rotation.z = lerpf(arm_r.rotation.z, arm_rz, 1.0 - exp(-17.261 * delta))
	if head:
		head.rotation.x = lerpf(head.rotation.x, head_x + head_look.y, 1.0 - exp(-9.751 * delta))
		head.rotation.y = lerpf(head.rotation.y, head_y + head_look.x, 1.0 - exp(-7.67 * delta))
		head.rotation.z = lerpf(head.rotation.z, head_z + sin(_phase) * deg_to_rad(3.0) * s, 1.0 - exp(-9.751 * delta))
	_animate_extras(delta, s)
	# Idle variation: occasional wink / tail curl (low amplitude, GDD §5).
	if s < 0.05 and action == "":
		_idle_variant_t -= delta
		if _idle_variant_t <= 0.0:
			_idle_variant_t = randf_range(7.0, 12.0)
			_idle_variant()


func _animate_extras(_delta: float, _s: float) -> void:
	pass


func _idle_variant() -> void:
	set_expression("wink" if randf() < 0.5 else "happy", 1.0)
