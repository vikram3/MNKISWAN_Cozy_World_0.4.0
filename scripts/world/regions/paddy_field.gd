extends RegionBase
## 05 Paddy Field & Farm — neat plots, water channels, bund paths, a small shed, Bao.


func build() -> void:
	# Six player crop plots (stable IDs plot_01..06)
	var idx := 1
	for row in 2:
		for col in 3:
			var p := FarmPlot.new().setup("plot_%02d" % idx)
			p.name = "Plot%02d" % idx
			p.position = Vector3(-4.0 + col * 3.2, 0, -3.0 + row * 3.4)
			add_child(p)
			idx += 1
	# Water channels and raised bunds
	for z in [-5.0, 0.4, 5.6]:
		var ch := CharParts.add(self, CharParts.box_mesh(Vector3(12.0, 0.04, 0.5)), EnvKit.water_material(), Vector3(-0.8, 0.03, z))
		ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Decorative flooded paddies with rice tufts (east side)
	for k in 2:
		var c := Vector3(8.5, 0, -4.0 + k * 7.0)
		var w := CharParts.add(self, CharParts.box_mesh(Vector3(5.0, 0.05, 5.0)), EnvKit.water_material(), c + Vector3(0, 0.04, 0))
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		CharParts.add(self, CharParts.box_mesh(Vector3(5.4, 0.18, 0.3)), CharParts.mat(Color("a7c27a")), c + Vector3(0, 0.09, 2.6))
		CharParts.add(self, CharParts.box_mesh(Vector3(5.4, 0.18, 0.3)), CharParts.mat(Color("a7c27a")), c + Vector3(0, 0.09, -2.6))
		for i in 25:
			CharParts.add(self, CharParts.cyl_mesh(0.0, 0.1, 0.45, 5), CharParts.mat(Color("8cc96b")), c + Vector3(-2 + (i % 5), 0.25, -2 + (i / 5)))
		EnvKit.invisible_wall(self, Vector3(5, 2, 5), c + Vector3(0, 1, 0))
	# Shed
	var shed := EnvKit.solid_box(self, Vector3(3.2, 2.4, 2.6), Vector3(-9.5, 1.2, -7.0), Color("c9a77a"), 15, 0.012)
	var roof := CharParts.add(shed, CharParts.cyl_mesh(0.0, 2.6, 1.2, 4), CharParts.mat(EnvKit.ROOF_RED, 0.012), Vector3(0, 1.8, 0), Vector3(0, 45, 0), Vector3(1.0, 1.0, 0.85))
	roof.name = "ShedRoof"
	CharParts.add(shed, CharParts.box_mesh(Vector3(1.0, 1.6, 0.05)), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(0, -0.4, 1.32))
	EnvKit.crate(self, Vector3(-7.4, 0, -5.4), Color("e8d58a"))
	CharParts.add(self, CharParts.cyl_mesh(0.4, 0.4, 0.9, 14), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(-6.6, 0.45, -7.4))
	EnvKit.sign_post(self, Vector3(-6, 0, 8.5), "Paddy Field\nPlant - Water - Sleep - Harvest", 180)
	EnvKit.fence(self, Vector3(-13, 0, -10), Vector3(-2.2, 0, -10))
	EnvKit.fence(self, Vector3(2.2, 0, -10), Vector3(5.5, 0, -10))
	add_npc("bao", [[5, Vector3(-6.5, 0, -2.5)], [11, Vector3(5.0, 0, 3.6)], [17, Vector3(-8.0, 0, -4.5)]])
