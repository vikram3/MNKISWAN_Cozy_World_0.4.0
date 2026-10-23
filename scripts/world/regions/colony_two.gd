extends RegionBase
## 12 Tree People Colony 2 — taller tree architecture, rope bridges, hanging baskets.
## Also hosts the broken stream-bridge site east of the colony (restoration quest).


func build() -> void:
	var homes := [Vector3(-7, 0, -5), Vector3(-7, 0, 6), Vector3(6, 0, -7)]
	var rots := [70.0, 110.0, -40.0]
	for i in homes.size():
		EnvKit.tree_home(self, homes[i], rots[i], [Color("e9dcc2"), Color("f0e6d2"), Color("e2d3b5")][i], [Color("b3a06a"), Color("5fa35a"), Color("c95c4a")][i], true)
	# Rope bridges between platforms (decorative, high above the path)
	_rope_bridge(Vector3(-7, 2.6, -5) + Vector3(0, 0, 2), Vector3(-7, 2.6, 6) - Vector3(0, 0, 2))
	_rope_bridge(Vector3(-5, 2.6, -5.5), Vector3(4.3, 2.6, -6.6))
	# Hanging baskets
	for p in [Vector3(-3, 3.2, 0.5), Vector3(-1, 3.0, -6.0), Vector3(2, 3.0, -6.3)]:
		CharParts.add(self, CharParts.cyl_mesh(0.3, 0.2, 0.3, 10), CharParts.mat(Color("c79a5b"), 0.008), p)
		EnvKit.flowers(self, p + Vector3(0, 0.0, 0), 8, 0.25, [Color("f2a3c0"), Color("f7d36b")], int(p.x * 10))
	EnvKit.tree(self, Vector3(-2, 0, 9.5), 1.4, Color("5a9e55"))
	EnvKit.sign_post(self, Vector3(3, 0, -4), "Colony Two\nOld stream bridge: east", 0)
	add_npc("mira", [[6, Vector3(-3.0, 0, -1.5)], [12, Vector3(3.5, 0, 2.5)], [18, Vector3(-3.5, 0, 4.0)]])


func _rope_bridge(a: Vector3, b: Vector3) -> void:
	var n := 12
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.5, 0)
		var plank := CharParts.add(self, CharParts.box_mesh(Vector3(0.9, 0.06, 0.3)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.006), p)
		plank.rotation.y = atan2(b.x - a.x, b.z - a.z) + PI * 0.5
	for side in [-0.45, 0.45]:
		var pts := PackedVector3Array()
		var dir := (b - a).normalized()
		var perp: Vector3 = Vector3(dir.z, 0, -dir.x) * side
		for i in 9:
			var t := float(i) / 8.0
			pts.append(a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.5, 0) + perp + Vector3(0, 0.8, 0))
		CharParts.add(self, CharParts.tube_mesh(pts, 0.025, 0.025, 5), CharParts.mat(Color("d9c08a")))
