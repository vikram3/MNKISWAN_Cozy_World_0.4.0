extends RegionBase
## 04 Village Flower Garden — colourful beds, trellis arch, benches, a small pond, two gardeners.


func build() -> void:
	var beds := [
		[Vector3(-7, 0, -5), [Color("f2a3c0"), Color("fbe6ef")]],
		[Vector3(-7, 0, 4), [Color("f7d36b"), Color("e77f6e")]],
		[Vector3(7, 0, -5), [Color("8fb0ff"), Color("ffffff")]],
		[Vector3(7, 0, 4), [Color("e0473a"), Color("f7d36b"), Color("f2a3c0")]],
	]
	for i in beds.size():
		var p: Vector3 = beds[i][0]
		EnvKit.solid_box(self, Vector3(5.0, 0.3, 3.0), p + Vector3(0, 0.15, 0), Color("8a6243"), 0.0, 0.01)
		EnvKit.flowers(self, p + Vector3(0, 0.15, 0), 70, 1.5, beds[i][1], 40 + i)
	# Trellis arch across the main path
	for x in [-1.8, 1.8]:
		CharParts.add(self, CharParts.box_mesh(Vector3(0.15, 2.6, 0.15)), CharParts.mat(Color("f3ead8"), 0.008), Vector3(x, 1.3, -1))
	var arch := CharParts.add(self, CharParts.torus_mesh(1.7, 1.9, 8, 24), CharParts.mat(Color("f3ead8"), 0.008), Vector3(0, 2.6, -1), Vector3(90, 0, 0))
	arch.name = "Trellis"
	for i in 9:
		var a := PI * i / 8.0
		CharParts.sphere(self, 0.13, [Color("f2a3c0"), Color("fbe6ef"), Color("e77f6e")][i % 3], Vector3(cos(a) * 1.8, 2.6 + sin(a) * 1.8, -0.9), Vector3.ONE, 0.006)
	EnvKit.pond(self, Vector3(0, 0, 7.5), 2.2)
	add_fishing("fish_garden", "garden_pond", Vector3(3.2, 0, 7.3), Vector3(-2.6, 0.1, 0.0))
	EnvKit.bench(self, Vector3(-3.5, 0, 7.5), 90)
	EnvKit.bench(self, Vector3(11, 0, -1), -90)
	# Gardening stations: watering cans + tool racks
	for p in [Vector3(-10.5, 0, -1), Vector3(10.5, 0, 2.5)]:
		CharParts.add(self, CharParts.cyl_mesh(0.18, 0.2, 0.32, 12), CharParts.mat(Color("78c9d4"), 0.01), p + Vector3(0, 0.16, 0))
		CharParts.add(self, CharParts.cyl_mesh(0.03, 0.04, 0.35, 6), CharParts.mat(Color("78c9d4"), 0.006), p + Vector3(0.2, 0.3, 0), Vector3(0, 0, -50))
	# Collectible daisies (distinct from decorative beds: white patches with a marker)
	var patches := [Vector3(-3.5, 0, -8), Vector3(3.5, 0, -8.5), Vector3(-10, 0, 8.5), Vector3(10, 0, 8.5), Vector3(-1.5, 0, 3.5)]
	for i in patches.size():
		add_gather("fg_flower_%d" % i, "flower_patch", patches[i])
	add_npc("rosa", [[6, Vector3(-4.5, 0, -2.2)], [13, Vector3(-4.5, 0, 6.5)], [19, Vector3(-9, 0, 1)]])
	add_npc("ivo", [[6, Vector3(4.5, 0, -2.2)], [12, Vector3(4.6, 0, 6.6)], [18, Vector3(9.5, 0, 0)]])
