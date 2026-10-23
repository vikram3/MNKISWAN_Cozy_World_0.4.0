extends Node
## Captures the actual in-game view, with the same camera and HUD used by players.
func _ready() -> void:
	GameState.new_game()
	SaveManager.clear_pending()
	for flag in ["gate_open", "park_restored"]:
		GameState.world.set_flag(flag)
	TimeManager.minute = 620
	var world := load("res://scenes/world/tree_village_world.tscn").instantiate() as Node3D
	add_child(world)
	await frames(10)
	GameState.clear_ui()
	var p := GameState.player as MnkiController
	p.teleport(GameData.region_world_pos("flower_garden") + Vector3(-4, 0.2, -7), 0)
	GameState.swan.global_position = p.global_position + Vector3(1.6, 0.3, 0)
	await frames(20)
	p.rig.set_yaw_deg(30)
	await frames(15)
	await shot("garden_mnki")
	p.switch_character(true)
	p.rig.set_yaw_deg(-25)
	await frames(15)
	await shot("garden_swan")
	p.teleport(Vector3(-24, 8, -22))
	p.model.clear_action()
	assert(p.toggle_flight())
	GameState.swan._bubble.visible = false
	p.rig.distance = 5.6
	p.rig.set_yaw_deg(-40)
	await frames(20)
	await shot("swan_flying")
	GameState.ui.hud.force_hidden = true
	p.rig.set_yaw_deg(140)
	await frames(10)
	await shot("swan_flight_front")
	get_tree().quit()

func frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://revision_gallery")
	get_viewport().get_texture().get_image().save_png("user://revision_gallery/%s.png" % label)
	print("Captured ", label)
