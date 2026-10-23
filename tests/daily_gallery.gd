extends Node
func frames(n: int) -> void:
	for i in n: await get_tree().process_frame

func _ready() -> void:
	GameState.new_game()
	SaveManager.clear_pending()
	TimeManager.minute = 600
	var world: Node3D = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await frames(5)
	TimeManager.running = false
	GameState.clear_ui()
	world.get_node("CoupleConversations").set_process(false)
	GameState.ui.hud.force_hidden = true
	var p: MnkiController = GameState.player
	var f: SwanCompanion = GameState.swan
	p.teleport(Vector3(48, 0.3, -22))
	f.global_position = Vector3(50, 0.3, -22)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 48
	var life: DailyLife = world.get_node("DailyLife")
	for spec in [["park_morning", 10, "village_park", Vector3(4, 0, 4), Vector3(8, 7, 11)], ["garden_date", 15, "flower_garden", Vector3(-2, 0, 5.2), Vector3(5, 3.5, 7)], ["fields_work", 10, "paddy_field", Vector3(4.5, 0, -4), Vector3(8, 6, 7)], ["lantern_market", 22, "market_square", Vector3(0, 0, 2), Vector3(12, 9, 16)], ["park_swing", 15, "village_park", Vector3(9, 0, 7), Vector3(-4, 3.5, 2)]]:
		if not OS.get_cmdline_user_args().is_empty() and spec[0] not in OS.get_cmdline_user_args(): continue
		TimeManager.minute = spec[1] * 60
		life.sync_clock(true)
		world._update_daylight()
		var center: Vector3 = GameData.region_world_pos(spec[2]) + spec[3]
		cam.global_position = center + spec[4]
		cam.look_at(center + Vector3(0, 1, 0))
		for state in life.residents.values():
			state.npc._greet_cooldown = 100
		await frames(18)
		await shot(spec[0])
	if not OS.get_cmdline_user_args().is_empty():
		get_tree().quit()
		return
	TimeManager.minute = 900
	life.sync_clock(true)
	world._update_daylight()
	var center := GameData.region_world_pos("flower_garden") + Vector3(0, 0, 11.5)
	p.teleport(center + Vector3(-0.7, 0.3, 0))
	f.global_position = center + Vector3(0.8, 0.3, 0)
	cam.global_position = center + Vector3(5, 3.5, 7)
	cam.look_at(center + Vector3(0, 1, 0))
	await frames(25)
	p.model.clear_action()
	f.model.clear_action()
	f._bubble.hide()
	assert(world.get_node("TogetherMoments").begin("garden"), "Gallery must show a real shared moment")
	await frames(12)
	await shot("together_garden")
	world.get_node("TogetherMoments").finish(false)
	GameState.ui.open_together()
	await frames(2)
	await shot("together_ui")
	GameState.ui.together.content.get_child(1).current_tab = 1
	await frames(2)
	await shot("village_day_ui")
	get_tree().quit()

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://daily_gallery")
	get_viewport().get_texture().get_image().save_png("user://daily_gallery/%s.png" % label)
	print("Captured ", label)
