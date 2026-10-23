extends RegionBase
## 01 Sunshine Forest — starting clearing: dappled light, flowers, berries, butterflies.


func build() -> void:
	# Ring of big soft trees framing the clearing (open toward south & east paths)
	var ring := [Vector3(-11, 0, -8), Vector3(-6, 0, -11), Vector3(1, 0, -11.5), Vector3(8, 0, -10), Vector3(-12.5, 0, 0), Vector3(-12, 0, 7), Vector3(11, 0, 8), Vector3(-7, 0, 10.5), Vector3(7, 0, 11)]
	for i in ring.size():
		EnvKit.tree(self, ring[i], 1.25 + (i % 3) * 0.15, [Color("5fa35a"), Color("7cbf5e"), Color("4f9a50")][i % 3])
	# Sun shafts (soft transparent cones)
	for p in [Vector3(-3, 0, -2), Vector3(4, 0, 3), Vector3(-6, 0, 5)]:
		var shaft := CharParts.add(self, CharParts.cyl_mesh(0.6, 2.2, 9.0, 16), CharParts.unshaded(Color(1.0, 0.95, 0.75, 0.035)), p + Vector3(0, 4.5, 0), Vector3(8, 0, 6))
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EnvKit.flowers(self, Vector3(-4, 0, -4), 60, 4.0, [Color("fbe6ef"), Color("f7d36b"), Color("f2a3c0"), Color.WHITE], 11)
	EnvKit.flowers(self, Vector3(6, 0, -5), 40, 3.0, [Color("f7d36b"), Color("e77f6e"), Color.WHITE], 12)
	for i in 5:
		var p := Vector3(-9 + i * 4.5, 0, -7.5 + (i % 2) * 15.0)
		if i == 1:
			p = Vector3(-3.5, 0, 10) # keep the new picnic's walking area clear
		EnvKit.rock(self, p, 0.6 + (i % 3) * 0.2)
	# Gatherables: the opening tutorial needs two berries close at hand
	add_gather("sf_berry_1", "berry_bush", Vector3(-4, 0, 3))
	add_gather("sf_berry_2", "berry_bush", Vector3(3.5, 0, -4))
	add_gather("sf_berry_3", "berry_bush", Vector3(-8, 0, -3))
	add_gather("sf_flower_1", "flower_patch", Vector3(5, 0, 5))
	add_gather("sf_flower_2", "flower_patch", Vector3(-8, 0, 3))
	EnvKit.sign_post(self, Vector3(1.8, 0, 6), "Home & Village: south\nWaterfall: east", 0)
	# Butterflies
	for i in 6:
		var b := Butterfly.new()
		b.position = Vector3(randf_range(-7, 7), 1.0, randf_range(-7, 7))
		b.color = [Color("f7d36b"), Color("f2a3c0"), Color("a7d7e0")][i % 3]
		add_child(b)
	# Picnic blanket where the story starts
	CharParts.add(self, CharParts.box_mesh(Vector3(2.2, 0.03, 1.6)), CharParts.mat(Color("e77f6e")), Vector3(0, 0.02, -2), Vector3(0, 15, 0))
	for i in 4:
		CharParts.add(self, CharParts.box_mesh(Vector3(2.2, 0.031, 0.12)), CharParts.mat(Color("fbf7ed")), Vector3(0, 0.025, -2.6 + i * 0.4), Vector3(0, 15, 0))
	CharParts.add(self, CharParts.cyl_mesh(0.3, 0.25, 0.25, 12), CharParts.mat(Color("c79a5b"), 0.01), Vector3(0.6, 0.13, -2.2))


class Butterfly extends Node3D:
	var color := Color.WHITE
	var _t := 0.0
	var _home := Vector3.ZERO
	var _wl: Node3D
	var _wr: Node3D

	func _ready() -> void:
		_home = position
		_t = randf() * 10.0
		_wl = Node3D.new(); add_child(_wl)
		_wr = Node3D.new(); add_child(_wr)
		var m := CharParts.unshaded(color)
		CharParts.add(_wl, CharParts.sphere_mesh(0.5, 8), m, Vector3(0.06, 0, 0), Vector3.ZERO, Vector3(0.12, 0.01, 0.09))
		CharParts.add(_wr, CharParts.sphere_mesh(0.5, 8), m, Vector3(-0.06, 0, 0), Vector3.ZERO, Vector3(0.12, 0.01, 0.09))

	func _process(delta: float) -> void:
		_t += delta
		position = _home + Vector3(sin(_t * 0.7) * 2.0, 0.4 + sin(_t * 1.9) * 0.3, cos(_t * 0.5) * 2.0)
		var f := sin(_t * 18.0) * 0.9
		_wl.rotation.z = f
		_wr.rotation.z = -f
		rotation.y = _t * 0.6
