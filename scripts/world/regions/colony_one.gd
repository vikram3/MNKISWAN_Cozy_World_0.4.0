extends RegionBase
## 11 Tree People Colony 1 — intimate lane, varied home silhouettes, gardens, hanging lanterns.


func build() -> void:
	EnvKit.tree_home(self, Vector3(-7, 0, -5), 70, Color("f3d9b1"), Color("c95c4a"))
	EnvKit.tree_home(self, Vector3(7.5, 0, -3), -80, Color("dfe8cf"), Color("6f8fe8"))
	EnvKit.tree_home(self, Vector3(-7, 0, 6), 110, Color("f6e2e8"), Color("e77f6e"))
	EnvKit.tree_home(self, Vector3(7.5, 0, 7), -110, Color("efe2c4"), Color("8b6749"))
	for p in [Vector3(-3, 0, -9), Vector3(3, 0, -9), Vector3(-3, 0, 1), Vector3(3, 0, 1), Vector3(-3, 0, 10), Vector3(3, 0, 10)]:
		EnvKit.lantern_post(self, p, p.x < 0 and p.z == 1.0)
	EnvKit.flowers(self, Vector3(-9.5, 0, 0.5), 30, 1.5, [Color("f7d36b"), Color("f2a3c0")], 111)
	EnvKit.flowers(self, Vector3(10, 0, 2), 30, 1.5, [Color("a7d7e0"), Color("fbe6ef")], 112)
	EnvKit.fence(self, Vector3(-11, 0, -1.5), Vector3(-8.5, 0, -1.5), false)
	EnvKit.fence(self, Vector3(8.5, 0, 2), Vector3(11, 0, 2), false)
	# Wind chimes on a little arch (local custom)
	CharParts.add(self, CharParts.torus_mesh(2.0, 2.2, 8, 24), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(0, 0.0, -10.5), Vector3(90, 0, 0))
	for i in 5:
		var a := PI * (i + 1) / 6.0
		CharParts.add(self, CharParts.cyl_mesh(0.03, 0.03, 0.35, 6), CharParts.mat(Color("a7d7e0"), 0.004), Vector3(cos(a) * 2.1, sin(a) * 2.1 - 0.3, -10.5))
	EnvKit.sign_post(self, Vector3(2.5, 0, -6.5), "Colony One\nLantern Lane", 0)
	add_npc("pip", [[6, Vector3(-3.2, 0, 3.0)], [11, Vector3(2.5, 0, -3.0)], [17, Vector3(-4.0, 0, 7.5)]])
