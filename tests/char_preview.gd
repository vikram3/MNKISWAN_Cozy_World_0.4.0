extends Node3D
## Renders a canon line-up of Mnki & Swan to user://char_preview_*.png (used for art QA).

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("fbf7ed")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("fff3e0")
	e.ambient_light_energy = 0.25
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.tonemap_exposure = 0.85
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 8.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -135, 0)
	fill.light_energy = 0.22
	fill.light_color = Color("dce9ff")
	add_child(fill)
	var m := MnkiModel.new()
	m.position = Vector3(-0.45, 0, 0)
	m.rotation_degrees.y = 12
	add_child(m)
	var s := SwanModel.new()
	s.position = Vector3(0.45, 0, 0)
	s.rotation_degrees.y = -12
	add_child(s)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(6, 6)
	ground.mesh = pm
	ground.material_override = CharParts.mat(Color("cfe3b8"))
	add_child(ground)
	var cam := Camera3D.new()
	add_child(cam)
	var views := {"front": [Vector3(0, 0.95, 3.0), 0.0], "back": [Vector3(0, 1.1, -3.0), 180.0], "side": [Vector3(3.0, 1.0, 0.6), 80.0], "three": [Vector3(1.8, 1.5, 2.4), 35.0]}
	await get_tree().process_frame
	m.set_expression("neutral", 999)
	for k in views:
		cam.position = views[k][0]
		cam.look_at(Vector3(0, 0.75, 0))
		cam.fov = 40
		for i in 8:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://char_preview_%s.png" % k)
		print("saved ", k)
	get_tree().quit()
