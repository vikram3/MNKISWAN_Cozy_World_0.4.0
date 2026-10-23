class_name EnvKit
extends RefCounted
## Modular miniature-diorama environment kit (GDD §13, Appendix A): trees, shrubs, rocks, fences,
## paths, water, tree homes, benches, lanterns and signs. All props get simple collision proxies
## (never render meshes as collision) on physics layer 1 "world".

const WOOD := Color("8b6749")
const WOOD_DARK := Color("6e4f37")
const WOOD_LIGHT := Color("b58a60")
const LEAF := Color("5fa35a")
const LEAF_LIGHT := Color("8cc96b")
const LEAF_DARK := Color("3f7d48")
const STONE := Color("a7adb0")
const STONE_DARK := Color("868d91")
const PATH := Color("e3cfa3")
const ROOF_RED := Color("c95c4a")
const CREAM := Color("fbf7ed")
const TEAL := Color("78c9d4")

static var _water_mat: ShaderMaterial
static var _ground_mat: ShaderMaterial
static var _fall_mat: ShaderMaterial
static var _path_mat: ShaderMaterial

static func path_material() -> ShaderMaterial:
	if _path_mat == null:
		var shader := Shader.new()
		shader.code = """
shader_type spatial;
render_mode specular_disabled;
void fragment() {
    vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float grain = fract(sin(dot(floor(w.xz * 16.0), vec2(12.9898, 78.233))) * 43758.5453);
    float patches = sin(w.x * 2.1) * sin(w.z * 1.7) * 0.025;
    ALBEDO = vec3(0.51, 0.40, 0.25) + vec3(grain * 0.045 + patches);
    ROUGHNESS = 1.0;
}
"""
		_path_mat = ShaderMaterial.new()
		_path_mat.shader = shader
	return _path_mat

const WATER_SHADER := """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform vec4 deep : source_color = vec4(0.30, 0.66, 0.74, 1.0);
uniform vec4 shallow : source_color = vec4(0.55, 0.84, 0.86, 1.0);
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 0.6;
	float rip = sin(w.x * 1.7 + t) * sin(w.z * 1.3 - t * 1.2) + sin((w.x + w.z) * 3.1 + t * 2.0) * 0.4;
	float hl = smoothstep(0.82, 1.0, rip);
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.5 + rip * 0.25) + vec3(hl * 0.35);
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
"""

const FALL_SHADER := """
shader_type spatial;
render_mode cull_disabled, unshaded;
uniform vec4 col : source_color = vec4(0.62, 0.88, 0.92, 1.0);
void fragment() {
	float s = fract(UV.y * 6.0 + TIME * 1.8 + sin(UV.x * 20.0) * 0.15);
	float streak = smoothstep(0.0, 0.25, s) * (1.0 - smoothstep(0.55, 1.0, s));
	ALBEDO = mix(col.rgb, vec3(1.0), streak * 0.55 + (sin(UV.x * 40.0) * 0.5 + 0.5) * 0.08);
}
"""

const GROUND_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 a : source_color = vec4(0.38, 0.52, 0.27, 1.0);
uniform vec4 b : source_color = vec4(0.29, 0.43, 0.23, 1.0);
uniform vec4 c : source_color = vec4(0.48, 0.62, 0.35, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = noise(w.xz * 0.08) * 0.6 + noise(w.xz * 0.35) * 0.4;
	vec3 col = mix(b.rgb, a.rgb, smoothstep(0.3, 0.7, n));
	col = mix(col, c.rgb, smoothstep(0.75, 0.95, noise(w.xz * 0.5 + 7.0)) * 0.6);
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""


static func water_material() -> ShaderMaterial:
	if _water_mat == null:
		var sh := Shader.new()
		sh.code = WATER_SHADER
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = sh
	return _water_mat


static func waterfall_material() -> ShaderMaterial:
	if _fall_mat == null:
		var sh := Shader.new()
		sh.code = FALL_SHADER
		_fall_mat = ShaderMaterial.new()
		_fall_mat.shader = sh
	return _fall_mat


static func ground_material() -> ShaderMaterial:
	if _ground_mat == null:
		var sh := Shader.new()
		sh.code = GROUND_SHADER
		_ground_mat = ShaderMaterial.new()
		_ground_mat.shader = sh
	return _ground_mat


# --- Collision helpers --------------------------------------------------------------------------

static func body(parent: Node3D, pos: Vector3 = Vector3.ZERO, layer: int = 1) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	sb.position = pos
	parent.add_child(sb)
	return sb


static func add_box_shape(sb: CollisionObject3D, size: Vector3, pos: Vector3 = Vector3.ZERO, rot_y: float = 0.0) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	cs.rotation.y = rot_y
	sb.add_child(cs)
	return cs


static func add_cyl_shape(sb: CollisionObject3D, radius: float, height: float, pos: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	cs.shape = c
	cs.position = pos
	sb.add_child(cs)
	return cs


## Visible box with matching collision.
static func solid_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_y_deg: float = 0.0, outline: float = 0.0) -> StaticBody3D:
	var sb := body(parent, pos)
	sb.rotation_degrees.y = rot_y_deg
	CharParts.add(sb, CharParts.box_mesh(size), CharParts.mat(color, outline))
	add_box_shape(sb, size)
	return sb


static func invisible_wall(parent: Node3D, size: Vector3, pos: Vector3, rot_y_deg: float = 0.0) -> StaticBody3D:
	var sb := body(parent, pos)
	sb.rotation_degrees.y = rot_y_deg
	add_box_shape(sb, size)
	return sb


# --- Vegetation ---------------------------------------------------------------------------------

static func tree(parent: Node3D, pos: Vector3, s: float = 1.0, leaf: Color = LEAF, kind: String = "round") -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	match kind:
		"palm":
			var pts: Array = []
			for i in 6:
				var f := float(i) / 5.0
				pts.append(Vector3(sin(f * 1.4) * 0.6 * s, f * 4.2 * s, 0.0))
			CharParts.add(root, CharParts.tube_mesh(CharParts.smooth(pts, 3), 0.18 * s, 0.12 * s, 8), CharParts.mat(Color("9b7a52"), 0.012))
			var top: Vector3 = pts[5]
			for i in 7:
				var a := TAU * float(i) / 7.0
				var leafm := CharParts.add(root, CharParts.sphere_mesh(0.5, 10), CharParts.mat(Color("4f9e45"), 0.01), top + Vector3(cos(a), -0.25, sin(a)) * 0.8 * s)
				leafm.basis = Basis.from_euler(Vector3(0, -a, 0.5)) * Basis.from_scale(Vector3(1.8 * s, 0.12 * s, 0.45 * s))
		"banana":
			CharParts.add(root, CharParts.cyl_mesh(0.12 * s, 0.18 * s, 1.6 * s, 10), CharParts.mat(Color("7fa35a"), 0.01), Vector3(0, 0.8 * s, 0))
			for i in 6:
				var a := TAU * float(i) / 6.0 + 0.3
				var lf := CharParts.add(root, CharParts.sphere_mesh(0.5, 10), CharParts.mat(Color("6dbb4f"), 0.01), Vector3(cos(a) * 0.7, 1.75, sin(a) * 0.7) * s)
				lf.basis = Basis.from_euler(Vector3(0, -a, 0.6)) * Basis.from_scale(Vector3(1.6 * s, 0.1 * s, 0.6 * s))
		"pine":
			CharParts.add(root, CharParts.cyl_mesh(0.15 * s, 0.22 * s, 1.2 * s, 8), CharParts.mat(WOOD_DARK, 0.01), Vector3(0, 0.6 * s, 0))
			for i in 3:
				CharParts.add(root, CharParts.cyl_mesh(0.0, (1.3 - i * 0.3) * s, 1.4 * s, 10), CharParts.mat(LEAF_DARK, 0.012), Vector3(0, (1.6 + i * 0.75) * s, 0))
		_:
			CharParts.add(root, CharParts.cyl_mesh(0.2 * s, 0.32 * s, 2.2 * s, 10), CharParts.mat(WOOD, 0.012), Vector3(0, 1.1 * s, 0))
			# root flares
			for i in 4:
				var a := TAU * float(i) / 4.0 + rng.randf()
				var rf := CharParts.add(root, CharParts.sphere_mesh(0.5, 8), CharParts.mat(WOOD, 0.01), Vector3(cos(a) * 0.3, 0.08, sin(a) * 0.3) * s)
				rf.basis = Basis.from_euler(Vector3(0, -a, 0)) * Basis.from_scale(Vector3(0.6 * s, 0.25 * s, 0.25 * s))
			var light := leaf.lightened(0.18)
			for i in 6:
				var off := Vector3(rng.randf_range(-0.9, 0.9), rng.randf_range(-0.2, 0.7), rng.randf_range(-0.9, 0.9)) * s
				var r := rng.randf_range(0.7, 1.05) * s
				CharParts.add(root, CharParts.sphere_mesh(r, 14), CharParts.mat(leaf if i % 3 else light, 0.014), Vector3(0, 2.7 * s, 0) + off)
	var sb := body(root)
	add_cyl_shape(sb, 0.28 * s, 3.0 * s, Vector3(0, 1.5 * s, 0))
	return root


static func bush(parent: Node3D, pos: Vector3, s: float = 1.0, color: Color = LEAF, solid: bool = false) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos) + 3
	for i in 4:
		var off := Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0.0, 0.2), rng.randf_range(-0.35, 0.35)) * s
		CharParts.add(root, CharParts.sphere_mesh(rng.randf_range(0.35, 0.5) * s, 12), CharParts.mat(color if i % 2 else color.lightened(0.12), 0.012), Vector3(0, 0.35 * s, 0) + off)
	if solid:
		var sb := body(root)
		add_cyl_shape(sb, 0.55 * s, 1.0, Vector3(0, 0.5, 0))
	return root


static func rock(parent: Node3D, pos: Vector3, s: float = 1.0, solid: bool = true) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos) + 9
	var m := CharParts.add(root, CharParts.sphere_mesh(0.6 * s, 9), CharParts.mat(STONE if rng.randf() < 0.6 else STONE_DARK, 0.014), Vector3(0, 0.25 * s, 0))
	m.scale = Vector3(rng.randf_range(0.9, 1.4), rng.randf_range(0.6, 0.9), rng.randf_range(0.9, 1.3))
	m.rotation.y = rng.randf() * TAU
	CharParts.add(root, CharParts.sphere_mesh(0.3 * s, 8), CharParts.mat(Color("7fae6a"), 0.0), Vector3(0.1, 0.55 * s * m.scale.y, 0.05), Vector3.ZERO, Vector3(1.4, 0.3, 1.2))
	if solid:
		var sb := body(root)
		add_cyl_shape(sb, 0.6 * s * maxf(m.scale.x, m.scale.z), 1.0 * s, Vector3(0, 0.4 * s, 0))
	return root


static func flowers(parent: Node3D, center: Vector3, count: int, radius: float, colors: Array, seed_val: int = 1) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.13
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = count
	for i in count:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * radius
		var t := Transform3D(Basis.IDENTITY, center + Vector3(cos(a) * d, 0.22 + rng.randf() * 0.1, sin(a) * d))
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, colors[rng.randi() % colors.size()])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	# stems
	return mmi


static func grass_tufts(parent: Node3D, area_min: Vector2, area_max: Vector2, count: int, seed_val: int, avoid: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.07
	cm.height = 0.32
	cm.radial_segments = 5
	mm.mesh = cm
	var xs: Array = []
	for i in count:
		var p := Vector3(rng.randf_range(area_min.x, area_max.x), 0.14, rng.randf_range(area_min.y, area_max.y))
		if avoid.is_valid() and avoid.call(p):
			continue
		xs.append(p)
	mm.instance_count = xs.size()
	for i in xs.size():
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
		b = b.scaled(Vector3.ONE * rng.randf_range(0.7, 1.4))
		mm.set_instance_transform(i, Transform3D(b, xs[i]))
		mm.set_instance_color(i, Color("6fae55").lerp(Color("a3d36f"), rng.randf()))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


## Dense border forest drawn with two MultiMeshes (trunks + canopy) and one collision body.
static func forest_band(parent: Node3D, positions: Array, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = CharParts.cyl_mesh(0.22, 0.34, 2.4, 8)
	trunk_mm.instance_count = positions.size()
	var can_mm := MultiMesh.new()
	can_mm.transform_format = MultiMesh.TRANSFORM_3D
	can_mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 7
	can_mm.mesh = sm
	can_mm.instance_count = positions.size() * 3
	var sb := body(parent)
	for i in positions.size():
		var p: Vector3 = positions[i]
		var s := rng.randf_range(0.9, 1.6)
		trunk_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), p + Vector3(0, 1.2 * s, 0)))
		for k in 3:
			var off := Vector3(rng.randf_range(-0.8, 0.8), 2.6 + k * 0.5 + rng.randf_range(0, 0.4), rng.randf_range(-0.8, 0.8)) * s
			var r := rng.randf_range(0.9, 1.3) * s
			can_mm.set_instance_transform(i * 3 + k, Transform3D(Basis.IDENTITY.scaled(Vector3(r, r * 0.9, r)), p + off))
			var base := Color("477a51").lerp(Color("7fa56a"), rng.randf())
			can_mm.set_instance_color(i * 3 + k, base)
		add_cyl_shape(sb, 0.45 * s, 3.0, p + Vector3(0, 1.5, 0))
	var tmi := MultiMeshInstance3D.new()
	tmi.multimesh = trunk_mm
	tmi.material_override = CharParts.mat(WOOD)
	parent.add_child(tmi)
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = can_mm
	var cmat := StandardMaterial3D.new()
	cmat.vertex_color_use_as_albedo = true
	cmat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	cmat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	cmi.material_override = cmat
	parent.add_child(cmi)


# --- Built props --------------------------------------------------------------------------------

static func path_segment(parent: Node3D, a: Vector3, b: Vector3, width: float = 3.0) -> void:
	var d := b - a
	d.y = 0
	var length := d.length()
	if length < 0.1:
		return
	var mid := (a + b) * 0.5
	var mi := CharParts.add(parent, CharParts.box_mesh(Vector3(width, 0.04, length + width * 0.6)), path_material(), Vector3(mid.x, 0.02, mid.z))
	mi.rotation.y = atan2(d.x, d.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# stepping stones along the edges for a crafted look
	var n := int(length / 2.2)
	var side := Vector3(-d.z, 0, d.x).normalized()
	for i in n:
		var p := a + d * (float(i) + 0.5) / float(max(n, 1))
		var s2: float = 1.0 if i % 2 == 0 else -1.0
		var st := CharParts.add(parent, CharParts.cyl_mesh(0.22, 0.25, 0.08, 8), CharParts.mat(Color("d5bf8f")), p + side * (width * 0.5 + 0.1) * s2 + Vector3(0, 0.03, 0))
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func disc(parent: Node3D, pos: Vector3, radius: float, color: Color, h: float = 0.05) -> MeshInstance3D:
	var mi := CharParts.add(parent, CharParts.cyl_mesh(radius, radius, h, 32), CharParts.mat(color), pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Pond with stone rim and a collision ring that keeps the player on the bank.
static func pond(parent: Node3D, pos: Vector3, radius: float, walls: bool = true) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	CharParts.add(root, CharParts.cyl_mesh(radius + 0.35, radius + 0.45, 0.12, 36), CharParts.mat(Color("cdbf9a")), Vector3(0, 0.03, 0))
	var w := CharParts.add(root, CharParts.cyl_mesh(radius, radius, 0.06, 40), water_material(), Vector3(0, 0.08, 0))
	w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	var stones := int(radius * 3.0)
	for i in stones:
		var a := TAU * float(i) / float(stones) + rng.randf() * 0.2
		var st := CharParts.add(root, CharParts.sphere_mesh(0.28, 8), CharParts.mat(STONE if i % 3 else STONE_DARK, 0.01), Vector3(cos(a) * (radius + 0.25), 0.1, sin(a) * (radius + 0.25)))
		st.scale = Vector3(1.2, 0.55, 1.0)
	for i in int(radius * 1.5):
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.3, radius - 0.6)
		CharParts.add(root, CharParts.cyl_mesh(0.3, 0.3, 0.02, 12), CharParts.mat(Color("6fb35e")), Vector3(cos(a) * d, 0.13, sin(a) * d))
		if i % 3 == 0:
			CharParts.sphere(root, 0.08, Color("f5b8d0"), Vector3(cos(a) * d, 0.18, sin(a) * d), Vector3(1, 0.6, 1), 0.006)
	if walls:
		var sb := body(root)
		add_cyl_shape(sb, radius - 0.2, 2.0, Vector3(0, 1.0, 0))
	return root


static func fence(parent: Node3D, a: Vector3, b: Vector3, solid: bool = true) -> void:
	var d := b - a
	var length := d.length()
	var n := int(length / 1.2) + 1
	for i in n + 1:
		var p := a + d * float(i) / float(n)
		CharParts.add(parent, CharParts.cyl_mesh(0.07, 0.08, 0.9, 6), CharParts.mat(WOOD_LIGHT, 0.008), p + Vector3(0, 0.45, 0))
	for h in [0.35, 0.7]:
		var rail := CharParts.add(parent, CharParts.box_mesh(Vector3(0.06, 0.08, length)), CharParts.mat(WOOD_LIGHT, 0.008), (a + b) * 0.5 + Vector3(0, h, 0))
		rail.rotation.y = atan2(d.x, d.z)
	if solid:
		var sb := body(parent, (a + b) * 0.5)
		add_box_shape(sb, Vector3(0.25, 1.4, length), Vector3(0, 0.7, 0), atan2(d.x, d.z))


static func bench(parent: Node3D, pos: Vector3, rot_y_deg: float) -> void:
	var root := body(parent, pos)
	root.rotation_degrees.y = rot_y_deg
	CharParts.add(root, CharParts.box_mesh(Vector3(1.6, 0.08, 0.45)), CharParts.mat(WOOD_LIGHT, 0.01), Vector3(0, 0.45, 0))
	CharParts.add(root, CharParts.box_mesh(Vector3(1.6, 0.35, 0.07)), CharParts.mat(WOOD_LIGHT, 0.01), Vector3(0, 0.7, -0.2))
	for x in [-0.65, 0.65]:
		CharParts.add(root, CharParts.box_mesh(Vector3(0.08, 0.45, 0.4)), CharParts.mat(WOOD, 0.01), Vector3(x, 0.22, 0))
	add_box_shape(root, Vector3(1.6, 0.9, 0.5), Vector3(0, 0.45, 0))


static func lantern_post(parent: Node3D, pos: Vector3, with_light: bool = false) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	CharParts.add(root, CharParts.cyl_mesh(0.06, 0.08, 2.0, 6), CharParts.mat(WOOD_DARK, 0.01), Vector3(0, 1.0, 0))
	CharParts.add(root, CharParts.box_mesh(Vector3(0.5, 0.06, 0.06)), CharParts.mat(WOOD_DARK, 0.008), Vector3(0.2, 1.95, 0))
	var lamp := CharParts.sphere(root, 0.16, Color("ffd88a"), Vector3(0.38, 1.72, 0), Vector3(1, 1.25, 1), 0.008)
	lamp.material_override = CharParts.mat(Color("ffd88a"), 0.008, 1.6)
	lamp.add_to_group("night_lamp")
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = Color("ffcf7a")
		l.omni_range = 6.0
		l.light_energy = 0.0
		l.position = Vector3(0.38, 1.6, 0)
		l.add_to_group("night_light")
		root.add_child(l)
	var sb := body(root)
	add_cyl_shape(sb, 0.12, 2.0, Vector3(0, 1.0, 0))
	return root


static func sign_post(parent: Node3D, pos: Vector3, text: String, rot_y_deg: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	CharParts.add(root, CharParts.cyl_mesh(0.06, 0.07, 1.4, 6), CharParts.mat(WOOD_DARK, 0.01), Vector3(0, 0.7, 0))
	CharParts.add(root, CharParts.box_mesh(Vector3(1.5, 0.45, 0.08)), CharParts.mat(WOOD_LIGHT, 0.01), Vector3(0, 1.3, 0))
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 40
	lbl.outline_size = 0
	lbl.modulate = Color("3b2a1e")
	lbl.pixel_size = 0.004
	lbl.position = Vector3(0, 1.3, 0.05)
	lbl.width = 340
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.double_sided = false
	root.add_child(lbl)
	var lbl2 := lbl.duplicate() as Label3D
	lbl2.position = Vector3(0, 1.3, -0.05)
	lbl2.rotation_degrees.y = 180
	root.add_child(lbl2)
	var sb := body(root)
	add_cyl_shape(sb, 0.1, 1.4, Vector3(0, 0.7, 0))
	return root


## A cosy hut on a short trunk platform (tree-people home). Front faces +Z.
static func tree_home(parent: Node3D, pos: Vector3, rot_y_deg: float, wall: Color, roof: Color, tall: bool = false) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	root.add_to_group("village_home")
	var lift := 2.2 if tall else 0.0
	if tall:
		CharParts.add(root, CharParts.cyl_mesh(0.9, 1.2, lift + 0.4, 12), CharParts.mat(WOOD, 0.014), Vector3(0, (lift + 0.4) * 0.5, 0))
		CharParts.add(root, CharParts.cyl_mesh(2.0, 2.0, 0.2, 16), CharParts.mat(WOOD_LIGHT, 0.012), Vector3(0, lift + 0.1, 0))
		# ladder
		for i in 7:
			CharParts.add(root, CharParts.box_mesh(Vector3(0.7, 0.06, 0.08)), CharParts.mat(WOOD_LIGHT, 0.008), Vector3(0, 0.3 + i * 0.32, 2.05))
		for x in [-0.35, 0.35]:
			CharParts.add(root, CharParts.box_mesh(Vector3(0.07, lift + 0.4, 0.07)), CharParts.mat(WOOD_DARK, 0.008), Vector3(x, (lift + 0.4) * 0.5, 2.05))
	var hut_y := lift + 0.2
	CharParts.add(root, CharParts.cyl_mesh(1.35, 1.45, 2.0, 14), CharParts.mat(wall, 0.014), Vector3(0, hut_y + 1.0, 0))
	CharParts.add(root, CharParts.cyl_mesh(0.0, 2.0, 1.6, 14), CharParts.mat(roof, 0.016), Vector3(0, hut_y + 2.75, 0))
	CharParts.sphere(root, 0.18, roof.lightened(0.2), Vector3(0, hut_y + 3.6, 0), Vector3.ONE, 0.01)
	# round door + window
	CharParts.add(root, CharParts.cyl_mesh(0.42, 0.42, 0.08, 16), CharParts.mat(WOOD_DARK, 0.01), Vector3(0, hut_y + 0.75, 1.42), Vector3(90, 0, 0), Vector3(1, 1, 1.5))
	CharParts.sphere(root, 0.04, Color("e4b96b"), Vector3(0.22, hut_y + 0.7, 1.48), Vector3.ONE, 0.0)
	var win := CharParts.add(root, CharParts.cyl_mesh(0.25, 0.25, 0.06, 12), CharParts.mat(Color("ffe3a3"), 0.01, 0.4), Vector3(0.85, hut_y + 1.35, 1.12), Vector3(90, 0, 0))
	win.rotation.y = 0.65
	win.add_to_group("night_lamp")
	# hanging lantern
	var lan := CharParts.sphere(root, 0.12, Color("ffd88a"), Vector3(-0.9, hut_y + 1.7, 1.3), Vector3(1, 1.3, 1), 0.008)
	lan.material_override = CharParts.mat(Color("ffd88a"), 0.008, 1.5)
	lan.add_to_group("night_lamp")
	var sb := body(root)
	if tall:
		add_cyl_shape(sb, 1.25, lift + 0.4, Vector3(0, (lift + 0.4) * 0.5, 0))
	add_cyl_shape(sb, 1.45, 2.4, Vector3(0, hut_y + 1.2, 0))
	return root


static func crate(parent: Node3D, pos: Vector3, fill: Color = Color(0, 0, 0, 0), solid: bool = true, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	parent.add_child(root)
	CharParts.add(root, CharParts.box_mesh(Vector3(0.7, 0.45, 0.5)), CharParts.mat(WOOD_LIGHT, 0.01), Vector3(0, 0.225, 0))
	for z in [-0.255, 0.255]:
		CharParts.add(root, CharParts.box_mesh(Vector3(0.72, 0.06, 0.02)), CharParts.mat(WOOD, 0.0), Vector3(0, 0.3, z))
	if fill.a > 0.0:
		for i in 6:
			CharParts.sphere(root, 0.1, fill, Vector3(-0.2 + (i % 3) * 0.2, 0.47, -0.1 + (i / 3) * 0.2), Vector3.ONE, 0.006)
	if solid:
		var sb := body(root)
		add_box_shape(sb, Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0))
	return root


static func label3d(parent: Node3D, text: String, pos: Vector3, size: int = 64, color: Color = Color("3b2a1e"), billboard: bool = false) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = color
	l.outline_modulate = Color(1, 1, 1, 0.9)
	l.outline_size = 10
	l.position = pos
	l.double_sided = billboard
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l
