class_name CharacterSculpt
extends RefCounted
## Contoured meshes for the hero silhouettes. Generated once, animated through rig pivots.

static func lock_mesh(control: Array, width: float, depth: float, feather: bool = false) -> ArrayMesh:
	var points := CharParts.smooth(control, 6)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var t := float(i) / float(points.size() - 1)
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := tangent.cross(Vector3.FORWARD).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		var normal := side.cross(tangent).normalized()
		var taper := pow(maxf(1.0 - t, 0.001), 0.62) * (0.72 + 0.45 * sin(t * PI))
		if feather:
			taper = pow(maxf(sin(t * PI), 0.001), 0.45)
		var ring := PackedVector3Array()
		for j in 12:
			var a := TAU * float(j) / 12.0
			ring.append(points[i] + side * cos(a) * width * taper + normal * sin(a) * depth * taper)
		rings.append(ring)
	for i in rings.size() - 1:
		for j in 12:
			var k := (j + 1) % 12
			_tri(st, rings[i][j], rings[i][k], rings[i + 1][j])
			_tri(st, rings[i][k], rings[i + 1][k], rings[i + 1][j])
	st.index()
	st.generate_normals()
	return st.commit()


static func pleated_skirt() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for row in 9:
		var t := float(row) / 8.0
		var ring := PackedVector3Array()
		for j in 96:
			var a := TAU * float(j) / 96.0
			var radius := lerpf(0.169, 0.298, t) + cos(a * 16.0) * 0.014 * t
			ring.append(Vector3(sin(a) * radius, 0.13 - t * 0.235 + sin(a * 8.0) * 0.004 * t, cos(a) * radius))
		rings.append(ring)
	for i in 8:
		for j in 96:
			var k := (j + 1) % 96
			_tri(st, rings[i][j], rings[i][k], rings[i + 1][j])
			_tri(st, rings[i][k], rings[i + 1][k], rings[i + 1][j])
	st.index()
	st.generate_normals()
	return st.commit()


static func hood_shell() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for row in 25:
		var theta := lerpf(0.01, 2.12, float(row) / 24.0)
		var ring := PackedVector3Array()
		for j in 48:
			var a := TAU * float(j) / 48.0
			ring.append(Vector3(sin(a) * sin(theta) * 0.335, cos(a) * sin(theta) * 0.35, -cos(theta) * 0.335))
		rings.append(ring)
	for i in 24:
		for j in 48:
			var k := (j + 1) % 48
			_tri(st, rings[i][j], rings[i][k], rings[i + 1][j])
			_tri(st, rings[i][k], rings[i + 1][k], rings[i + 1][j])
	st.index()
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func clothing_details(model: CharModel, white: Color, skin: Color, cuff: Color) -> void:
	for side in [-1, 1]:
		var arm := model.arm_l if side > 0 else model.arm_r
		CharParts.sphere(arm, 0.023, skin, Vector3(-0.025 * side, -0.277, 0.036), Vector3(0.75, 1.2, 0.85), 0)
		CharParts.add(arm, CharParts.cyl_mesh(0.057, 0.057, 0.034, 24), CharParts.mat(cuff), Vector3(0.016 * side, -0.252, 0))
		var leg := model.leg_l if side > 0 else model.leg_r
		for i in 3:
			for crossing in [-1.0, 1.0]:
				var lace := PackedVector3Array()
				for k in 9:
					var t := float(k) / 8.0
					var x: float = lerpf(-0.035, 0.035, t) * crossing
					var z := 0.04 + i * 0.03 + t * 0.02
					var y := -0.345 + 0.075 * sqrt(maxf(0.0, 1.0 - pow(x / 0.1, 2) - pow((z - 0.035) / 0.16, 2))) + 0.006
					lace.append(Vector3(x, y, z))
				CharParts.tube(leg, lace, 0.0035, 0.0035, white, 0, 6)
