extends Node
## Actual scene captures. Overview camera is for reviewing placement, not a gameplay feature.
func _ready() -> void:
	GameState.new_game()
	SaveManager.clear_pending()
	TimeManager.minute = 620
	var world := load("res://scenes/world/tree_village_world.tscn").instantiate() as Node3D
	add_child(world)
	await frames(5)
	TimeManager.running = false
	GameState.clear_ui()
	GameState.ui.hud.force_hidden = true
	var p := GameState.player as MnkiController
	GameState.swan.set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 50
	var requested := OS.get_cmdline_user_args()
	for region in VillageLifeData.PLACES:
		if not requested.is_empty() and not region in requested:
			continue
		var place: Node3D = world.get_node("VillageLife").places[region]
		var center := place.global_position
		p.teleport(center + Vector3(-0.7, 0.3, 1.3))
		GameState.swan.global_position = center + Vector3(0.8, 0, 1.3)
		camera.global_position = center + Vector3(8, 6, 11)
		if region in ["berry_maze", "waterfall_ponds"]:
			camera.global_position = center + Vector3(-7, 7, 9)
		elif region == "animal_farm":
			camera.global_position = center + Vector3(8, 7, -8)
		camera.look_at(center + Vector3(0, 1.2, 0))
		await frames(3)
		GameState.swan._bubble.hide()
		await shot("life_" + region)
	if not requested.is_empty():
		get_tree().quit()
		return
	# Capture the actual HUD / non-modal portrait dialogue in the garden.
	var center: Vector3 = world.get_node("VillageLife").places.flower_garden.global_position
	p.teleport(center + Vector3(-0.7, 0.3, 1.3))
	GameState.swan.global_position = center + Vector3(0.8, 0.1, 1.3)
	GameState.swan.velocity = Vector3.ZERO
	GameState.swan._bubble_t = 0
	GameState.swan._bubble.hide()
	GameState.swan.model.clear_action()
	p.model.clear_action()
	camera.global_position = center + Vector3(5, 3.5, 7)
	camera.look_at(center + Vector3(0, 1.1, 0))
	await frames(20)
	GameState.swan._bubble_t = 0
	GameState.swan._bubble.hide()
	GameState.swan.model.clear_action()
	for npc: NpcCharacter in get_tree().get_nodes_in_group("villager"):
		npc._bubble_t = 0
		npc._bubble.hide()
		npc._greet_cooldown = 100
	GameState.ui.hud.force_hidden = false
	var chat: CoupleConversations = world.get_node("CoupleConversations")
	chat.begin_chat()
	assert(chat.active, "Gallery requires an actual eligible conversation")
	await frames(2)
	await shot("life_conversation")
	chat.cancel()
	TimeManager.minute = 1250
	world._update_daylight()
	for activity: CozyActivity in get_tree().get_nodes_in_group("cozy_activity"):
		GameState.world.set_state(activity.object_id, {"day": TimeManager.day})
		activity._refresh()
	GameState.ui.hud.force_hidden = true
	center = world.get_node("VillageLife").places.market_square.global_position
	camera.global_position = center + Vector3(11, 7, 14)
	camera.look_at(center + Vector3(0, 1, -3))
	await frames(3)
	await shot("life_market_evening")
	get_tree().quit()

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://living_gallery")
	get_viewport().get_texture().get_image().save_png("user://living_gallery/%s.png" % label)
	print("Captured ", label)
