class_name MnkiModel
extends CharModel
## MNKI — canon-locked 3D build (MNKISWAN_CHARACTER_CANON.md §1 / CHARACTER_LOCK.json "mnki").
## MUST KEEP checklist, all implemented below:
##  [x] huge fluffy dark-brown tousled hair with bangs & flyaway tufts
##  [x] gold DOUBLE INWARD SPIRAL headband across the forehead
##  [x] big soft brown eyes, warm rosy cheeks, chibi proportions
##  [x] vivid red hoodie with dangling drawstrings + small monkey-face chest emblem
##  [x] loose nearly-black cargo trousers with pockets
##  [x] chunky red-and-white sneakers with white toe caps & broad soles
##  [x] long brown monkey tail with a conspicuous curled tip
## Skin tone follows the official sticker shading (warm tan) pending the owner-approved master
## colour sheet (canon §6) — change SKIN in one place if the approved value differs.

const SKIN := Color("e9b48c")
const SKIN_SHADE := Color("d39a72")
const HAIR := Color("3b2417")
const HAIR_LIGHT := Color("543423")
const GOLD := Color("eab53b")
const HOODIE := Color("d8302b")
const HOODIE_DARK := Color("b5241f")
const PANTS := Color("2a221e")
const PANTS_POCKET := Color("3a2f29")
const SHOE_RED := Color("d7262b")
const WHITE := Color("f7f3ea")
const TAIL := Color("7b4a2b")
const TAIL_TIP := Color("6a3e23")
const EYE_IRIS := Color("7a4320")
const BLUSH := Color(0.96, 0.55, 0.55, 0.85)
const EMBLEM_BROWN := Color("8a5a35")
const EMBLEM_FACE := Color("f0c9a0")

var _tail_base_rot := Vector3.ZERO


func _ready() -> void:
	build()


func build() -> void:
	var ol := SKIN_LINE
	hips = CharParts.pivot(body, Vector3(0, 0.43, 0), "Hips")
	torso = CharParts.pivot(body, Vector3(0, 0.43, 0), "Torso")

	# --- Legs: loose cargo trousers + red/white sneakers ---------------------------------------
	for side in [1.0, -1.0]:
		var leg := CharParts.pivot(hips, Vector3(0.1 * side, 0, 0), "LegL" if side > 0 else "LegR")
		CharParts.add(leg, CharParts.cyl_mesh(0.085, 0.098, 0.31, 14), CharParts.mat(PANTS, ol), Vector3(0, -0.15, 0))
		CharParts.add(leg, CharParts.box_mesh(Vector3(0.035, 0.085, 0.1)), CharParts.mat(PANTS_POCKET, 0.008), Vector3(0.092 * side, -0.12, 0.0))
		CharParts.add(leg, CharParts.box_mesh(Vector3(0.04, 0.02, 0.105)), CharParts.mat(PANTS_POCKET, 0.006), Vector3(0.094 * side, -0.075, 0.0))
		# Sneaker
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 16), CharParts.mat(SHOE_RED, ol), Vector3(0, -0.345, 0.035), Vector3.ZERO, Vector3(0.105, 0.075, 0.165))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 16), CharParts.mat(WHITE, ol), Vector3(0, -0.4, 0.04), Vector3.ZERO, Vector3(0.11, 0.035, 0.175))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 14), CharParts.mat(WHITE, ol), Vector3(0, -0.37, 0.14), Vector3.ZERO, Vector3(0.085, 0.05, 0.065))
		if side > 0:
			leg_l = leg
		else:
			leg_r = leg

	# --- Torso: red hoodie, kangaroo pocket, drawstrings, monkey emblem ------------------------
	CharParts.add(torso, CharParts.sphere_mesh(0.2, 22), CharParts.mat(HOODIE, ol), Vector3(0, 0.17, 0), Vector3.ZERO, Vector3(1.08, 1.0, 0.86))
	CharParts.add(torso, CharParts.cyl_mesh(0.18, 0.19, 0.06, 18), CharParts.mat(HOODIE_DARK, ol), Vector3(0, 0.0, 0))  # waist band
	CharParts.add(torso, CharParts.sphere_mesh(0.15, 16), CharParts.mat(HOODIE_DARK, 0.008), Vector3(0, 0.06, 0.13), Vector3.ZERO, Vector3(0.75, 0.38, 0.32))
	CharParts.add(torso, CharParts.sphere_mesh(0.13, 16), CharParts.mat(HOODIE, ol), Vector3(0, 0.33, -0.11), Vector3.ZERO, Vector3(1.35, 0.75, 0.85))  # bunched hood
	for side in [-1.0, 1.0]:
		var dx: float = 0.04 * side
		CharParts.add(torso, CharParts.cyl_mesh(0.007, 0.007, 0.13, 6), CharParts.mat(Color("3a2a22")), Vector3(dx, 0.27, 0.165), Vector3(-12, 0, 0))
		CharParts.sphere(torso, 0.014, Color("3a2a22"), Vector3(dx, 0.2, 0.18), Vector3.ONE, 0.0)
	var emb := CharParts.pivot(torso, Vector3(0, 0.17, 0.18), "MonkeyEmblem")
	emb.scale = Vector3.ONE * 1.35
	CharParts.add(emb, CharParts.sphere_mesh(1.0, 14), CharParts.mat(EMBLEM_BROWN, 0.004), Vector3.ZERO, Vector3.ZERO, Vector3(0.042, 0.04, 0.014))
	for ex in [-0.042, 0.042]:
		CharParts.add(emb, CharParts.sphere_mesh(1.0, 10), CharParts.mat(EMBLEM_BROWN, 0.004), Vector3(ex, 0.006, -0.002), Vector3.ZERO, Vector3(0.016, 0.016, 0.01))
		CharParts.add(emb, CharParts.sphere_mesh(1.0, 10), CharParts.mat(EMBLEM_FACE), Vector3(ex, 0.006, 0.002), Vector3.ZERO, Vector3(0.009, 0.009, 0.008))
	CharParts.add(emb, CharParts.sphere_mesh(1.0, 12), CharParts.mat(EMBLEM_FACE), Vector3(0, -0.008, 0.008), Vector3.ZERO, Vector3(0.03, 0.024, 0.01))
	for ex in [-0.013, 0.013]:
		CharParts.add(emb, CharParts.sphere_mesh(1.0, 8), CharParts.unshaded(Color("2b1408")), Vector3(ex, 0.006, 0.017), Vector3.ZERO, Vector3(0.006, 0.007, 0.004))

	# --- Arms --------------------------------------------------------------------------------
	for side in [1.0, -1.0]:
		var arm := CharParts.pivot(torso, Vector3(0.2 * side, 0.29, 0), "ArmL" if side > 0 else "ArmR")
		CharParts.add(arm, CharParts.capsule_mesh(0.066, 0.3), CharParts.mat(HOODIE, ol), Vector3(0.015 * side, -0.12, 0))
		CharParts.add(arm, CharParts.cyl_mesh(0.058, 0.06, 0.04, 12), CharParts.mat(HOODIE_DARK, 0.008), Vector3(0.018 * side, -0.255, 0))
		CharParts.sphere(arm, 0.058, SKIN, Vector3(0.018 * side, -0.3, 0.005), Vector3(1.0, 1.05, 0.9), ol)
		if side > 0:
			arm_l = arm
		else:
			arm_r = arm

	# --- Head --------------------------------------------------------------------------------
	head = CharParts.pivot(torso, Vector3(0, 0.37, 0), "Head")
	var hc := CharParts.pivot(head, Vector3(0, 0.28, 0), "HeadCenter")
	var r := 0.3
	CharParts.add(hc, CharParts.sphere_mesh(r, 28), CharParts.mat(SKIN, ol), Vector3.ZERO, Vector3.ZERO, Vector3(1.04, 0.97, 1.0))
	for side in [-1.0, 1.0]:
		CharParts.add(hc, CharParts.sphere_mesh(0.07, 12), CharParts.mat(SKIN, ol), Vector3(0.295 * side, -0.03, -0.01), Vector3.ZERO, Vector3(0.55, 1.0, 0.8))
	build_face(hc, r, -0.03, 0.115, 0.072, 0.092, EYE_IRIS, BLUSH, -0.155)
	_build_hair(hc)
	_build_headband(hc)

	# --- Tail: long brown monkey tail with curled tip ----------------------------------------
	tail = CharParts.pivot(torso, Vector3(0, 0.03, -0.14), "Tail")
	# S-curve out to the character's left side, rising into a big curled tip (sticker silhouette)
	var ctrl := [Vector3(0, 0, 0), Vector3(0.06, -0.08, -0.12), Vector3(0.2, -0.06, -0.22), Vector3(0.34, 0.06, -0.24),
		Vector3(0.42, 0.24, -0.2), Vector3(0.42, 0.42, -0.16), Vector3(0.34, 0.52, -0.14), Vector3(0.24, 0.48, -0.13),
		Vector3(0.22, 0.38, -0.13), Vector3(0.28, 0.33, -0.13), Vector3(0.33, 0.38, -0.13)]
	CharParts.tube(tail, CharParts.smooth(ctrl, 5), 0.042, 0.055, TAIL, 0.011, 10)
	CharParts.sphere(tail, 0.055, TAIL_TIP, Vector3(0.33, 0.38, -0.13), Vector3.ONE, 0.011)
	_tail_base_rot = tail.rotation
	CharacterSculpt.clothing_details(self, WHITE, SKIN, HOODIE_DARK)


func _build_hair(hc: Node3D) -> void:
	var ol := 0.012
	var hm := CharParts.mat(HAIR, ol)
	var hl := CharParts.mat(HAIR_LIGHT, ol)
	# Volume cap (sits behind the face so eyes are never covered)
	CharParts.add(hc, CharParts.sphere_mesh(0.335, 24), hm, Vector3(0, 0.07, -0.085), Vector3.ZERO, Vector3(1.1, 0.98, 1.0))
	# Fluffy tousled clumps + short flyaway spikes (fixed seed = consistent silhouette).
	var rng := RandomNumberGenerator.new()
	rng.seed = 1701
	for i in 46:
		var polar := deg_to_rad(rng.randf_range(5.0, 115.0))
		var az := deg_to_rad(rng.randf_range(0.0, 360.0))
		var dir := Vector3(sin(polar) * sin(az), cos(polar), sin(polar) * cos(az))
		if dir.z > 0.5 and dir.y < 0.6:
			continue  # keep the face clear
		var base_pos := Vector3(0, 0.07, -0.085) + dir * 0.31
		var tip_dir := (dir + Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.1, 0.3), rng.randf_range(-0.35, 0.2))).normalized()
		var ctrl := [base_pos - dir * 0.06, base_pos + tip_dir * 0.065, base_pos + tip_dir * 0.13 + Vector3(0.035, 0.035, -0.015)]
		CharParts.add(hc, CharacterSculpt.lock_mesh(ctrl, rng.randf_range(0.07, 0.095), 0.05), hm if i % 4 else hl)
	# Side tufts over the ears and flyaways
	for side in [-1.0, 1.0]:
		for k in 3:
			var d := Vector3(side * 0.9, -0.15 - k * 0.12, 0.1 - k * 0.1).normalized()
			var start := Vector3(side * 0.27, 0.07 - k * 0.06, -0.025 - k * 0.04)
			CharParts.add(hc, CharacterSculpt.lock_mesh([start, start + d * 0.07, start + d * 0.14 + Vector3(0, 0.025, 0)], 0.06, 0.04), hm)
	# Bangs: chunky locks across the forehead, ending just above the eyes
	for i in 7:
		var x := -0.2 + i * 0.066
		var y := 0.15 + absf(x) * 0.05
		var z := surface_z(0.32, x, y) - 0.02
		var d := Vector3(x * 0.8 + (0.06 if i % 2 else -0.06), -1.0, 0.45).normalized()
		var start := Vector3(x, y + 0.07, z - 0.04)
		CharParts.add(hc, CharacterSculpt.lock_mesh([start, Vector3(x, y, z + 0.015), Vector3(x, y, z) + d * 0.10], 0.062, 0.032), hm if i % 3 else hl)


func _build_headband(hc: Node3D) -> void:
	var gold := CharParts.mat(GOLD, 0.005, 0.15, 0.35)
	# Band ring around hair, dipping slightly toward the forehead
	var ring := CharParts.add(hc, CharParts.torus_mesh(0.335, 0.368, 10, 40), gold, Vector3(0, 0.15, -0.03), Vector3(-14, 0, 0), Vector3(1.05, 1.0, 0.95))
	ring.name = "HeadbandRing"
	# Double INWARD spiral ornament on the forehead (canon: two inward spirals, not a crown)
	var orn := CharParts.pivot(hc, Vector3(0, 0.205, 0.335), "HeadbandSpirals")
	orn.rotation_degrees = Vector3(-18, 0, 0)
	for side in [-1.0, 1.0]:
		var pts := CharParts.spiral_points(1.4, 0.075, 0.014, 40, side < 0)
		var shifted := PackedVector3Array()
		for p in pts:
			shifted.append(Vector3(p.x * side * -1.0 + 0.082 * side, p.y, 0.0))
		CharParts.add(orn, CharParts.tube_mesh(shifted, 0.019, 0.014, 8), gold)
	CharParts.sphere(orn, 0.022, GOLD, Vector3(0, -0.045, -0.005), Vector3(1.4, 0.9, 0.8), 0.006)


func _animate_extras(delta: float, s: float) -> void:
	if tail:
		# Secondary motion: lazy sway at idle, lag & lift while running.
		var sway := sin(_time * 1.6) * deg_to_rad(10.0) + sin(_phase) * deg_to_rad(8.0) * s
		tail.rotation.y = lerpf(tail.rotation.y, sway, 1.0 - exp(-7.67 * delta))
		tail.rotation.x = lerpf(tail.rotation.x, deg_to_rad(-6.0) * s + sin(_time * 2.3) * deg_to_rad(3.0), 1.0 - exp(-6.322 * delta))
		tail.rotation.z = lerpf(tail.rotation.z, sin(_time * 1.1) * deg_to_rad(5.0), 1.0 - exp(-6.322 * delta))
