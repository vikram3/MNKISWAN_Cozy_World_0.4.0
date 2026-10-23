class_name SwanModel
extends CharModel
## SWAN — canon-locked 3D build (MNKISWAN_CHARACTER_CANON.md §2 / CHARACTER_LOCK.json "swan").
## MUST KEEP checklist, all implemented below:
##  [x] very long, thick, wavy chestnut-to-dark-brown hair with bangs (reaches skirt level)
##  [x] small GOLD CROWN, separate from the hood, perched at the upper side
##  [x] white SWAN HOOD with bright ORANGE BEAK on top and dark swan-eye marks
##  [x] big brown eyes and rosy cheeks, matching chibi proportions
##  [x] cozy white hoodie with drawstrings ending in round fluffy POM-POMS
##  [x] short pleated pastel-PINK skirt
##  [x] small white FEATHER WINGS behind the shoulders (never removed)
##  [x] white socks and thick-soled BLUE-AND-WHITE lace-up sneakers
## DON'T (canon §5): no long swan neck, beak never on her face, crown is not Mnki's, hair never short.

const SKIN := Color("f6d4bd")
const HAIR := Color("5e3420")
const HAIR_DARK := Color("4a2818")
const HOOD := Color("fbfaf6")
const BEAK := Color("f2861f")
const GOLD := Color("eab53b")
const HOODIE := Color("f8f5ef")
const SKIRT := Color("f29bb3")
const SKIRT_DARK := Color("de7f9b")
const SOCK := Color("fbfbf8")
const SHOE_BLUE := Color("3d7fd1")
const WHITE := Color("f7f3ea")
const WING := Color("ffffff")
const EYE_IRIS := Color("7a4a2a")
const BLUSH := Color(0.97, 0.56, 0.6, 0.85)

var _locks: Array = []
var flight_blend := 0.0
var flight_lift := 0.0
var flight_bank := 0.0
var _wing_spread := 0.0


func _ready() -> void:
	build()


func build() -> void:
	var ol := SKIN_LINE
	hips = CharParts.pivot(body, Vector3(0, 0.43, 0), "Hips")
	torso = CharParts.pivot(body, Vector3(0, 0.43, 0), "Torso")

	# --- Legs: white socks + blue/white sneakers ----------------------------------------------
	for side in [1.0, -1.0]:
		var leg := CharParts.pivot(hips, Vector3(0.085 * side, 0, 0), "LegL" if side > 0 else "LegR")
		CharParts.add(leg, CharParts.cyl_mesh(0.058, 0.055, 0.14, 12), CharParts.mat(SKIN, ol), Vector3(0, -0.07, 0))
		CharParts.add(leg, CharParts.cyl_mesh(0.064, 0.066, 0.17, 12), CharParts.mat(SOCK, ol), Vector3(0, -0.22, 0))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 16), CharParts.mat(SHOE_BLUE, ol), Vector3(0, -0.345, 0.035), Vector3.ZERO, Vector3(0.1, 0.075, 0.16))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 16), CharParts.mat(WHITE, ol), Vector3(0, -0.4, 0.04), Vector3.ZERO, Vector3(0.105, 0.035, 0.17))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 14), CharParts.mat(WHITE, ol), Vector3(0, -0.37, 0.14), Vector3.ZERO, Vector3(0.08, 0.05, 0.062))
		if side > 0:
			leg_l = leg
		else:
			leg_r = leg

	# --- Pleated pink skirt (attached to hips so it moves with the walk) ---------------------
	var skirt_material := CharParts.mat(SKIRT).duplicate() as StandardMaterial3D
	skirt_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	CharParts.add(hips, CharacterSculpt.pleated_skirt(), skirt_material)
	CharParts.add(hips, CharParts.torus_mesh(0.16, 0.178, 10, 48), CharParts.mat(SKIRT_DARK), Vector3(0, 0.125, 0))

	# --- Torso: white hoodie with pom-pom drawstrings ----------------------------------------
	CharParts.add(torso, CharParts.sphere_mesh(0.19, 22), CharParts.mat(HOODIE, ol), Vector3(0, 0.18, 0), Vector3.ZERO, Vector3(1.06, 1.0, 0.86))
	CharParts.add(torso, CharParts.cyl_mesh(0.17, 0.18, 0.05, 18), CharParts.mat(Color("eeeae2"), ol), Vector3(0, 0.03, 0))
	for side in [-1.0, 1.0]:
		var dx: float = 0.038 * side
		CharParts.add(torso, CharParts.cyl_mesh(0.006, 0.006, 0.12, 6), CharParts.mat(Color("d9d4ca")), Vector3(dx, 0.26, 0.16), Vector3(-12, 0, 0))
		CharParts.sphere(torso, 0.036, WHITE, Vector3(dx * 1.15, 0.185, 0.175), Vector3(1.0, 0.95, 0.9), 0.008)

	# --- Arms: white sleeves ------------------------------------------------------------------
	for side in [1.0, -1.0]:
		var arm := CharParts.pivot(torso, Vector3(0.19 * side, 0.29, 0), "ArmL" if side > 0 else "ArmR")
		CharParts.add(arm, CharParts.capsule_mesh(0.064, 0.29), CharParts.mat(HOODIE, ol), Vector3(0.015 * side, -0.12, 0))
		CharParts.sphere(arm, 0.054, SKIN, Vector3(0.018 * side, -0.29, 0.005), Vector3(1.0, 1.05, 0.9), ol)
		if side > 0:
			arm_l = arm
		else:
			arm_r = arm

	# --- Wings: small white feather wings behind the shoulders -------------------------------
	for side in [1.0, -1.0]:
		var w := CharParts.pivot(torso, Vector3(0.19 * side, 0.27, -0.29), "WingL" if side > 0 else "WingR")
		w.rotation_degrees = Vector3(0, -32.0 * side, 0)
		var wm := CharParts.mat(WING, 0.01)
		CharParts.sphere(w, 0.07, WING, Vector3(0.05 * side, 0.02, 0), Vector3(1.1, 1.0, 0.6), 0.01)
		for row in 2:
			for i in 9:
				var t := float(i) / 8.0
				var root_pos := Vector3((0.04 + t * 0.32) * side, 0.06 + sin(t * PI) * 0.12, -row * 0.023)
				var tip := root_pos + Vector3((0.22 + t * 0.18) * side, 0.08 - t * 0.24, -0.025)
				if row == 1:
					tip = root_pos.lerp(tip, 0.52) + Vector3(0, 0.04, -0.025)
				var ctrl := [root_pos, root_pos.lerp(tip, 0.4) + Vector3(0, 0.05, -0.02), tip]
				var feather := CharParts.add(w, CharacterSculpt.lock_mesh(ctrl, 0.055 if row == 0 else 0.038, 0.018, true), wm if row == 0 else CharParts.mat(Color("e5edf6")))
				feather.name = "Feather%d_%d" % [row, i]
		if side > 0:
			wing_l = w
		else:
			wing_r = w

	# --- Long wavy chestnut hair (big back mass + cascading locks) ---------------------------
	hair_back = CharParts.pivot(torso, Vector3(0, 0.5, -0.12), "HairBack")
	var hm := CharParts.mat(HAIR, 0.012)
	var hd := CharParts.mat(HAIR_DARK, 0.012)
	CharParts.add(hair_back, CharParts.sphere_mesh(0.5, 20), hm, Vector3(0, -0.12, -0.1), Vector3.ZERO, Vector3(0.62, 0.95, 0.34))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	for i in 16:
		var t := float(i) / 15.0
		var ax := lerpf(-0.28, 0.28, t)
		var zback := -0.04 - (0.1 if absf(ax) < 0.2 else 0.0) - rng.randf_range(0.0, 0.05)
		var ctrl: Array = []
		var flare := signf(ax) * (0.06 + absf(ax) * 0.55)
		var length := 0.67 + rng.randf_range(-0.05, 0.08)
		for k in 8:
			var f := float(k) / 7.0
			var wave := sin(f * TAU * 1.8 + i * 1.3) * 0.065 * f
			ctrl.append(Vector3(ax + flare * f * f + wave, 0.08 - f * length, zback - 0.03 * f + wave * 0.5))
		var end: Vector3 = ctrl[-1]
		var curl_side := 1.0 if i % 2 == 0 else -1.0
		ctrl.append(end + Vector3(curl_side * 0.045, 0.015, 0.012))
		ctrl.append(end + Vector3(curl_side * 0.05, 0.055, 0.018))
		ctrl.append(end + Vector3(curl_side * 0.015, 0.067, 0.018))
		var pts := CharParts.smooth(ctrl, 4)
		var lock := CharParts.add(hair_back, CharacterSculpt.lock_mesh(ctrl, 0.065, 0.045), hm if i % 3 else hd)
		_locks.append(lock)
	# Front side locks framing the face (in front of the shoulders)
	for side in [-1.0, 1.0]:
		var ctrl2: Array = []
		for k in 6:
			var f := float(k) / 5.0
			ctrl2.append(Vector3(side * (0.25 + f * 0.06 + sin(f * 9.0) * 0.02), 0.18 - f * 0.42, 0.06 + f * 0.04))
		ctrl2.append((ctrl2[-1] as Vector3) + Vector3(side * 0.03, 0.025, 0))
		CharParts.add(hair_back, CharacterSculpt.lock_mesh(ctrl2, 0.058, 0.034), hm)

	# --- Head, face, hood ---------------------------------------------------------------------
	head = CharParts.pivot(torso, Vector3(0, 0.37, 0), "Head")
	var hc := CharParts.pivot(head, Vector3(0, 0.27, 0), "HeadCenter")
	var r := 0.29
	CharParts.add(hc, CharParts.sphere_mesh(r, 28), CharParts.mat(SKIN, ol), Vector3.ZERO, Vector3.ZERO, Vector3(1.03, 0.97, 1.0))
	build_face(hc, r, -0.035, 0.11, 0.07, 0.095, EYE_IRIS, BLUSH, -0.155)
	# Hair under the hood: crown volume + bangs
	CharParts.add(hc, CharParts.sphere_mesh(0.3, 20), hm, Vector3(0, 0.05, -0.05), Vector3.ZERO, Vector3(1.08, 1.0, 1.0))
	for i in 7:
		var x := -0.18 + i * 0.06
		var z := surface_z(0.3, x, 0.15)
		var ctrl := [Vector3(x * 0.9, 0.24, z - 0.04), Vector3(x, 0.16, z + 0.025), Vector3(x + 0.015, 0.065 + absf(x) * 0.1, z + 0.03)]
		CharParts.add(hc, CharacterSculpt.lock_mesh(ctrl, 0.05, 0.027), hm)
	# The swan hood (white dome) + face-framing rim
	var hood_m := CharParts.mat(HOOD, 0.013)
	var cloth := hood_m.duplicate() as StandardMaterial3D
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	CharParts.add(hc, CharacterSculpt.hood_shell(), cloth, Vector3(0, 0.075, -0.035))
	var rim := PackedVector3Array()
	for i in 49:
		var a := TAU * float(i) / 48.0
		rim.append(Vector3(sin(a) * 0.285, cos(a) * 0.298 + 0.075, 0.14))
	CharParts.tube(hc, rim, 0.014, 0.014, Color("e9e4df"), 0, 10)
	# Hood flap hanging down the back
	CharParts.add(hc, CharParts.sphere_mesh(0.2, 16), hood_m, Vector3(0, -0.2, -0.26), Vector3(20, 0, 0), Vector3(1.2, 1.1, 0.55))
	# Bright orange beak ON TOP of the hood
	var beak := CharParts.add(hc, CharParts.sphere_mesh(0.5, 18), CharParts.mat(BEAK, 0.01), Vector3(0, 0.36, 0.13), Vector3.ZERO, Vector3.ONE, "Beak")
	beak.basis = Basis.from_euler(Vector3(deg_to_rad(-24), 0, 0)) * Basis.from_scale(Vector3(0.2, 0.075, 0.2))
	# Dark swan-eye marks either side of the beak
	for side in [-1.0, 1.0]:
		var mark := CharParts.add(hc, CharParts.capsule_mesh(0.012, 0.06), CharParts.mat(Color("2b1d18")), Vector3(0.165 * side, 0.3, 0.165))
		mark.rotation = Vector3(deg_to_rad(-30), atan2(0.165 * side, 0.165), deg_to_rad(70.0 * side))
	# Small gold crown at the upper side (character's right), distinct from the beak
	var crown := CharParts.pivot(hc, Vector3(-0.16, 0.39, -0.06), "Crown")
	crown.rotation_degrees = Vector3(-8, 0, 24)
	var gold := CharParts.mat(GOLD, 0.008, 0.1, 0.35)
	CharParts.add(crown, CharParts.cyl_mesh(0.07, 0.066, 0.045, 18), gold)
	for i in 5:
		var a := TAU * float(i) / 5.0
		CharParts.add(crown, CharParts.cyl_mesh(0.0, 0.026, 0.07, 6), gold, Vector3(sin(a) * 0.055, 0.055, cos(a) * 0.055))
		CharParts.sphere(crown, 0.012, GOLD, Vector3(sin(a) * 0.055, 0.093, cos(a) * 0.055), Vector3.ONE, 0.0)
	CharacterSculpt.clothing_details(self, WHITE, SKIN, Color("e0d9d4"))


func _animate_extras(delta: float, s: float) -> void:
	if wing_l:
		_wing_spread = move_toward(_wing_spread, flight_blend, delta * 2.5)
		var flap := sin(_time * 2.4) * deg_to_rad(6.0) + sin(_phase * 2.0) * deg_to_rad(5.0) * s
		if action == "celebrate":
			flap += sin(_time * 14.0) * deg_to_rad(22.0)
		wing_l.rotation.y = lerpf(wing_l.rotation.y, deg_to_rad(-32.0) - flap, 1.0 - exp(-13.389 * delta))
		wing_r.rotation.y = lerpf(wing_r.rotation.y, deg_to_rad(32.0) + flap, 1.0 - exp(-13.389 * delta))
		wing_l.rotation.z = lerpf(wing_l.rotation.z, flap * 0.5, 1.0 - exp(-13.389 * delta))
		wing_r.rotation.z = lerpf(wing_r.rotation.z, -flap * 0.5, 1.0 - exp(-13.389 * delta))
		if _wing_spread > 0.01:
			var beat := sin(_time * (10.0 if flight_lift > 0.2 else 5.5)) * (0.5 if flight_lift > 0.2 else 0.25)
			wing_l.rotation = wing_l.rotation.lerp(Vector3(0.12, -0.1, 0.3 + beat), _wing_spread)
			wing_r.rotation = wing_r.rotation.lerp(Vector3(0.12, 0.1, -0.3 - beat), _wing_spread)
			body.rotation.x = lerpf(body.rotation.x, 0.17 * s, _wing_spread)
			body.rotation.z = lerpf(body.rotation.z, flight_bank, 1.0 - exp(-6.322 * delta))
		wing_l.scale = Vector3(0.78, 0.78, 0.78).lerp(Vector3(2.1, 1.6, 1.3), _wing_spread)
		wing_r.scale = wing_l.scale
		if flight_blend == 0.0:
			body.rotation.z = lerpf(body.rotation.z, 0.0, 1.0 - exp(-9.751 * delta))
	if hair_back:
		hair_back.rotation.x = lerpf(hair_back.rotation.x, deg_to_rad(6.0) * s + sin(_time * 1.3) * deg_to_rad(1.5), 1.0 - exp(-5.003 * delta))
		hair_back.rotation.z = lerpf(hair_back.rotation.z, sin(_phase) * deg_to_rad(2.5) * s, 1.0 - exp(-5.003 * delta))


func _idle_variant() -> void:
	if randf() < 0.5:
		set_expression("happy", 1.2)
	else:
		play_action("think", 1.4)
