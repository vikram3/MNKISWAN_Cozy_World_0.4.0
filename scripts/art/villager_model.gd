class_name VillagerModel
extends CharModel
## Generic chibi villager built from NpcDB colours. Deliberately simpler than Mnki/Swan so the
## duo remains the visual focus (GDD §6). Hats give each villager a readable silhouette.

var def: Dictionary = {}
var _daily_props: Dictionary = {}


func setup(d: Dictionary) -> VillagerModel:
	def = d
	return self


func _ready() -> void:
	build()


func build() -> void:
	var ol := SKIN_LINE
	var skin := Color(String(def.get("skin", "#e0b08a")))
	var hair := Color(String(def.get("hair", "#3a2a22")))
	var top := Color(String(def.get("top", "#6fa35a")))
	var bottom := Color(String(def.get("bottom", "#6b4e36")))
	var accent := Color(String(def.get("accent", "#e4b96b")))
	var sc := float(def.get("scale", 1.0))
	scale = Vector3.ONE * sc
	hips = CharParts.pivot(body, Vector3(0, 0.43, 0), "Hips")
	torso = CharParts.pivot(body, Vector3(0, 0.43, 0), "Torso")
	for side in [1.0, -1.0]:
		var leg := CharParts.pivot(hips, Vector3(0.09 * side, 0, 0))
		CharParts.add(leg, CharParts.cyl_mesh(0.075, 0.08, 0.3, 12), CharParts.mat(bottom, ol), Vector3(0, -0.15, 0))
		CharParts.add(leg, CharParts.sphere_mesh(1.0, 14), CharParts.mat(Color("5a4032"), ol), Vector3(0, -0.37, 0.03), Vector3.ZERO, Vector3(0.09, 0.06, 0.14))
		if side > 0: leg_l = leg
		else: leg_r = leg
	CharParts.add(torso, CharParts.sphere_mesh(0.19, 20), CharParts.mat(top, ol), Vector3(0, 0.17, 0), Vector3.ZERO, Vector3(1.05, 1.0, 0.85))
	CharParts.add(torso, CharParts.cyl_mesh(0.17, 0.18, 0.05, 16), CharParts.mat(bottom, ol), Vector3(0, 0.02, 0))
	CharParts.sphere(torso, 0.035, accent, Vector3(0, 0.22, 0.155), Vector3(1, 1, 0.5), 0.006)
	for side in [1.0, -1.0]:
		var arm := CharParts.pivot(torso, Vector3(0.19 * side, 0.29, 0))
		CharParts.add(arm, CharParts.capsule_mesh(0.06, 0.28), CharParts.mat(top, ol), Vector3(0.012 * side, -0.12, 0))
		CharParts.sphere(arm, 0.052, skin, Vector3(0.015 * side, -0.28, 0), Vector3.ONE, ol)
		if side > 0: arm_l = arm
		else: arm_r = arm
	head = CharParts.pivot(torso, Vector3(0, 0.36, 0), "Head")
	var hc := CharParts.pivot(head, Vector3(0, 0.25, 0))
	var r := 0.27
	CharParts.add(hc, CharParts.sphere_mesh(r, 24), CharParts.mat(skin, ol), Vector3.ZERO, Vector3.ZERO, Vector3(1.03, 0.97, 1.0))
	build_face(hc, r, -0.03, 0.1, 0.05, 0.065, Color("5a3a22"), Color(0.95, 0.6, 0.55, 0.7), -0.13)
	CharParts.add(hc, CharParts.sphere_mesh(0.29, 20), CharParts.mat(hair, ol), Vector3(0, 0.07, -0.07), Vector3.ZERO, Vector3(1.06, 0.95, 1.0))
	for i in 5:
		var x := -0.16 + i * 0.08
		var b := CharParts.add(hc, CharParts.sphere_mesh(0.5, 10), CharParts.mat(hair, 0.01), Vector3(x, 0.13, surface_z(0.28, x, 0.13) - 0.03))
		b.basis = Basis.from_euler(Vector3(-0.4, atan2(x, 0.25), 0)) * Basis.from_scale(Vector3(0.1, 0.12, 0.05))
	if def.get("age", "") == "elder" or def.get("name", "") == "Elder Maple":
		for side in [-1, 1]:
			CharParts.add(hc, CharParts.torus_mesh(0.062, 0.07, 6, 18), CharParts.mat(Color("936a42")), Vector3(side * 0.1, -0.03, 0.255), Vector3(90, 0, 0))
		CharParts.add(hc, CharParts.box_mesh(Vector3(0.06, 0.012, 0.012)), CharParts.mat(Color("936a42")), Vector3(0, -0.03, 0.265))
	if def.get("age", "") == "child":
		head.scale = Vector3.ONE * 1.12
	_build_hat(hc, String(def.get("hat", "none")), accent)
	var book := Node3D.new()
	arm_l.add_child(book)
	book.position = Vector3(-0.06, -0.26, 0.03)
	CharParts.add(book, CharParts.box_mesh(Vector3(0.23, 0.035, 0.18)), CharParts.mat(Color("7c8d82")), Vector3.ZERO)
	CharParts.add(book, CharParts.box_mesh(Vector3(0.2, 0.012, 0.16)), CharParts.mat(Color("f6e6c9")), Vector3(0, 0.025, 0))
	_daily_props.read = book
	var tool := Node3D.new()
	arm_r.add_child(tool)
	tool.position = Vector3(0, -0.27, 0)
	CharParts.add(tool, CharParts.cyl_mesh(0.018, 0.018, 0.65, 6), CharParts.mat(EnvKit.WOOD), Vector3(0, -0.1, 0))
	CharParts.add(tool, CharParts.box_mesh(Vector3(0.16, 0.025, 0.08)), CharParts.mat(Color("839296")), Vector3(0, -0.43, 0.025))
	_daily_props.farm = tool
	var bowl := Node3D.new()
	arm_l.add_child(bowl)
	bowl.position = Vector3(0, -0.27, 0.03)
	CharParts.add(bowl, CharParts.cyl_mesh(0.09, 0.05, 0.07, 12), CharParts.mat(Color("e7c493")), Vector3.ZERO)
	_daily_props.eat = bowl
	for prop in _daily_props.values(): prop.hide()

func _process(delta: float) -> void:
	super._process(delta)
	for key in _daily_props: _daily_props[key].visible = action == key



func _build_hat(hc: Node3D, hat: String, accent: Color) -> void:
	var ol := 0.01
	match hat:
		"straw":
			CharParts.add(hc, CharParts.cyl_mesh(0.42, 0.42, 0.03, 24), CharParts.mat(Color("e8cd7a"), ol), Vector3(0, 0.22, -0.02), Vector3(-6, 0, 0))
			CharParts.add(hc, CharParts.cyl_mesh(0.2, 0.24, 0.14, 20), CharParts.mat(Color("e8cd7a"), ol), Vector3(0, 0.3, -0.03), Vector3(-6, 0, 0))
			CharParts.add(hc, CharParts.cyl_mesh(0.245, 0.245, 0.04, 20), CharParts.mat(Color("c0533f")), Vector3(0, 0.25, -0.03), Vector3(-6, 0, 0))
		"sunhat":
			CharParts.add(hc, CharParts.cyl_mesh(0.46, 0.46, 0.025, 24), CharParts.mat(Color("f6e7c8"), ol), Vector3(0, 0.22, -0.02), Vector3(-10, 0, 0))
			CharParts.sphere(hc, 0.22, Color("f6e7c8"), Vector3(0, 0.25, -0.04), Vector3(1, 0.6, 1), ol)
			CharParts.sphere(hc, 0.05, accent, Vector3(0.2, 0.3, 0.05), Vector3.ONE, 0.006)
		"beret":
			CharParts.sphere(hc, 0.24, accent, Vector3(0.04, 0.24, -0.04), Vector3(1.15, 0.45, 1.1), ol)
		"conical":
			CharParts.add(hc, CharParts.cyl_mesh(0.0, 0.48, 0.24, 24), CharParts.mat(Color("e2c785"), ol), Vector3(0, 0.33, -0.02))
		"bucket":
			CharParts.add(hc, CharParts.cyl_mesh(0.22, 0.32, 0.18, 20), CharParts.mat(accent, ol), Vector3(0, 0.25, -0.03), Vector3(-5, 0, 0))
		"bandana":
			CharParts.sphere(hc, 0.3, accent, Vector3(0, 0.1, -0.05), Vector3(1.04, 0.75, 1.04), ol)
			CharParts.sphere(hc, 0.06, accent, Vector3(0.0, 0.05, -0.32), Vector3(1.2, 0.8, 0.7), ol)
		"scarf":
			CharParts.add(hc, CharParts.torus_mesh(0.16, 0.24, 10, 24), CharParts.mat(accent, ol), Vector3(0, -0.28, 0))
		_:
			pass
