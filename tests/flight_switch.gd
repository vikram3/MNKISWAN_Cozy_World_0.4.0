extends Node
## Real physics regression: input, collisions, ownership, persistence and paused flight.
var passed := 0
var failed := 0
var world: Node
var p: MnkiController

func _ready() -> void:
	var lock := CharacterSculpt.lock_mesh([Vector3.ZERO, Vector3.UP], 0.1, 0.05)
	var arrays := lock.surface_get_arrays(0)
	check((arrays[Mesh.ARRAY_VERTEX][0] as Vector3).dot(arrays[Mesh.ARRAY_NORMAL][0]) > 0, "hair and feather mesh normals point outward")
	arrays = CharacterSculpt.hood_shell().surface_get_arrays(0)
	check((arrays[Mesh.ARRAY_VERTEX][0] as Vector3).dot(arrays[Mesh.ARRAY_NORMAL][0]) > 0, "hood shell normals point outward")
	GameState.new_game()
	SaveManager.clear_pending()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	p = GameState.player
	await frames(70)
	GameState.clear_ui()
	# An empty, level clearing isolates locomotion from region props.
	p.teleport(Vector3(48, 0.3, -22))
	GameState.swan.global_position = Vector3(50, 0.3, -22)
	await frames(70)
	check(p.is_on_floor(), "Mnki is grounded")
	check(not p.toggle_flight(), "Mnki cannot fly")
	var mnki_model := p.model
	var swan_model: CharModel = GameState.swan.model
	var inventory_before := GameState.inventory.to_save()
	check(p.switch_character(), "switch from Mnki to Swan")
	check(p.character_id == "swan" and p.model == swan_model, "Swan model is the controlled character")
	check(GameState.swan.model == mnki_model, "Mnki becomes the companion without duplicating models")
	check(p._rod.get_parent() == p.model.arm_r, "fishing equipment follows the active rig")
	check(GameState.inventory.to_save() == inventory_before, "inventory preserved across switch")
	await frames(10)
	var start := p.global_position
	Input.action_press("move_forward")
	await frames(30)
	Input.action_release("move_forward")
	check(p.global_position.distance_to(start) > 1.0, "Swan walks using player input")
	await frames(20)
	check(p.toggle_flight(), "Swan takes off")
	Input.action_press("jump")
	await frames(100)
	Input.action_release("jump")
	await frames(40)
	check(p.global_position.y > 5.0, "held ascend gains altitude")
	var hover_y := p.global_position.y
	await frames(50)
	check(absf(p.global_position.y - hover_y) < 0.15, "Swan hovers without input")
	Input.action_press("descend")
	await frames(30)
	Input.action_release("descend")
	check(p.global_position.y < hover_y - 0.7, "descent input lowers altitude")
	check(GameState.swan.global_position.y < 1.0, "Mnki stays on the ground during flight")
	check(not p.switch_character(), "airborne switching is safely refused")
	check(p.scanner.current == null, "flight does not interact through roofs or with ground props")
	var paused_pos := p.global_position
	GameState.push_ui("inventory")
	Input.action_press("jump")
	Input.action_press("move_forward")
	await frames(30)
	check(p.global_position.distance_to(paused_pos) < 0.001, "opening a menu freezes flight")
	check(not p.toggle_flight() and not p.switch_character(), "menus block flight and switch commands")
	GameState.pop_ui("inventory")
	Input.action_release("move_forward")
	await frames(340)
	Input.action_release("jump")
	check(p.global_position.y <= p.flight_ceiling + 0.15, "flight ceiling prevents escape")
	p.global_position = Vector3(60.8, 22, 108.8)
	p.rig.set_yaw_deg(0)
	Input.action_press("move_right")
	Input.action_press("move_back")
	await frames(40)
	Input.action_release("move_right")
	Input.action_release("move_back")
	check(p.global_position.x <= 61.0 and p.global_position.z <= 109.0, "flight cannot leave the village boundary")
	check(SaveManager.save_game("flight_test"), "save during flight succeeds")
	var snapshot := SaveManager.build_snapshot()
	check(snapshot.player.character == "swan" and float(snapshot.player.pos[1]) < 1.0, "flight save records Swan and safe ground")
	check(SaveManager.prepare_load(), "saved Swan can be loaded")
	world.queue_free()
	await frames(3)
	GameState.new_game()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	p = GameState.player
	await frames(65)
	GameState.clear_ui()
	check(p.character_id == "swan" and p.model is SwanModel, "reload restores Swan as playable")
	check(p.flight_mode == "grounded" and p.is_on_floor(), "reloading airborne save starts safely grounded")
	check(GameState.swan.model is MnkiModel, "reload restores Mnki companion")
	p.teleport(Vector3(48, 0.3, -22))
	GameState.swan.global_position = Vector3(50, 0.3, -22)
	await frames(60)
	check(p.toggle_flight(), "second takeoff")
	var trail := world.get_node("SkyTrail") as SkyTrail
	var old_coins := GameState.economy.coins
	p.global_position = SkyTrail.STOPS[0] - Vector3.UP * 0.7
	await frames(5)
	check(GameState.world.has_flag("sky_feather_0") and GameState.economy.coins == old_coins + 5, "flying through a sky charm collects its reward")
	check(not trail.collect(0) and GameState.economy.coins == old_coins + 5, "sky feather cannot pay twice")
	check(not trail.collect(-1) and not trail.collect(6), "invalid sky feather IDs are rejected")
	check(SaveManager.build_snapshot().game.world.flags.has("sky_feather_0"), "sky trail progress included in save")
	p.global_position = Vector3(48, 2.5, -22)
	Input.action_press("jump")
	await frames(70)
	Input.action_release("jump")
	check(p.toggle_flight() and p.flight_mode == "landing", "flight toggle requests gentle landing")
	await frames(220)
	check(p.flight_mode == "grounded" and p.is_on_floor(), "landing finishes on floor")
	await frames(60)
	check(p.switch_character(), "switch back after landing")
	check(p.character_id == "mnki" and p.model is MnkiModel and GameState.swan.model is SwanModel, "both identities stay correct after round trip")
	# Actual solid ceiling: takeoff rejected indoors, flight collision tested outdoors.
	check(p.switch_character(), "switch back to Swan again")
	await frames(5)
	var roof := EnvKit.body(world, p.global_position + Vector3(0, 2.0, 0))
	EnvKit.add_box_shape(roof, Vector3(4, 0.2, 4))
	await frames(4)
	check(not p.toggle_flight(), "low indoor ceiling blocks takeoff")
	roof.queue_free()
	await frames(3)
	# Ascending into solid geometry must stop, not pass through it.
	roof = EnvKit.body(world, p.global_position + Vector3(0, 6, 0))
	EnvKit.add_box_shape(roof, Vector3(8, 0.3, 8))
	await frames(3)
	check(p.toggle_flight(), "open space below a high roof permits takeoff")
	Input.action_press("jump")
	await frames(110)
	Input.action_release("jump")
	check(p.global_position.y < roof.global_position.y - 1.0, "ascending respects a solid ceiling")
	roof.queue_free()
	p.teleport(Vector3(48, 0.3, -22))
	await frames(40)
	# Save corruption must retain a known-good backup even after a new save.
	check(SaveManager.save_game("backup"), "second save creates backup")
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	check(SaveManager.prepare_load(), "corrupt primary recovers from backup")
	check(SaveManager.save_game("after_corruption"), "save after corrupt primary succeeds")
	check(SaveManager._valid(SaveManager._read_json(SaveManager.BAK_PATH)), "corrupt primary did not overwrite valid backup")
	SaveManager.clear_pending()
	SaveManager.delete_save()
	print("FLIGHT & SWITCH: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)
