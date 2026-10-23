extends RegionBase
## 10 Mnki & Swan's Two-Storey Treehouse — a cutaway diorama home (open front avoids camera
## problems). Ground floor: living area, storage, keepsake shelf. Upper floor: kitchen + bed.
## House collision uses layer 5 so the camera spring arm doesn't snap inside the rooms.

const HOUSE_LAYER := 16
const WALL := Color("c99a6b")
const FLOOR := Color("b58a60")
const TRIM := Color("8b6749")

var house: Node3D


func build() -> void:
	house = Node3D.new()
	house.name = "House"
	house.position = Vector3(-4.5, 0, 0)
	house.rotation_degrees.y = 90   # open front faces east, toward the paths
	add_child(house)
	_shell()
	_ground_floor()
	_upper_floor()
	# Home tree behind
	var trunk := CharParts.add(house, CharParts.cyl_mesh(1.4, 2.0, 13.0, 14), CharParts.mat(EnvKit.WOOD, 0.016), Vector3(0, 6.5, -6.2))
	trunk.name = "HomeTreeTrunk"
	var tsb := EnvKit.body(house)
	EnvKit.add_cyl_shape(tsb, 1.9, 13.0, Vector3(0, 6.5, -6.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 10
	for i in 9:
		var off := Vector3(rng.randf_range(-5, 5), rng.randf_range(0, 2.5), rng.randf_range(-4, 2))
		CharParts.add(house, CharParts.sphere_mesh(rng.randf_range(2.2, 3.2), 16), CharParts.mat([Color("5fa35a"), Color("7cbf5e"), Color("4f9a50")][i % 3], 0.018), Vector3(0, 12.0, -5.5) + off)
	# Mailbox + welcome sign
	EnvKit.sign_post(self, Vector3(3.0, 0, -5.0), "MNKI & SWAN\nhome sweet treehouse", 90)
	EnvKit.lantern_post(self, Vector3(3.0, 0, 5.0), true)
	EnvKit.flowers(self, Vector3(2.5, 0, 6.5), 30, 1.4, [Color("f2a3c0"), Color("fbe6ef"), Color("f7d36b")], 101)
	EnvKit.flowers(self, Vector3(2.5, 0, -7.0), 30, 1.4, [Color("e77f6e"), Color("fbe6ef")], 102)


func _hbox(size: Vector3, pos: Vector3, color: Color, rot := Vector3.ZERO, outline := 0.012, solid := true) -> Node3D:
	var sb: Node3D
	if solid:
		var b := EnvKit.body(house, pos, HOUSE_LAYER)
		b.rotation_degrees = rot
		EnvKit.add_box_shape(b, size)
		sb = b
	else:
		sb = Node3D.new()
		sb.position = pos
		sb.rotation_degrees = rot
		house.add_child(sb)
	CharParts.add(sb, CharParts.box_mesh(size), CharParts.mat(color, outline))
	return sb


func _shell() -> void:
	# Floor deck, back and side walls, upper floor, roof
	_hbox(Vector3(10.4, 0.12, 8.4), Vector3(0, 0.06, 0), FLOOR, Vector3.ZERO, 0.0, false)
	_hbox(Vector3(10.8, 6.4, 0.4), Vector3(0, 3.2, -4.3), WALL)
	_hbox(Vector3(0.4, 6.4, 8.6), Vector3(-5.3, 3.2, 0), WALL)
	_hbox(Vector3(0.4, 6.4, 8.6), Vector3(5.3, 3.2, 0), WALL)
	# Corner posts and beams (crafted look)
	for x in [-5.3, 5.3]:
		_hbox(Vector3(0.5, 6.6, 0.5), Vector3(x, 3.3, 4.3), TRIM)
	_hbox(Vector3(11.2, 0.4, 0.5), Vector3(0, 6.5, 4.3), TRIM, Vector3.ZERO, 0.012, false)
	# Round windows
	for p in [Vector3(-5.08, 1.8, -1.5), Vector3(-5.08, 4.8, -2.0), Vector3(5.08, 1.8, -2.0)]:
		CharParts.add(house, CharParts.cyl_mesh(0.6, 0.6, 0.06, 16), CharParts.mat(Color("ffe3a3"), 0.01, 0.35), p, Vector3(0, 0, 90))
	# Upper floor (back half) + railing
	_hbox(Vector3(10.2, 0.3, 4.6), Vector3(0, 3.05, -1.85), FLOOR)
	_hbox(Vector3(8.0, 0.08, 0.08), Vector3(-1.0, 4.05, 0.42), TRIM, Vector3.ZERO, 0.008, false)
	for i in 9:
		_hbox(Vector3(0.08, 0.9, 0.08), Vector3(-5.0 + i * 1.0, 3.65, 0.42), TRIM, Vector3.ZERO, 0.006, false)
	var rail := EnvKit.body(house, Vector3(-1.0, 3.7, 0.42), HOUSE_LAYER)
	EnvKit.add_box_shape(rail, Vector3(8.2, 1.0, 0.2))
	# Stairs along the right wall: visual steps + one ramp collision proxy
	for i in 10:
		var z := 4.2 - i * 0.4
		_hbox(Vector3(1.2, 0.12, 0.42), Vector3(4.3, 0.2 + i * 0.29, z), FLOOR.lightened(0.08), Vector3.ZERO, 0.006, false)
	# A wedge meets ground level and overlaps the upper deck: the old rotated box
	# blocked the walking approach at its raised entry edge.
	var ramp := EnvKit.body(house, Vector3(4.3, 0, 0), HOUSE_LAYER)
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for x in [-0.6, 0.6]:
		points.append(Vector3(x, -0.12, 4.65))
		points.append(Vector3(x, -0.02, 4.65))
		points.append(Vector3(x, -0.12, 0.35))
		points.append(Vector3(x, 3.3, 0.35))
	shape.points = points
	var collider := CollisionShape3D.new()
	collider.shape = shape
	ramp.add_child(collider)
	# Roof (no collision — keeps the camera free)
	var roof := CharParts.add(house, CharParts.cyl_mesh(0.6, 7.6, 2.6, 16), CharParts.mat(Color("6fa35a"), 0.018), Vector3(0, 7.9, 0))
	roof.name = "LeafRoof"
	CharParts.add(house, CharParts.cyl_mesh(7.7, 7.7, 0.25, 16), CharParts.mat(Color("5a9047"), 0.014), Vector3(0, 6.65, 0))


func _ground_floor() -> void:
	# Storage chest
	var chest := Node3D.new()
	chest.position = Vector3(-4.2, 0, -3.2)
	house.add_child(chest)
	CharParts.add(chest, CharParts.box_mesh(Vector3(1.3, 0.7, 0.8)), CharParts.mat(EnvKit.WOOD, 0.012), Vector3(0, 0.35, 0))
	CharParts.add(chest, CharParts.cyl_mesh(0.4, 0.4, 1.3, 12), CharParts.mat(EnvKit.WOOD_LIGHT, 0.012), Vector3(0, 0.7, 0), Vector3(0, 0, 90), Vector3(1, 1, 1))
	CharParts.add(chest, CharParts.box_mesh(Vector3(0.18, 0.22, 0.05)), CharParts.mat(Color("e4b96b")), Vector3(0, 0.7, 0.42))
	var csb := EnvKit.body(chest, Vector3.ZERO, HOUSE_LAYER)
	EnvKit.add_box_shape(csb, Vector3(1.3, 1.1, 0.8), Vector3(0, 0.55, 0))
	var sprompt := func(): return "Open storage"
	var saction := func(_a):
		var u := ui()
		if u:
			u.open_storage()
	var sp := ActionPoint.new().configure("storage_chest", sprompt, saction, Callable(), 2.0, 1.4, 1)
	sp.position = Vector3(-4.2, 0, -2.4)
	house.add_child(sp)
	# Keepsake shelf on the back wall
	_hbox(Vector3(3.4, 0.12, 0.5), Vector3(-1.2, 1.3, -3.85), TRIM, Vector3.ZERO, 0.008, false)
	_hbox(Vector3(3.4, 0.12, 0.5), Vector3(-1.2, 2.2, -3.85), TRIM, Vector3.ZERO, 0.008, false)
	_anchor("anchor_keepsake_1", Vector3(-2.2, 1.36, -3.8))
	_anchor("anchor_keepsake_2", Vector3(-0.2, 1.36, -3.8))
	# Living-room anchors
	_anchor("anchor_rug", Vector3(0.0, 0.12, 0.6))
	_anchor("anchor_lamp", Vector3(-4.3, 0.12, 1.8))
	_anchor("anchor_stool", Vector3(-2.0, 0.12, 2.4))
	_anchor("anchor_basket", Vector3(2.4, 0.12, -3.4))
	_anchor("anchor_lantern", Vector3(-1.0, 0.12, 3.8))
	# A small sofa so the space reads as a living room
	_hbox(Vector3(2.6, 0.5, 0.9), Vector3(-1.2, 0.35, -2.9), Color("e77f6e"), Vector3.ZERO, 0.012)
	_hbox(Vector3(2.6, 0.7, 0.3), Vector3(-1.2, 0.8, -3.3), Color("e77f6e"), Vector3.ZERO, 0.012, false)
	# Journal desk
	var jprompt := func(): return "Read the shared journal"
	var jaction := func(_a):
		var u := ui()
		if u:
			u.open_journal()
	var jp := ActionPoint.new().configure("journal_desk", jprompt, jaction, Callable(), 1.8, 1.4)
	jp.position = Vector3(1.8, 0, 2.0)
	house.add_child(jp)
	CharParts.add(jp, CharParts.box_mesh(Vector3(1.2, 0.08, 0.7)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(0, 0.75, -0.6))
	for x in [-0.5, 0.5]:
		CharParts.add(jp, CharParts.box_mesh(Vector3(0.08, 0.75, 0.6)), CharParts.mat(TRIM), Vector3(x, 0.375, -0.6))
	CharParts.add(jp, CharParts.box_mesh(Vector3(0.5, 0.06, 0.36)), CharParts.mat(Color("f2a3c0"), 0.006), Vector3(0, 0.82, -0.6), Vector3(0, 12, 0))


func _upper_floor() -> void:
	var y := 3.2
	# Bed (rest / save)
	_hbox(Vector3(2.4, 0.45, 1.7), Vector3(1.2, y + 0.22, -3.0), Color("f3ead8"), Vector3.ZERO, 0.012)
	_hbox(Vector3(2.42, 0.12, 1.2), Vector3(1.2, y + 0.5, -2.75), Color("e77f6e"), Vector3.ZERO, 0.0, false)
	_hbox(Vector3(0.8, 0.2, 0.5), Vector3(0.6, y + 0.55, -3.6), Color("ffffff"), Vector3.ZERO, 0.008, false)
	_hbox(Vector3(0.8, 0.2, 0.5), Vector3(1.8, y + 0.55, -3.6), Color("f2a3c0"), Vector3.ZERO, 0.008, false)
	var bprompt := func(): return "Rest until morning (saves the game)"
	var baction := func(_a):
		var u := ui()
		if u:
			u.sleep_sequence()
	var bp := ActionPoint.new().configure("bed", bprompt, baction, Callable(), 2.2, 1.2, 2)
	bp.position = Vector3(1.2, y, -1.6)
	house.add_child(bp)
	# Kitchen corner
	_hbox(Vector3(2.6, 0.9, 0.8), Vector3(-3.6, y + 0.45, -3.5), Color("f3ead8"), Vector3.ZERO, 0.012)
	_hbox(Vector3(2.7, 0.08, 0.9), Vector3(-3.6, y + 0.94, -3.5), TRIM, Vector3.ZERO, 0.008, false)
	CharParts.add(house, CharParts.cyl_mesh(0.2, 0.2, 0.1, 12), CharParts.mat(Color("3b3b3b"), 0.006), Vector3(-4.3, y + 1.03, -3.5))
	_anchor("anchor_teapot", Vector3(-3.0, y + 0.98, -3.45))
	_anchor("anchor_picture", Vector3(-1.0, y, -3.95))
	_anchor("anchor_plant", Vector3(-4.4, y + 0.15, -0.1))
	_anchor("anchor_flowerpot", Vector3(-4.7, y + 1.3, -2.0))


func _anchor(id: String, local: Vector3) -> void:
	var a := DecorAnchor.new().setup(id)
	a.name = id
	a.position = local
	house.add_child(a)
