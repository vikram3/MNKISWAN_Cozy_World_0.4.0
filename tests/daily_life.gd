extends Node
var passed := 0
var failed := 0
var world: Node3D
var life: DailyLife
var ritual: TogetherMoments
var p: MnkiController
var friend: SwanCompanion

func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("PASS: ", label)
	else: failed += 1; push_error("FAIL: " + label)

func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame

func hour(value: int) -> void:
	TimeManager.minute = value * 60
	life.sync_clock(true)

func _ready() -> void:
	GameState.new_game()
	SaveManager.clear_pending()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await frames(35)
	GameState.clear_ui()
	TimeManager.running = false
	life = world.get_node("DailyLife")
	ritual = world.get_node("TogetherMoments")
	world.get_node("CoupleConversations").set_process(false)
	p = GameState.player
	friend = GameState.swan
	check(life.initialized and life.residents.size() == 31, "31 villagers have a home and routine")
	check(life.homes.size() > 5, "village houses receive working doorstep interactions")
	for point in get_tree().get_nodes_in_group("together_place"):
		for offset in [-0.7, 0.8]:
			var probe := PhysicsShapeQueryParameters3D.new()
			probe.shape = life.navigation.probe
			probe.collision_mask = 1 | 16
			probe.transform.origin = point.global_position + Vector3(offset, 0.85, 0)
			check(world.get_world_3d().direct_space_state.intersect_shape(probe).is_empty(), "shared ritual has room for both partners: " + point.object_id + str(offset))
	GameState.ui.open_together() # Viewing memories before completing one must be safe.
	GameState.ui.together.close()
	hour(10)
	await frames(50)
	check(life.residents.poppy.npc.model.action == "play_ball" and life._ball.visible, "children play catch in the park")
	check(life.residents.pearl.npc.model.action == "read", "Pearl reads on the bench")
	check(life.residents.rowan.npc.model.global_position.distance_to(life.residents.rowan.seat) < 0.1, "Rowan actually occupies his bench seat")
	check(life.residents.sumi.npc.model.action == "farm", "Sumi works in the rice fields")
	check(life.residents.bao.npc.model.action == "farm", "Bao has a field work animation")
	hour(13)
	await frames(5)
	check(life.residents.sumi.npc.model.action == "eat" and life.residents.poppy.npc.model.action == "eat", "workers and children stop for lunch")
	check(life.residents.nila.npc.model.action == "affection", "garden couple spends time together")
	hour(15)
	await frames(50)
	check(life.residents.poppy.phase == "swing" and absf(world.regions.village_park.swing_pivot.rotation.x) > 0.01, "playground swing moves with its seated child")
	var swing_seat: Vector3 = world.regions.village_park.swing_pivot.to_global(Vector3(0, -1.75, 0))
	check(absf(life.residents.poppy.npc.model.hips.global_position.y - swing_seat.y) < 0.15, "child sits on the swing seat rather than floating above it")
	hour(19)
	await frames(10)
	check(life._market_lights.visible and life.residents.tamsin.npc.visible, "night market lights and vendors are active")
	check(life.residents.nila.phase == "market" and life.residents.arun.phase == "market", "couple visits market together")
	hour(22)
	check(life.residents.poppy.sleeping and life.residents.elder.sleeping, "children and elders sleep at night")
	check(not life.residents.tamsin.sleeping and not life.residents.ren.sleeping, "night market remains lively after household bedtime")
	check(not DailyLifeData.market_open(17) and DailyLifeData.market_open(18) and DailyLifeData.market_open(23) and not DailyLifeData.market_open(0), "market opening boundaries are exact")
	# Test actual walking home for everyone, not only clock/load placement.
	hour(19)
	for state in life.residents.values(): state.npc.set_physics_process(false)
	life.set_process(false)
	TimeManager.minute = 0
	life.sync_clock()
	for id in life.residents:
		var state: Dictionary = life.residents[id]
		check(state.sleeping or not state.route.is_empty(), "reachable route home: " + id)
	for i in 2100:
		for state in life.residents.values(): life.step(state.npc, 1.0 / 15.0)
		if i % 10 == 0: await frames(1)
	for id in life.residents:
		var s: Dictionary = life.residents[id]
		check(s.sleeping and not s.npc.visible and s.npc._body.collision_layer == 0, "walked home and retired: " + id)
		if not s.sleeping: print("ROUTE DEBUG ", id, " position=", s.npc.global_position, " goal=", s.goal, " index=", s.index, " size=", s.route.size())
	hour(8)
	for state in life.residents.values(): state.npc.set_physics_process(true)
	life.set_process(true)
	await frames(10)
	check(life.residents.poppy.npc.visible and not life.residents.poppy.sleeping, "new morning wakes children")
	# Shared rituals must use both actors, cleanly cancel, and persist completed memories.
	p.teleport(Vector3(48, 0.3, -22))
	friend.global_position = Vector3(50, 0.3, -22)
	friend.model.clear_action()
	p.model.clear_action()
	await frames(60)
	check(ritual.begin("appreciate"), "nearby grounded partners can start a shared moment")
	check(p.state == "locked" and friend.state == "together" and friend.model.action == "affection", "both partners join the ritual")
	check(not p.switch_character(), "switch cannot break a shared moment")
	Input.action_press("move_forward")
	await frames(3)
	Input.action_release("move_forward")
	check(not ritual.active and p.state == "free" and friend.state == "follow", "movement gently cancels and restores both actors")
	check(GameState.world.get_state("together_appreciate", {}).get("days", 0) == 0, "cancelled moment does not create a completed memory")
	await frames(30)
	var before := GameState.economy.coins
	check(ritual.begin("dance"), "shared dance begins")
	ritual.elapsed = ritual.duration - 0.01
	await frames(3)
	check(GameState.world.get_state("together_dance", {}).get("days", 0) == 1, "completed ritual creates a saved memory")
	check(GameState.economy.coins == before, "affection does not cost or farm money")
	check(ritual.begin("dance"), "ritual can be enjoyed again without cooldown")
	ritual.finish(true)
	check(GameState.world.get_state("together_dance", {}).get("days", 0) == 1, "repeating ritual does not duplicate daily memory")
	check(ritual.begin("tea"), "tea creates held cups for both partners")
	check(ritual._props.size() == 2, "both partners have a cup")
	GameState.ui.open_together()
	await frames(3)
	check(not ritual.active and ritual._props.is_empty() and p.state == "free", "opening a menu clears ritual state and props")
	check(GameState.top_ui() == "together", "new shared-life panel participates in modal stack")
	GameState.ui.together.close()
	check(p.switch_character(), "switching works after ritual cancellation")
	await frames(5)
	check(ritual.begin("breathe"), "Swan can initiate the same rituals")
	check(ritual._line.text.contains("Swan:"), "ritual speaker follows character switching")
	ritual.finish(false)
	p.flight_mode = "flying"
	check(not ritual.begin("dance"), "airborne ritual is rejected")
	p.flight_mode = "grounded"
	hour(2)
	check(not ritual.unavailable_reason("market").is_empty(), "night meal cannot start after market closure")
	# Correct house mask: fall onto real upper floor rather than through it.
	var house: Node3D = world.regions.treehouse.house
	p.teleport(house.to_global(Vector3(0, 4, -1.5)))
	await frames(75)
	check(p.is_on_floor() and p.global_position.y > 3, "hero stands on the upper treehouse floor")
	p.teleport(house.to_global(Vector3(4.3, 0.3, 5.0)))
	p.set_physics_process(false)
	for i in 300:
		p.velocity = house.global_basis * Vector3(0, 0 if p.is_on_floor() else -3, -2.0)
		p.move_and_slide()
		await frames(1)
	print("Stair traversal finished at ", house.to_local(p.global_position))
	check(p.global_position.y >= 3.18 and house.to_local(p.global_position).z < 0 and p.is_on_floor(), "hero can walk up the treehouse stairs without jumping")
	p.set_physics_process(true)
	var slow := VillagerModel.new().setup(NpcDB.get_def("pearl"))
	var fast := VillagerModel.new().setup(NpcDB.get_def("pearl"))
	add_child(slow); add_child(fast)
	slow.set_process(false); fast.set_process(false)
	slow.play_action("fish", -1); fast.play_action("fish", -1)
	for i in 30: slow._animate(1.0 / 30.0)
	for i in 120: fast._animate(1.0 / 120.0)
	check(absf(slow.arm_r.rotation.x - fast.arm_r.rotation.x) < 0.0001, "pose smoothing converges equally at 30 and 120 FPS")
	slow.queue_free(); fast.queue_free()
	var calls := [0]
	TimeManager.hour_changed.connect(func(_h): calls[0] += 1)
	TimeManager.sleep_to_morning()
	check(TimeManager.hour() == 6 and calls[0] == 1, "sleep emits the new hour immediately")
	check(SaveManager.save_game("daily_life_test") and SaveManager.prepare_load(), "daily memories save and load with existing schema")
	check(SaveManager.pending_load.game.world.objects.together_dance.days == 1, "shared memory survives save serialization")
	SaveManager.clear_pending()
	SaveManager.delete_save()
	var addresses := {}
	for id in life.residents: addresses[id] = life.residents[id].home.global_position
	world.queue_free()
	await frames(3)
	GameState.new_game()
	TimeManager.minute = 22 * 60
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await frames(20)
	life = world.get_node("DailyLife")
	var stable := true
	for id in addresses:
		stable = stable and addresses[id].distance_to(life.residents[id].home.global_position) < 0.01
	check(stable, "all 31 household assignments remain stable when the world loads at night")
	print("DAILY LIFE: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed else 0)
