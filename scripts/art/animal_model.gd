class_name AnimalModel
extends Node3D
## Friendly farm animals (cow, sheep, chicken). Rounded toy-like forms with simple
## idle/walk/eat/happy animation. Faces +Z.

var species := "chicken"
var head: Node3D
var legs: Array = []
var _t := 0.0
var moving := 0.0
var mood := ""        # "", "happy", "eat", "groom"
var mood_t := 0.0


func setup(sp: String) -> AnimalModel:
	species = sp
	return self


func _ready() -> void:
	match species:
		"cow": _build_cow()
		"sheep": _build_sheep()
		_: _build_chicken()


func react(m: String, dur: float = 1.2) -> void:
	mood = m
	mood_t = dur


func _process(delta: float) -> void:
	_t += delta
	var bob := 0.0
	if moving > 0.05:
		bob = absf(sin(_t * 9.0)) * 0.03
		for i in legs.size():
			var lg: Node3D = legs[i]
			lg.rotation.x = sin(_t * 9.0 + (PI if i % 2 else 0.0)) * 0.5
	else:
		for lg in legs:
			var l2: Node3D = lg
			l2.rotation.x = lerpf(l2.rotation.x, 0.0, 0.2)
	if mood_t > 0.0:
		mood_t -= delta
		match mood:
			"happy":
				bob += absf(sin(_t * 12.0)) * 0.06
				if head: head.rotation.z = sin(_t * 10.0) * 0.2
			"eat":
				if head: head.rotation.x = lerpf(head.rotation.x, 0.7 + sin(_t * 14.0) * 0.12, 0.3)
			"groom":
				rotation.z = sin(_t * 8.0) * 0.04
		if mood_t <= 0.0:
			mood = ""
	else:
		if head:
			head.rotation.x = lerpf(head.rotation.x, sin(_t * 0.7) * 0.08, 0.1)
			head.rotation.z = lerpf(head.rotation.z, 0.0, 0.1)
		rotation.z = lerpf(rotation.z, 0.0, 0.1)
		if species == "chicken" and moving < 0.05 and head:
			head.rotation.x = 0.5 * maxf(0.0, sin(_t * 1.7)) * maxf(0.0, sin(_t * 0.4))
	position.y = bob


func _leg(parent: Node3D, pos: Vector3, h: float, r: float, color: Color) -> void:
	var p := CharParts.pivot(parent, pos)
	CharParts.add(p, CharParts.cyl_mesh(r, r, h, 10), CharParts.mat(color, 0.01), Vector3(0, -h * 0.5, 0))
	legs.append(p)


func _eyes(h: Node3D, x: float, y: float, z: float, r: float) -> void:
	for s in [-1.0, 1.0]:
		CharParts.add(h, CharParts.sphere_mesh(1.0, 10), CharParts.unshaded(Color("2b1408")), Vector3(x * s, y, z), Vector3.ZERO, Vector3(r, r * 1.2, r * 0.6))
		CharParts.add(h, CharParts.sphere_mesh(1.0, 8), CharParts.unshaded(Color.WHITE), Vector3(x * s + r * 0.3, y + r * 0.4, z + r * 0.4), Vector3.ZERO, Vector3(r * 0.35, r * 0.35, r * 0.2))


func _build_cow() -> void:
	var white := Color("f7f2ea")
	var spot := Color("6b4a3a")
	CharParts.sphere(self, 0.5, white, Vector3(0, 0.8, 0), Vector3(1.0, 0.85, 1.45), 0.015)
	CharParts.sphere(self, 0.2, spot, Vector3(0.32, 0.9, 0.1), Vector3(0.8, 1.0, 1.3), 0.0)
	CharParts.sphere(self, 0.18, spot, Vector3(-0.3, 0.85, -0.3), Vector3(0.8, 1.0, 1.2), 0.0)
	for p in [Vector3(0.28, 0.5, 0.45), Vector3(-0.28, 0.5, 0.45), Vector3(0.28, 0.5, -0.45), Vector3(-0.28, 0.5, -0.45)]:
		_leg(self, p, 0.48, 0.09, white)
	head = CharParts.pivot(self, Vector3(0, 1.05, 0.7))
	CharParts.sphere(head, 0.3, white, Vector3(0, 0.05, 0.12), Vector3(1.0, 0.95, 1.0), 0.013)
	CharParts.sphere(head, 0.2, Color("f2b6b0"), Vector3(0, -0.08, 0.36), Vector3(1.2, 0.8, 0.7), 0.01)
	for s in [-1.0, 1.0]:
		CharParts.sphere(head, 0.08, white, Vector3(0.3 * s, 0.15, 0.05), Vector3(1.5, 0.6, 0.8), 0.01)
		CharParts.add(head, CharParts.cyl_mesh(0.0, 0.04, 0.14, 8), CharParts.mat(Color("f1e3b9"), 0.008), Vector3(0.14 * s, 0.33, 0.06), Vector3(0, 0, -25 * s))
	_eyes(head, 0.12, 0.1, 0.38, 0.04)
	var bell := CharParts.sphere(head, 0.06, Color("e4b96b"), Vector3(0, -0.3, 0.1), Vector3.ONE, 0.008)
	bell.name = "Bell"
	CharParts.add(self, CharParts.cyl_mesh(0.02, 0.03, 0.5, 6), CharParts.mat(white, 0.008), Vector3(0, 0.75, -0.75), Vector3(30, 0, 0))


func _build_sheep() -> void:
	var wool := Color("fbf8f2")
	var face := Color("3e3330")
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	CharParts.sphere(self, 0.38, wool, Vector3(0, 0.6, 0), Vector3(1.0, 0.9, 1.25), 0.014)
	for i in 14:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.0, 1), rng.randf_range(-1, 1)).normalized()
		CharParts.sphere(self, 0.15, wool, Vector3(0, 0.6, 0) + d * Vector3(0.36, 0.3, 0.45), Vector3.ONE, 0.012)
	for p in [Vector3(0.18, 0.32, 0.25), Vector3(-0.18, 0.32, 0.25), Vector3(0.18, 0.32, -0.25), Vector3(-0.18, 0.32, -0.25)]:
		_leg(self, p, 0.32, 0.05, face)
	head = CharParts.pivot(self, Vector3(0, 0.78, 0.48))
	CharParts.sphere(head, 0.17, face, Vector3(0, 0, 0.08), Vector3(0.9, 1.0, 1.1), 0.01)
	CharParts.sphere(head, 0.14, wool, Vector3(0, 0.13, 0.02), Vector3(1.2, 0.8, 1.0), 0.01)
	for s in [-1.0, 1.0]:
		CharParts.sphere(head, 0.06, face, Vector3(0.17 * s, 0.03, 0.02), Vector3(1.5, 0.6, 0.8), 0.008)
	_eyes(head, 0.07, 0.03, 0.24, 0.03)


func _build_chicken() -> void:
	var white := Color("fffdf7")
	CharParts.sphere(self, 0.2, white, Vector3(0, 0.3, 0), Vector3(1.0, 0.95, 1.15), 0.012)
	CharParts.sphere(self, 0.1, white, Vector3(0, 0.38, -0.2), Vector3(0.8, 1.2, 0.7), 0.01)  # tail
	for s in [-1.0, 1.0]:
		CharParts.sphere(self, 0.1, Color("f1ede4"), Vector3(0.18 * s, 0.32, -0.02), Vector3(0.4, 0.8, 1.2), 0.008)
		_leg(self, Vector3(0.07 * s, 0.13, 0.02), 0.13, 0.015, Color("f2a33a"))
	head = CharParts.pivot(self, Vector3(0, 0.45, 0.14))
	CharParts.sphere(head, 0.11, white, Vector3(0, 0.05, 0.02), Vector3.ONE, 0.01)
	CharParts.add(head, CharParts.cyl_mesh(0.0, 0.035, 0.08, 8), CharParts.mat(Color("f2a33a"), 0.006), Vector3(0, 0.04, 0.15), Vector3(90, 0, 0))
	CharParts.sphere(head, 0.03, Color("e0473a"), Vector3(0, -0.02, 0.11), Vector3(0.7, 1.2, 0.7), 0.0)
	for i in 3:
		CharParts.sphere(head, 0.035, Color("e0473a"), Vector3(0, 0.16, -0.02 + i * 0.04), Vector3.ONE, 0.006)
	_eyes(head, 0.06, 0.08, 0.09, 0.022)
