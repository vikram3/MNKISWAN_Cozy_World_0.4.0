class_name CharParts
extends RefCounted
## Procedural "soft miniature" art kit: toon materials with warm-brown ink outlines (matching the
## MNKISWAN sticker linework), cached primitive meshes and a tube builder for tails, spirals and
## hair locks. Used for the greybox-to-stylised characters and environment props.

const OUTLINE_COLOR := Color("4a2a1a")   # warm brown ink, per canon §4

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}
static var _outline_mats: Dictionary = {}

const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec4 outline_color : source_color = vec4(0.29, 0.165, 0.10, 1.0);
uniform float thickness = 0.012;
void vertex() {
	VERTEX += NORMAL * thickness;
}
void fragment() {
	ALBEDO = outline_color.rgb;
}
"""

static var _outline_shader: Shader


static func outline_material(thickness: float = 0.012) -> ShaderMaterial:
	var key := str(snappedf(thickness, 0.001))
	if _outline_mats.has(key):
		return _outline_mats[key]
	if _outline_shader == null:
		_outline_shader = Shader.new()
		_outline_shader.code = OUTLINE_SHADER
	var m := ShaderMaterial.new()
	m.shader = _outline_shader
	m.set_shader_parameter("outline_color", OUTLINE_COLOR)
	m.set_shader_parameter("thickness", thickness)
	_outline_mats[key] = m
	return m


## Toon material. `outline` > 0 adds an ink outline pass of that thickness.
static func mat(color: Color, outline: float = 0.0, emission: float = 0.0, rough: float = 0.75) -> StandardMaterial3D:
	var key := "%s|%.3f|%.2f|%.2f" % [color.to_html(), outline, emission, rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.metallic_specular = 0.22
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	# Small separate parts no longer carry thick overlapping ink shells.
	# Their geometry and soft directional light define the silhouette instead.
	_mats[key] = m
	return m


static func unshaded(color: Color) -> StandardMaterial3D:
	var key := "u|" + color.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


# --- Cached meshes ------------------------------------------------------------------------------

static func sphere_mesh(radius: float = 0.5, segs: int = 20) -> SphereMesh:
	var key := "s%.3f_%d" % [radius, segs]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = segs
		m.rings = int(segs * 0.6)
		_meshes[key] = m
	return _meshes[key]


static func cyl_mesh(top: float, bottom: float, height: float, segs: int = 16) -> CylinderMesh:
	var key := "c%.3f_%.3f_%.3f_%d" % [top, bottom, height, segs]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top
		m.bottom_radius = bottom
		m.height = height
		m.radial_segments = segs
		m.rings = 1
		_meshes[key] = m
	return _meshes[key]


static func box_mesh(size: Vector3) -> BoxMesh:
	var key := "b%s" % str(size)
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _meshes[key]


static func capsule_mesh(radius: float, height: float) -> CapsuleMesh:
	var key := "k%.3f_%.3f" % [radius, height]
	if not _meshes.has(key):
		var m := CapsuleMesh.new()
		m.radius = radius
		m.height = max(height, radius * 2.0)
		m.radial_segments = 16
		m.rings = 6
		_meshes[key] = m
	return _meshes[key]


static func torus_mesh(inner: float, outer: float, ring_segs: int = 12, segs: int = 32) -> TorusMesh:
	var key := "t%.3f_%.3f" % [inner, outer]
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.ring_segments = ring_segs
		m.rings = segs
		_meshes[key] = m
	return _meshes[key]


# --- Node helpers -------------------------------------------------------------------------------

static func add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	if node_name != "":
		mi.name = node_name
	parent.add_child(mi)
	return mi


static func sphere(parent: Node3D, r: float, color: Color, pos: Vector3, scl: Vector3 = Vector3.ONE, outline: float = 0.012, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return add(parent, sphere_mesh(r), mat(color, outline), pos, rot_deg, scl)


static func pivot(parent: Node3D, pos: Vector3, node_name: String = "") -> Node3D:
	var p := Node3D.new()
	p.position = pos
	if node_name != "":
		p.name = node_name
	parent.add_child(p)
	return p


## Builds a smooth tube along `points`, radius lerped from r0 to r1.
static func tube_mesh(points: PackedVector3Array, r0: float, r1: float, sides: int = 10) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := points.size()
	var rings: Array = []
	var ref := Vector3.UP
	for i in n:
		var t: Vector3
		if i == 0:
			t = (points[1] - points[0]).normalized()
		elif i == n - 1:
			t = (points[n - 1] - points[n - 2]).normalized()
		else:
			t = (points[i + 1] - points[i - 1]).normalized()
		var nrm: Vector3 = ref - t * ref.dot(t)
		if nrm.length() < 0.01:
			nrm = Vector3.RIGHT - t * Vector3.RIGHT.dot(t)
		nrm = nrm.normalized()
		ref = nrm
		var b := t.cross(nrm).normalized()
		var r := lerpf(r0, r1, float(i) / float(max(n - 1, 1)))
		var ring: Array = []
		for s in sides:
			var a := TAU * float(s) / float(sides)
			var dir := nrm * cos(a) + b * sin(a)
			ring.append([points[i] + dir * r, dir])
		rings.append(ring)
	for i in n - 1:
		for s in sides:
			var s2 := (s + 1) % sides
			var a0: Array = rings[i][s]
			var a1: Array = rings[i][s2]
			var b0: Array = rings[i + 1][s]
			var b1: Array = rings[i + 1][s2]
			_v(st, a0); _v(st, b0); _v(st, a1)
			_v(st, a1); _v(st, b0); _v(st, b1)
	# end caps (flat fans)
	for e in [0, n - 1]:
		var ring_e: Array = rings[e]
		var center: Vector3 = points[e]
		var tn: Vector3 = (points[1] - points[0]).normalized() if e == 0 else (points[n - 1] - points[n - 2]).normalized()
		if e == 0:
			tn = -tn
		for s in sides:
			var s2 := (s + 1) % sides
			var pa: Vector3 = ring_e[s][0]
			var pb: Vector3 = ring_e[s2][0]
			if e == 0:
				_vp(st, center, tn); _vp(st, pa, tn); _vp(st, pb, tn)
			else:
				_vp(st, center, tn); _vp(st, pb, tn); _vp(st, pa, tn)
	return st.commit()


static func _v(st: SurfaceTool, d: Array) -> void:
	st.set_normal(d[1])
	st.add_vertex(d[0])


static func _vp(st: SurfaceTool, p: Vector3, nrm: Vector3) -> void:
	st.set_normal(nrm)
	st.add_vertex(p)


static func tube(parent: Node3D, points: PackedVector3Array, r0: float, r1: float, color: Color, outline: float = 0.01, sides: int = 10) -> MeshInstance3D:
	return add(parent, tube_mesh(points, r0, r1, sides), mat(color, outline))


## Planar spiral in the XY plane (used for MNKI's golden double-spiral headband ornament).
static func spiral_points(turns: float, r_start: float, r_end: float, steps: int, clockwise: bool) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in steps + 1:
		var f := float(i) / float(steps)
		var a := f * turns * TAU
		if clockwise:
			a = -a
		var r := lerpf(r_start, r_end, f)
		pts.append(Vector3(cos(a) * r, sin(a) * r, 0.0))
	return pts


## Smooth catmull-rom resample through control points.
static func smooth(ctrl: Array, per_seg: int = 6) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n := ctrl.size()
	for i in n - 1:
		var p0: Vector3 = ctrl[max(i - 1, 0)]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[i + 1]
		var p3: Vector3 = ctrl[min(i + 2, n - 1)]
		for k in per_seg:
			var t := float(k) / float(per_seg)
			var t2 := t * t
			var t3 := t2 * t
			pts.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	pts.append(ctrl[n - 1])
	return pts
