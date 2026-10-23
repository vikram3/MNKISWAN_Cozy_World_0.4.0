extends RegionBase
## 13 Market Square & Mnki & Swan Fruit Stall — the signature system. The stall visibly fills as
## goods sell and gains a shelf/order board, striped awning + flower bucket, and display tower.

var stall: Node3D
var _lvl_nodes: Array = [[], [], [], []]
var _plain_awning: Node3D
var _display: Node3D


func build() -> void:
	# Cobbled square
	EnvKit.disc(self, Vector3(0, 0.02, 0), 11.0, Color("e8d9b5"), 0.04)
	for i in 40:
		var a := randf() * TAU
		var d := sqrt(randf()) * 10.5
		EnvKit.disc(self, Vector3(cos(a) * d, 0.045, sin(a) * d), 0.35, Color("d8c69c"), 0.02)
	# Red canopy landmark (visible from the treehouse path)
	CharParts.add(self, CharParts.cyl_mesh(0.12, 0.15, 4.6, 8), CharParts.mat(EnvKit.WOOD_DARK, 0.01), Vector3(6, 2.3, 4))
	var can := CharParts.add(self, CharParts.cyl_mesh(0.2, 3.6, 1.3, 16), CharParts.mat(Color("d8443a"), 0.016), Vector3(6, 4.6, 4))
	can.name = "RedCanopy"
	for i in 8:
		var a := TAU * i / 8.0
		CharParts.add(self, CharParts.box_mesh(Vector3(0.5, 0.05, 3.4)), CharParts.mat(Color("fbf7ed")), Vector3(6 + cos(a) * 1.75, 4.62, 4 + sin(a) * 1.75), Vector3(-20, rad_to_deg(-a) + 90, 0))
	var psb := EnvKit.body(self, Vector3(6, 0, 4))
	EnvKit.add_cyl_shape(psb, 0.2, 4.6, Vector3(0, 2.3, 0))
	EnvKit.bench(self, Vector3(6, 0, 6.6), 180)
	_build_stall()
	_build_grocer()
	_build_decor()
	for p in [Vector3(-11, 0, 7), Vector3(11, 0, -8), Vector3(-11, 0, -9)]:
		EnvKit.lantern_post(self, p, p.z > 0)
	for p in [Vector3(-1.5, 0, -8.0), Vector3(-0.8, 0, -8.8), Vector3(9.5, 0, 0.5)]:
		EnvKit.crate(self, p, [Color("f4a12a"), Color("d8344a"), Color("7cc461")][int(absf(p.x)) % 3])
	GameState.shop.stall_upgraded.connect(func(_l): _apply())
	GameState.shop.display_changed.connect(func(_c): _apply())
	_apply()
	add_npc("tamsin", [[6, Vector3(-6.6, 0, 6.2)], [19, Vector3(-3.0, 0, 9.0)]])
	add_npc("odo", [[7, Vector3(7.6, 0, -1.4)], [18, Vector3(9.0, 0, 3.0)]])


func _build_stall() -> void:
	stall = Node3D.new()
	stall.name = "FruitStall"
	stall.position = Vector3(-4.5, 0, -6.5)
	add_child(stall)
	var wood := EnvKit.WOOD_LIGHT
	var sb := EnvKit.solid_box(stall, Vector3(3.8, 1.0, 1.0), Vector3(0, 0.5, 1.0), wood, 0, 0.012)
	sb.name = "Counter"
	CharParts.add(stall, CharParts.box_mesh(Vector3(3.9, 0.08, 1.1)), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(0, 1.04, 1.0))
	CharParts.add(stall, CharParts.box_mesh(Vector3(3.6, 0.1, 0.6)), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(0, 1.0, -0.6))
	for x in [-1.85, 1.85]:
		for z in [-0.9, 1.45]:
			CharParts.add(stall, CharParts.cyl_mesh(0.07, 0.08, 2.8, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 1.4, z))
	var bsb := EnvKit.body(stall)
	EnvKit.add_box_shape(bsb, Vector3(3.8, 2.0, 0.6), Vector3(0, 1.0, -0.6))
	# Level 0 awning: plain canvas
	_plain_awning = CharParts.add(stall, CharParts.box_mesh(Vector3(4.4, 0.08, 2.9)), CharParts.mat(Color("f3ead8"), 0.012), Vector3(0, 2.85, 0.3), Vector3(-10, 0, 0))
	# Sign
	var sign := EnvKit.label3d(stall, "MNKI & SWAN\nFRUIT STALL", Vector3(0, 2.35, 1.6), 64, Color("8b2f2a"))
	sign.outline_size = 12
	# Display: fruit in crates on the counter
	_display = Node3D.new()
	stall.add_child(_display)
	# Level 1: extra shelf + order board
	var l1 := Node3D.new(); stall.add_child(l1); _lvl_nodes[1].append(l1)
	CharParts.add(l1, CharParts.box_mesh(Vector3(3.6, 0.1, 0.5)), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(0, 1.65, -0.65))
	CharParts.add(l1, CharParts.box_mesh(Vector3(1.0, 1.2, 0.08)), CharParts.mat(Color("2f4f3f"), 0.01), Vector3(2.5, 1.4, 0.6), Vector3(0, -20, 0))
	CharParts.add(l1, CharParts.cyl_mesh(0.05, 0.05, 1.6, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(2.5, 0.8, 0.6))
	var ob := EnvKit.label3d(l1, "ORDERS", Vector3(2.52, 1.75, 0.66), 34, Color("fbf7ed"))
	ob.rotation_degrees.y = -20
	ob.outline_size = 0
	# Level 2: striped awning + flower bucket
	var l2 := Node3D.new(); stall.add_child(l2); _lvl_nodes[2].append(l2)
	for i in 8:
		CharParts.add(l2, CharParts.box_mesh(Vector3(0.56, 0.09, 3.0)), CharParts.mat(Color("d8443a") if i % 2 == 0 else Color("fbf7ed"), 0.01), Vector3(-1.96 + i * 0.56, 2.9, 0.3), Vector3(-10, 0, 0))
	for i in 8:
		CharParts.sphere(l2, 0.16, Color("d8443a") if i % 2 == 0 else Color("fbf7ed"), Vector3(-1.96 + i * 0.56, 2.62, 1.75), Vector3(1.6, 1, 0.5), 0.008)
	CharParts.add(l2, CharParts.cyl_mesh(0.3, 0.25, 0.5, 12), CharParts.mat(Color("78c9d4"), 0.01), Vector3(-2.5, 0.25, 1.4))
	EnvKit.flowers(l2, Vector3(-2.5, 0.35, 1.4), 18, 0.25, [Color("f5c531"), Color("f2a3c0"), Color.WHITE], 131)
	# Level 3: tiered display tower + painted sign
	var l3 := Node3D.new(); stall.add_child(l3); _lvl_nodes[3].append(l3)
	for t in 3:
		CharParts.add(l3, CharParts.cyl_mesh(0.6 - t * 0.17, 0.6 - t * 0.17, 0.1, 14), CharParts.mat(EnvKit.WOOD_LIGHT, 0.008), Vector3(-2.9, 0.5 + t * 0.45, 0.2))
		for k in 6 - t * 2:
			var a := TAU * k / (6 - t * 2)
			CharParts.sphere(l3, 0.09, [Color("f4a12a"), Color("d8344a"), Color("f2d84b")][(k + t) % 3], Vector3(-2.9 + cos(a) * (0.45 - t * 0.15), 0.62 + t * 0.45, 0.2 + sin(a) * (0.45 - t * 0.15)), Vector3.ONE, 0.006)
	CharParts.add(l3, CharParts.cyl_mesh(0.04, 0.04, 1.5, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(-2.9, 0.75, 0.2))
	var star := CharParts.add(l3, CharParts.box_mesh(Vector3(2.6, 0.6, 0.1)), CharParts.mat(Color("e4b96b"), 0.012), Vector3(0, 3.45, 1.2))
	star.name = "PaintedSign"
	var ps := EnvKit.label3d(l3, "fresh from Tree Village", Vector3(0, 3.45, 1.27), 36, Color("3b2a1e"))
	ps.outline_size = 0
	# Interactions
	var sprompt := func(): return "Open our fruit stall (sell, orders, upgrade)"
	var saction := func(actor):
		if actor.has_method("face_towards"):
			actor.face_towards(stall.global_position)
		var u := ui()
		if u:
			u.open_shop("stall")
	add_point("fruit_stall", Vector3(-4.5, 0, -4.1), sprompt, saction, Callable(), 2.4, 2.2, 3)


func _build_grocer() -> void:
	var g := Node3D.new()
	g.position = Vector3(-8.5, 0, 4.0)
	g.rotation_degrees.y = 110
	add_child(g)
	EnvKit.solid_box(g, Vector3(3.0, 0.9, 0.9), Vector3(0, 0.45, 0.8), Color("f2d84b"), 0, 0.012)
	CharParts.add(g, CharParts.box_mesh(Vector3(3.4, 0.08, 2.4)), CharParts.mat(Color("e77f6e"), 0.012), Vector3(0, 2.5, 0.3), Vector3(-12, 0, 0))
	for x in [-1.5, 1.5]:
		CharParts.add(g, CharParts.cyl_mesh(0.06, 0.07, 2.5, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 1.25, 1.2))
	var cols := [Color("c9d98a"), Color("9bd27e"), Color("f4b37a"), Color("ee8a7e"), Color("f7dd7a")]
	for i in 5:
		EnvKit.crate(g, Vector3(-1.2 + i * 0.6, 0.9, 0.8), cols[i], false)
	var lbl := EnvKit.label3d(g, "TAMSIN'S SEEDS & GROCERIES", Vector3(0, 1.9, 1.3), 36, Color("3b2a1e"))
	lbl.outline_size = 10
	var gp := func(): return "Buy seeds from Tamsin's crates"
	var ga := func(_a):
		var u := ui()
		if u:
			u.open_shop("grocer")
	var ap := ActionPoint.new().configure("grocer_counter", gp, ga, Callable(), 2.3, 1.8, 2)
	ap.position = Vector3(0, 0, 2.2)
	g.add_child(ap)


func _build_decor() -> void:
	var d := Node3D.new()
	d.position = Vector3(8.5, 0, -2.5)
	d.rotation_degrees.y = -55
	add_child(d)
	EnvKit.solid_box(d, Vector3(3.0, 0.9, 0.9), Vector3(0, 0.45, 0.8), Color("b07f52"), 0, 0.012)
	CharParts.add(d, CharParts.box_mesh(Vector3(3.4, 0.08, 2.4)), CharParts.mat(Color("78c9d4"), 0.012), Vector3(0, 2.5, 0.3), Vector3(-12, 0, 0))
	for x in [-1.5, 1.5]:
		CharParts.add(d, CharParts.cyl_mesh(0.06, 0.07, 2.5, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 1.25, 1.2))
	CharParts.sphere(d, 0.2, Color("e4b96b"), Vector3(-0.9, 1.15, 0.8), Vector3(1, 1.1, 1), 0.008)
	CharParts.add(d, CharParts.cyl_mesh(0.5, 0.5, 0.05, 16), CharParts.mat(Color("e77f6e"), 0.008), Vector3(0.1, 0.93, 0.8))
	CharParts.sphere(d, 0.25, Color("d9534f"), Vector3(1.0, 1.05, 0.8), Vector3(1, 0.45, 1), 0.008)
	for i in 4:
		CharParts.add(d, CharParts.box_mesh(Vector3(1.2, 0.08, 0.2)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.006), Vector3(2.2, 0.08 + i * 0.09, 0.3))
	var lbl := EnvKit.label3d(d, "ODO'S DECOR & PLANKS", Vector3(0, 1.9, 1.3), 36, Color("3b2a1e"))
	lbl.outline_size = 10
	var dp := func(): return "Browse Odo's decor & timber planks"
	var da := func(_a):
		var u := ui()
		if u:
			u.open_shop("decor")
	var ap := ActionPoint.new().configure("decor_counter", dp, da, Callable(), 2.3, 1.8, 2)
	ap.position = Vector3(0, 0, 2.2)
	d.add_child(ap)


func _apply() -> void:
	var lvl := GameState.shop.level
	for i in range(1, 4):
		for n in _lvl_nodes[i]:
			var nn: Node3D = n
			nn.visible = lvl >= i
	_plain_awning.visible = lvl < 2
	for c in _display.get_children():
		c.queue_free()
	# Base stock always shows a little fruit; more appears as sales grow (visible consequence)
	var count := 6 + mini(GameState.shop.display_count, 30)
	var cols := [Color("f4a12a"), Color("d8344a"), Color("f2d84b"), Color("7cc461"), Color("8b5e3c")]
	for i in count:
		var col := i % 10
		var row := (i / 10) % 3
		var p := Vector3(-1.6 + col * 0.34, 1.16 + row * 0.12, 0.75 + (row % 2) * 0.2)
		CharParts.sphere(_display, 0.1, cols[i % cols.size()], p, Vector3.ONE, 0.006)
