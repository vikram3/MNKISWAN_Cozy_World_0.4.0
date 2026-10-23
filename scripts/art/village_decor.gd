class_name VillageDecor
extends RefCounted
## Small crafted props and layered planting, shared without loading external art.

static func box(p: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	return CharParts.add(p, CharParts.box_mesh(size), CharParts.mat(color), at)

static func gathering_place(parent: Node3D, tint: Color, index: int) -> void:
	# Clear central aisle; only the four posts have collision.
	EnvKit.disc(parent, Vector3(0, 0.035, 0), 3.25, Color("cbbd95"), 0.045)
	EnvKit.disc(parent, Vector3(0, 0.065, 0), 2.95, Color("e3d4ad"), 0.035)
	for x in [-2.65, 2.65]:
		for z in [-1.55, 1.55]:
			EnvKit.solid_box(parent, Vector3(0.16, 2.9, 0.16), Vector3(x, 1.45, z), EnvKit.WOOD)
			box(parent, Vector3(0.25, 0.12, 0.25), Vector3(x, 2.9, z), EnvKit.WOOD_LIGHT)
		box(parent, Vector3(0.16, 0.16, 3.6), Vector3(x, 2.85, 0), EnvKit.WOOD_LIGHT)
	for z in [-1.65, 1.65]:
		box(parent, Vector3(5.7, 0.16, 0.17), Vector3(0, 2.85, z), EnvKit.WOOD_LIGHT)
	# Alternating open pergolas / striped cloth roofs keep distinct silhouettes.
	for i in 9:
		var x := -2.4 + i * 0.6
		if index % 3 == 0:
			box(parent, Vector3(0.14, 0.1, 3.5), Vector3(x, 3.0, 0), EnvKit.WOOD_LIGHT)
		else:
			box(parent, Vector3(0.6, 0.045, 3.3), Vector3(x, 3.0 + sin(float(i) / 8.0 * PI) * 0.32, 0), tint if i % 2 == 0 else EnvKit.CREAM)
	var cable := PackedVector3Array()
	for i in 17:
		var t := float(i) / 16.0
		cable.append(Vector3(lerpf(-2.6, 2.6, t), 2.8 - sin(t * PI) * 0.45, 1.7))
	CharParts.add(parent, CharParts.tube_mesh(cable, 0.015, 0.015, 4), CharParts.mat(EnvKit.WOOD_DARK))
	for i in 9:
		var t := float(i) / 8.0
		var pos := Vector3(lerpf(-2.6, 2.6, t), 2.67 - sin(t * PI) * 0.45, 1.7)
		CharParts.add(parent, CharParts.sphere_mesh(0.075, 8), CharParts.mat(Color("ffe3a0"), 0, 0.6), pos)
	# Baskets, climbing leaves and mixed-height flower borders frame each place.
	for side in [-1.0, 1.0]:
		var pos := Vector3(side * 3.0, 0, -0.5)
		box(parent, Vector3(0.6, 0.4, 2.2), pos + Vector3(0, 0.2, 0), EnvKit.WOOD_LIGHT)
		EnvKit.flowers(parent, pos + Vector3(0, 0.4, 0), 36, 0.85, [tint, Color("fff0c7"), tint.lightened(0.25)], index * 11 + int(side) + 30)
		for j in 5:
			CharParts.sphere(parent, 0.18, Color("69965a"), Vector3(side * 2.67, 0.6 + j * 0.43, -1.55), Vector3(1.5, 0.6, 1), 0)
	EnvKit.flowers(parent, Vector3(0, 0, -2.5), 65, 2.5, [tint, Color("fff0c7")], index + 350)

static func activity_prop(parent: Node3D, kind: String, tint: Color) -> Dictionary:
	var result := Node3D.new()
	result.name = "CompletedDetails"
	parent.add_child(result)
	var animated: Node3D = null
	match kind:
		"flower":
			box(parent, Vector3(1.0, 0.45, 0.65), Vector3(0, 0.23, 0), tint.darkened(0.25))
			box(parent, Vector3(0.86, 0.05, 0.5), Vector3(0, 0.46, 0), Color("665044"))
			EnvKit.flowers(parent, Vector3(0, 0.48, 0), 5, 0.3, [Color("9aa681")], 35)
			EnvKit.flowers(result, Vector3(0, 0.48, 0), 30, 0.42, [tint, Color("fff0c7")], 37)
		"tea", "basket":
			box(parent, Vector3(1.05, 0.12, 0.72), Vector3(0, 0.72, 0), EnvKit.WOOD_LIGHT)
			for x in [-0.38, 0.38]:
				box(parent, Vector3(0.12, 0.7, 0.5), Vector3(x, 0.35, 0), EnvKit.WOOD)
			box(parent, Vector3(0.35, 0.02, 0.73), Vector3(0, 0.8, 0), tint)
			if kind == "tea":
				CharParts.sphere(parent, 0.18, tint, Vector3(0, 0.98, 0), Vector3(1, 0.8, 1), 0)
				for x in [-0.32, 0.32]:
					CharParts.add(result, CharParts.cyl_mesh(0.1, 0.075, 0.15, 12), CharParts.mat(EnvKit.CREAM), Vector3(x, 0.89, 0.16))
					CharParts.add(result, CharParts.cyl_mesh(0.084, 0.084, 0.01, 12), CharParts.mat(Color("b47e43")), Vector3(x, 0.97, 0.16))
			else:
				CharParts.add(parent, CharParts.cyl_mesh(0.35, 0.26, 0.25, 12), CharParts.mat(Color("bf9258")), Vector3(0, 0.92, 0))
				for i in 7:
					var a := i * TAU / 7.0
					CharParts.sphere(result, 0.12, [tint, Color("e4c257"), Color("d97565")][i % 3], Vector3(cos(a) * 0.21, 1.08, sin(a) * 0.18), Vector3.ONE, 0)
		"water":
			box(parent, Vector3(1.0, 0.32, 0.7), Vector3(0, 0.16, 0), Color("9ca7a0"))
			CharParts.add(result, CharParts.box_mesh(Vector3(0.86, 0.03, 0.56)), EnvKit.water_material(), Vector3(0, 0.34, 0))
			animated = CharParts.pivot(parent, Vector3(0, 0.86, -0.25))
			CharParts.add(animated, CharParts.torus_mesh(0.3, 0.37, 6, 16), CharParts.mat(EnvKit.WOOD_LIGHT), Vector3.ZERO, Vector3(90, 0, 0))
			for i in 8:
				var blade := box(animated, Vector3(0.1, 0.75, 0.15), Vector3.ZERO, EnvKit.WOOD_LIGHT)
				blade.rotation.z = i * PI / 4.0
		"feeder":
			box(parent, Vector3(0.13, 1.1, 0.13), Vector3(0, 0.55, 0), EnvKit.WOOD)
			box(parent, Vector3(0.8, 0.08, 0.55), Vector3(0, 1.05, 0), EnvKit.WOOD_LIGHT)
			CharParts.add(parent, CharParts.cyl_mesh(0, 0.58, 0.4, 4), CharParts.mat(tint), Vector3(0, 1.6, 0), Vector3(0, 45, 0))
			for x in [-0.3, 0.3]:
				box(parent, Vector3(0.06, 0.4, 0.06), Vector3(x, 1.28, 0), EnvKit.WOOD)
			for i in 12:
				CharParts.sphere(result, 0.035, Color("f4d888"), Vector3(sin(i * 2.4) * 0.25, 1.12, cos(i * 2.4) * 0.18), Vector3.ONE, 0)
			# A tiny bird arrives when food is provided.
			CharParts.sphere(result, 0.11, tint, Vector3(0.27, 1.24, 0.16), Vector3(0.8, 1, 1.3), 0)
			CharParts.sphere(result, 0.07, tint.lightened(0.2), Vector3(0.27, 1.35, 0.23), Vector3.ONE, 0)
			CharParts.sphere(result, 0.025, Color("f2c257"), Vector3(0.27, 1.34, 0.3), Vector3(1, 0.5, 1.5), 0)
		"chime", "lantern":
			box(parent, Vector3(0.12, 1.85, 0.12), Vector3(-0.42, 0.925, 0), EnvKit.WOOD)
			box(parent, Vector3(0.9, 0.1, 0.12), Vector3(0, 1.85, 0), EnvKit.WOOD)
			animated = CharParts.pivot(parent, Vector3(0.05, 1.75, 0))
			if kind == "chime":
				for i in 5:
					var h := 0.35 + i * 0.08
					box(animated, Vector3(0.012, 0.16, 0.012), Vector3(-0.26 + i * 0.13, -0.08, 0), EnvKit.WOOD_DARK)
					CharParts.add(animated, CharParts.cyl_mesh(0.04, 0.04, h, 8), CharParts.mat(tint), Vector3(-0.26 + i * 0.13, -0.16 - h * 0.5, 0))
				CharParts.sphere(result, 0.09, Color("f4d888"), Vector3(0.05, 0.65, 0), Vector3.ONE, 0)
			else:
				box(parent, Vector3(0.48, 0.07, 0.48), Vector3(0.05, 0.95, 0), EnvKit.WOOD_DARK)
				box(parent, Vector3(0.48, 0.07, 0.48), Vector3(0.05, 1.55, 0), EnvKit.WOOD_DARK)
				CharParts.add(parent, CharParts.sphere_mesh(0.24, 12), CharParts.mat(tint.darkened(0.4)), Vector3(0.05, 1.25, 0), Vector3.ZERO, Vector3(1, 1.2, 1))
				CharParts.add(result, CharParts.sphere_mesh(0.25, 12), CharParts.mat(Color("ffe1a0"), 0, 1.2), Vector3(0.05, 1.25, 0), Vector3.ZERO, Vector3(1, 1.2, 1))
	# Props are solid, but their approach is on the open front side.
	var body := EnvKit.body(parent)
	EnvKit.add_box_shape(body, Vector3(1.0, 0.9, 0.65), Vector3(0, 0.45, 0))
	return {"result": result, "animated": animated}

static func landscape(region: RegionBase, tint: Color) -> void:
	match region.region_id:
		"sunshine_forest", "flower_garden", "village_park":
			# Flowering trees add a second canopy colour and a carpet of fallen petals.
			var points: Array = {
				"sunshine_forest": [Vector3(7, 0, 7), Vector3(-11, 0, -6)],
				"flower_garden": [Vector3(-12, 0, -8), Vector3(12, 0, 10)],
				"village_park": [Vector3(-11, 0, -11), Vector3(12, 0, 11)],
			}[region.region_id]
			for p: Vector3 in points:
				EnvKit.tree(region, p, 0.85, Color("eeb7bf"))
				EnvKit.flowers(region, p + Vector3(0, -0.15, 0), 70, 2.5, [Color("eeb7bf"), Color("fbe7db")], int(p.x * 3 + 100))
		"waterfall_ponds":
			# Break up the cliff silhouette with mossy shoulders and rock shelves.
			for side in [-1.0, 1.0]:
				for i in 4:
					var p := Vector3(side * (6.5 + i * 2.0), 0.4 + i * 0.8, -11)
					var rock := EnvKit.rock(region, p, 1.4 + i * 0.22, false)
					rock.scale.y = 1.5
					EnvKit.bush(region, p + Vector3(0, 1.5 + i * 0.15, 0), 0.8, Color("73a57a"))
			for i in 9:
				var a := i * TAU / 9.0
				var p := Vector3(2 + cos(a) * 3.1, 0.13, -6 + sin(a) * 3.1)
				EnvKit.disc(region, p, 0.3, Color("70aa86"), 0.025)
				CharParts.sphere(region, 0.1, Color("f3c0ce"), p + Vector3(0, 0.06, 0), Vector3(1, 0.5, 1), 0)
		"berry_maze":
			for x in [-10, 10]:
				EnvKit.lantern_post(region, Vector3(x, 0, -11.5))
				EnvKit.flowers(region, Vector3(x, 0, 11.5), 45, 1.4, [tint, Color("fff0c7")], x + 90)
		"paddy_field":
			# A small drying rack gives the field a recognisable working silhouette.
			for x in [-11.0, -5.5]:
				EnvKit.solid_box(region, Vector3(0.14, 2.0, 0.14), Vector3(x, 1.0, 9.5), EnvKit.WOOD)
			box(region, Vector3(5.8, 0.14, 0.14), Vector3(-8.25, 1.9, 9.5), EnvKit.WOOD_LIGHT)
			for i in 8:
				CharParts.add(region, CharParts.cyl_mesh(0.06, 0.22, 0.8, 7), CharParts.mat(Color("dfc17a")), Vector3(-10.5 + i * 0.65, 1.4, 9.5))
		"tropical_forest":
			for p in [Vector3(-5, 0, 10), Vector3(11, 0, -8)]:
				EnvKit.flowers(region, p, 70, 2.0, [Color("ed885d"), Color("f1c764"), Color("cf6c77")], 63)
				EnvKit.bush(region, p + Vector3(0, 0, 1), 0.7, Color("49835b"))
		"animal_farm":
			for i in 4:
				var p := Vector3(-12 + (i % 2) * 1.1, 0.4 + (i / 2) * 0.8, -8)
				CharParts.add(region, CharParts.cyl_mesh(0.43, 0.43, 1, 12), CharParts.mat(Color("d9b76d")), p, Vector3(0, 0, 90))
			EnvKit.flowers(region, Vector3(12, 0, 7), 85, 2.8, [Color("f1ce6b"), Color("fff1c3")], 77)
		"guardian_gate":
			for side in [-1.0, 1.0]:
				for i in 4:
					EnvKit.disc(region, Vector3(side * 2, 0.08, -8 + i * 2.2), 0.25, Color("b5aea0"), 0.15)
					CharParts.add(region, CharParts.cyl_mesh(0.08, 0.08, 0.25, 8), CharParts.mat(Color("ffe2aa"), 0, 0.4), Vector3(side * 2, 0.28, -8 + i * 2.2))
		"treehouse":
			EnvKit.flowers(region, Vector3(6, 0, -8.5), 100, 2.5, [tint, Color("f6deab"), Color("b5cba0")], 100)
			EnvKit.bench(region, Vector3(6, 0, 7), 180)
		"colony_one", "colony_two":
			for z in [-7.0, 2.0, 9.0]:
				var points := PackedVector3Array()
				for i in 13:
					var t := float(i) / 12
					points.append(Vector3(lerpf(-3.2, 3.2, t), 3.8 - sin(t * PI) * 0.6, z))
				CharParts.add(region, CharParts.tube_mesh(points, 0.018, 0.018, 4), CharParts.mat(EnvKit.WOOD_DARK))
				for i in 7:
					var t := float(i) / 6
					CharParts.add(region, CharParts.sphere_mesh(0.12, 8), CharParts.mat(Color("ffdda1"), 0, 0.6), Vector3(lerpf(-3.2, 3.2, t), 3.6 - sin(t * PI) * 0.6, z), Vector3.ZERO, Vector3(1, 1.3, 1))
		"market_square":
			for side in [-1.0, 1.0]:
				EnvKit.flowers(region, Vector3(side * 11, 0, 8), 90, 2, [tint, Color("f8d778"), Color("f8e5d6")], int(side) + 132)
				EnvKit.lantern_post(region, Vector3(side * 9.5, 0, 10))
