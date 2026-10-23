extends RegionBase
## 09 Village Garden & Park — central green, old tree, circular walk, play area, elder's home,
## community board. Visibly restored by "A Basket for the Village" and lit up by the festival.

var swing_pivot: Node3D
var _bed_flowers: Node3D
var _bed_empty: Node3D
var _basket: Node3D
var _festival: Node3D


func build() -> void:
	# Circular walking route
	var ring := CharParts.add(self, CharParts.torus_mesh(6.2, 7.6, 6, 48), CharParts.mat(EnvKit.PATH), Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1, 0.04, 1))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The old tree (landmark)
	var old_tree := EnvKit.tree(self, Vector3(0, 0, 0), 2.1, Color("5a9e55"))
	old_tree.name = "OldTree"
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		EnvKit.bench(self, Vector3(cos(a), 0, sin(a)) * 4.8, rad_to_deg(-a) - 90)
	# Fountain
	EnvKit.pond(self, Vector3(-9, 0, 7), 1.6)
	CharParts.add(self, CharParts.cyl_mesh(0.25, 0.35, 1.2, 12), CharParts.mat(Color("cdd5dc"), 0.01), Vector3(-9, 0.6, 7))
	CharParts.sphere(self, 0.35, Color("cdd5dc"), Vector3(-9, 1.25, 7), Vector3(1, 0.4, 1), 0.01)
	# Play area: swing + slide
	for x in [-1.0, 1.0]:
		CharParts.add(self, CharParts.cyl_mesh(0.06, 0.06, 2.4, 6), CharParts.mat(Color("e77f6e"), 0.008), Vector3(9 + x, 1.2, 7), Vector3(0, 0, x * 10))
	CharParts.add(self, CharParts.cyl_mesh(0.06, 0.06, 2.4, 6), CharParts.mat(Color("e77f6e"), 0.008), Vector3(9, 2.35, 7), Vector3(0, 0, 90))
	swing_pivot = Node3D.new()
	swing_pivot.position = Vector3(9, 2.35, 7)
	add_child(swing_pivot)
	CharParts.add(swing_pivot, CharParts.box_mesh(Vector3(0.6, 0.06, 0.3)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.008), Vector3(0, -1.75, 0))
	for x in [-0.25, 0.25]:
		CharParts.add(swing_pivot, CharParts.cyl_mesh(0.01, 0.01, 1.7, 4), CharParts.mat(Color("6b4a33")), Vector3(x, -0.88, 0))
	var slide := CharParts.add(self, CharParts.box_mesh(Vector3(0.8, 0.08, 3.0)), CharParts.mat(Color("78c9d4"), 0.008), Vector3(10.5, 0.8, 1.5), Vector3(32, 0, 0))
	slide.name = "Slide"
	EnvKit.solid_box(self, Vector3(1.0, 1.6, 1.0), Vector3(10.5, 0.8, -0.3), Color("f2d84b"), 0, 0.01)
	# Elder Maple's home
	EnvKit.tree_home(self, Vector3(9, 0, -8), -35, Color("d8c3e8"), Color("8e6fb0"))
	# Community flower bed (restored by the basket quest)
	EnvKit.solid_box(self, Vector3(4.0, 0.25, 2.0), Vector3(-8, 0.125, -7), Color("8a6243"), 0, 0.01)
	_bed_empty = Node3D.new()
	add_child(_bed_empty)
	for i in 5:
		CharParts.add(_bed_empty, CharParts.cyl_mesh(0.0, 0.08, 0.2, 5), CharParts.mat(Color("9a8a5a")), Vector3(-9.6 + i * 0.8, 0.35, -7 + (i % 2) * 0.4 - 0.2))
	_bed_flowers = Node3D.new()
	add_child(_bed_flowers)
	EnvKit.flowers(_bed_flowers, Vector3(-8, 0.1, -7), 70, 1.6, [Color("f2a3c0"), Color("f7d36b"), Color("fbe6ef"), Color("e77f6e")], 91)
	_basket = Node3D.new()
	_basket.position = Vector3(-4.2, 0, -8.6)
	add_child(_basket)
	CharParts.add(_basket, CharParts.cyl_mesh(0.42, 0.32, 0.4, 14), CharParts.mat(Color("c79a5b"), 0.01), Vector3(0, 0.2, 0))
	CharParts.add(_basket, CharParts.torus_mesh(0.3, 0.36, 6, 20), CharParts.mat(Color("a8804b"), 0.008), Vector3(0, 0.55, 0), Vector3(90, 0, 0))
	for i in 6:
		CharParts.sphere(_basket, 0.1, [Color("d8344a"), Color("f4a12a")][i % 2], Vector3(cos(i) * 0.2, 0.45, sin(i) * 0.2), Vector3.ONE, 0.006)
	# Community board
	var board_prompt := func(): return "Read the community board"
	var board_action := func(_a): _read_board()
	var board := add_point("community_board", Vector3(-3.5, 0, 9.5), board_prompt, board_action, Callable(), 2.2, 2.2)
	CharParts.add(board, CharParts.box_mesh(Vector3(2.0, 1.3, 0.1)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(0, 1.5, 0))
	for x in [-0.9, 0.9]:
		CharParts.add(board, CharParts.cyl_mesh(0.06, 0.06, 1.6, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(x, 0.8, 0))
	for i in 4:
		CharParts.add(board, CharParts.box_mesh(Vector3(0.35, 0.45, 0.02)), CharParts.mat([Color("fbf7ed"), Color("f2a3c0"), Color("f7d36b"), Color("a7d7e0")][i]), Vector3(-0.6 + i * 0.4, 1.5 + (i % 2) * 0.12, 0.07), Vector3(0, 0, (i - 1.5) * 4))
	var bsb := EnvKit.body(board)
	EnvKit.add_box_shape(bsb, Vector3(2.0, 2.2, 0.3), Vector3(0, 1.1, 0))
	for p in [Vector3(-11, 0, -1), Vector3(11, 0, -1), Vector3(-6, 0, 11), Vector3(6, 0, 11)]:
		EnvKit.lantern_post(self, p, p.x < 0 and p.z < 0)
	# Festival decorations (Land, Water, Forest celebration)
	_festival = Node3D.new()
	add_child(_festival)
	var cols := [Color("ffd88a"), Color("f2a3c0"), Color("a7d7e0"), Color("f7d36b")]
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		var p0 := Vector3(cos(a0) * 7.0, 3.2, sin(a0) * 7.0)
		var p1 := Vector3(cos(a1) * 7.0, 3.2, sin(a1) * 7.0)
		CharParts.add(_festival, CharParts.cyl_mesh(0.05, 0.05, 3.2, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(p0.x, 1.6, p0.z))
		for i in 9:
			var t := float(i) / 8.0
			var p := p0.lerp(p1, t) - Vector3(0, sin(t * PI) * 0.7, 0)
			var bulb := CharParts.sphere(_festival, 0.1, cols[(i + k) % 4], p, Vector3(1, 1.2, 1), 0.0)
			bulb.material_override = CharParts.mat(cols[(i + k) % 4], 0.0, 2.2)
	var fl := OmniLight3D.new()
	fl.position = Vector3(0, 4, 0)
	fl.omni_range = 14
	fl.light_color = Color("ffd59a")
	fl.light_energy = 1.2
	_festival.add_child(fl)
	GameState.world.flag_set.connect(func(_f): _apply())
	_apply()
	add_npc("elder", [[6, Vector3(7.0, 0, -5.5)], [9, Vector3(-2.0, 0, 8.6)], [14, Vector3(-5.0, 0, -6.0)], [19, Vector3(7.0, 0, -5.5)]])


func _apply() -> void:
	var restored := GameState.world.has_flag("park_restored")
	_bed_flowers.visible = restored
	_bed_empty.visible = not restored
	_basket.visible = restored
	_festival.visible = GameState.world.has_flag("festival")


func _read_board() -> void:
	var lines: Array = ["Board: TREE VILLAGE COMMUNITY BOARD - Requests are never urgent. Help whenever you have time."]
	var any := false
	for id in GameState.quests.order:
		var d: Dictionary = GameState.quests.defs[id]
		if d.get("auto_start", false) or GameState.quests.states.has(id):
			continue
		if GameState.quests.prereqs_met(id):
			lines.append("Board: %s - ask %s." % [String(d.title), NpcDB.display_name(String(d.giver))])
			any = true
	if not any:
		lines.append("Board: No new requests posted right now. Check back after helping around the village!")
	GameState.request_dialogue(lines)
