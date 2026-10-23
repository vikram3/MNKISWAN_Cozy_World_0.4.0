extends RegionBase
## 02 Waterfall, Bridge and Ponds — cool teal water, wet stone, lily pads, timber bridge, fishing.


func build() -> void:
	# Cliff + waterfall landmark (visible from the approach)
	# Staggered rock columns replace the rectangular wall while retaining a simple solid core.
	EnvKit.invisible_wall(self, Vector3(30, 4.0, 4), Vector3(0, 2.0, -13))
	for i in 13:
		var x := -14.0 + i * 2.3
		var height := 5.2 + sin(i * 1.7) * 0.6 + (2.0 if absf(x - 3.0) < 4.0 else 0.0)
		var stone := Color("7c918b").lightened(float(i % 3) * 0.035)
		EnvKit.invisible_wall(self, Vector3(2.3, height, 2.5), Vector3(x, height * 0.5, -12.5))
		CharParts.add(self, CharParts.cyl_mesh(1.3, 1.8, height, 7), CharParts.mat(stone), Vector3(x, height * 0.5, -12.5), Vector3(0, i * 23, 0), Vector3(1.0, 1.0, 1.5))
		CharParts.add(self, CharParts.sphere_mesh(1.0, 10), CharParts.mat(Color("739271")), Vector3(x, height - 0.1, -12.6), Vector3.ZERO, Vector3(1.45, 0.35, 1.9))
		if i % 2 == 0:
			EnvKit.rock(self, Vector3(x, height - 0.2, -12.8), 0.9, false)
			EnvKit.bush(self, Vector3(x, height + 0.2, -13.2), 0.9, Color("5a9e55"))
	var fall := CharParts.add(self, QuadMesh.new(), EnvKit.waterfall_material(), Vector3(3, 3.6, -10.95))
	(fall.mesh as QuadMesh).size = Vector2(4.0, 7.2)
	fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 6:
		CharParts.sphere(self, 0.45, Color("eef9fb"), Vector3(1.4 + i * 0.65, 0.25, -10.3), Vector3(1, 0.6, 1), 0.0)
	var mist := CPUParticles3D.new()
	mist.position = Vector3(3, 0.4, -10.2)
	mist.amount = 24
	mist.lifetime = 1.6
	mist.direction = Vector3(0, 1, 1)
	mist.spread = 40
	mist.initial_velocity_min = 0.6
	mist.initial_velocity_max = 1.4
	mist.gravity = Vector3(0, -0.3, 0)
	mist.scale_amount_min = 0.2
	mist.scale_amount_max = 0.45
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0
	mist.mesh = sm
	mist.material_override = CharParts.unshaded(Color(1, 1, 1, 0.35))
	add_child(mist)
	# Main pool beneath the falls and a lower pond, joined by a stream under the timber bridge
	EnvKit.pond(self, Vector3(2, 0, -6), 4.6)
	EnvKit.pond(self, Vector3(-7, 0, 8.5), 3.0)
	# Stream frame: from the main pool's south-west edge down to the lower pond
	var frame := Node3D.new()
	frame.position = Vector3(-4.5, 0, 0.75)
	frame.rotation_degrees.y = -28
	add_child(frame)
	var stream := CharParts.add(frame, CharParts.box_mesh(Vector3(2.4, 0.06, 11.0)), EnvKit.water_material(), Vector3(0, 0.07, 0))
	stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Banks block crossing except over the bridge
	EnvKit.invisible_wall(frame, Vector3(2.4, 2, 2.8), Vector3(0, 1, -3.4))
	EnvKit.invisible_wall(frame, Vector3(2.4, 2, 4.8), Vector3(0, 1, 2.7))
	_bridge(Vector3(-4.1, 0, 0.0))
	# Fishing banks (broad enough for camera and companion)
	add_fishing("fish_falls", "falls", Vector3(7.8, 0, -3.6), Vector3(-2.4, 0.1, -2.0))
	add_fishing("fish_pond", "pond", Vector3(1.0, 0, -0.4), Vector3(0.4, 0.1, -3.2))
	add_fishing("fish_lower", "pond", Vector3(-3.4, 0, 9.2), Vector3(-2.6, 0.1, -0.3))
	# Reeds, rocks, frog
	for i in 10:
		var a := TAU * i / 10.0
		CharParts.add(self, CharParts.cyl_mesh(0.02, 0.03, 0.9, 4), CharParts.mat(Color("6f9c4f")), Vector3(-7 + cos(a) * 3.3, 0.45, 8.5 + sin(a) * 3.3), Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))
	for p in [Vector3(9, 0, 4), Vector3(11, 0, -6), Vector3(-11, 0, -7), Vector3(12, 0, 9)]:
		EnvKit.rock(self, p, 1.0)
	var frog := Node3D.new()
	frog.position = Vector3(-8.5, 0.15, 6.2)
	add_child(frog)
	CharParts.sphere(frog, 0.14, Color("6fb35e"), Vector3(0, 0.1, 0), Vector3(1, 0.7, 1.1), 0.008)
	for s in [-1.0, 1.0]:
		CharParts.sphere(frog, 0.05, Color("6fb35e"), Vector3(0.06 * s, 0.2, 0.06), Vector3.ONE, 0.006)
		CharParts.sphere(frog, 0.02, Color("2b1408"), Vector3(0.06 * s, 0.22, 0.1), Vector3.ONE, 0.0)
	for p in [Vector3(-12, 0, 2), Vector3(12, 0, -1), Vector3(10, 0, 11)]:
		EnvKit.tree(self, p, 1.2, Color("4f9a50"))
	add_npc("lumi", [[5, Vector3(3.0, 0, 0.6)], [12, Vector3(-1.2, 0, 10.5)], [17, Vector3(5.5, 0, -1.5)], [20, Vector3(9.0, 0, 6.0)]])


func _bridge(p: Vector3) -> void:
	var root := Node3D.new()
	root.position = p
	root.rotation_degrees.y = -28
	add_child(root)
	# Arched timber deck along local X (the path direction)
	for i in 9:
		var x := -2.4 + i * 0.6
		var h := 0.45 * (1.0 - pow(x / 2.6, 2.0))
		CharParts.add(root, CharParts.box_mesh(Vector3(0.55, 0.1, 2.2)), CharParts.mat(EnvKit.WOOD_LIGHT if i % 2 else EnvKit.WOOD, 0.008), Vector3(x, 0.12 + h, 0))
	for z in [-1.15, 1.15]:
		for i in 5:
			var x := -2.0 + i * 1.0
			CharParts.add(root, CharParts.cyl_mesh(0.05, 0.05, 0.8, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 0.55 + 0.45 * (1.0 - pow(x / 2.6, 2.0)), z))
		var rail := CharParts.add(root, CharParts.box_mesh(Vector3(5.0, 0.07, 0.07)), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(0, 1.05, z))
		rail.name = "Rail"
	var sb := EnvKit.body(root)
	# two gentle ramps (collision proxies, not the plank meshes)
	var r1 := EnvKit.add_box_shape(sb, Vector3(2.8, 0.2, 2.2), Vector3(-1.3, 0.3, 0))
	r1.rotation.z = deg_to_rad(10)
	var r2 := EnvKit.add_box_shape(sb, Vector3(2.8, 0.2, 2.2), Vector3(1.3, 0.3, 0))
	r2.rotation.z = deg_to_rad(-10)
	EnvKit.add_box_shape(sb, Vector3(5.0, 1.2, 0.15), Vector3(0, 0.9, 1.15))
	EnvKit.add_box_shape(sb, Vector3(5.0, 1.2, 0.15), Vector3(0, 0.9, -1.15))
