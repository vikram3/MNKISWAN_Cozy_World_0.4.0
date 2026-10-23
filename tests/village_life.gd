extends Node
## Exercise real scene objects, collision approaches, dialogue callbacks, and saved daily state.
var passed := 0
var failed := 0
var world: Node3D
var p: MnkiController

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _ready() -> void:
	GameState.new_game()
	SaveManager.clear_pending()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await frames(75)
	GameState.clear_ui()
	TimeManager.running = false
	p = GameState.player
	var chat: CoupleConversations = world.get_node("CoupleConversations")
	chat.set_process(false)
	var activities := get_tree().get_nodes_in_group("cozy_activity")
	check(activities.size() == 39, "39 activities created")
	check(world.get_node("VillageLife").places.size() == 13, "all thirteen regions have a gathering place")
	check(get_tree().get_nodes_in_group("village_host").size() == 13, "thirteen new hosts created")
	var villagers := 0
	for child in world.npc_root.get_children():
		if child is NpcCharacter:
			villagers += 1
	check(villagers == 31, "31 villagers coexist with farm animals")
	for host: NpcCharacter in get_tree().get_nodes_in_group("village_host"):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = host._probe
		query.collision_mask = 1 | 16
		query.transform.origin = host.global_position + Vector3(0, 0.78, 0)
		check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "host starts clear of scenery: " + host.npc_id)
	GameState.swan.set_physics_process(false)
	GameState.swan.global_position = Vector3(0, 0.1, 0)
	for a: CozyActivity in activities:
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.28
		shape.height = 1.3
		query.shape = shape
		query.collision_mask = 1 | 16
		query.transform.origin = a.global_position + Vector3(0, 0.75, 1.1)
		check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "clear standing approach: " + a.object_id)
		p.teleport(a.global_position + Vector3(0, 0.02, 1.1))
		p.face_towards(a.global_position)
		p.scanner._physics_process(0)
		check(p.scanner.current == a, "keyboard interaction can focus: " + a.object_id)
		var coins := GameState.economy.coins
		check(a.complete(p) and GameState.economy.coins == coins + 2 and a.result.visible, "first completion rewards and changes prop: " + a.object_id)
		check(not a.complete(p) and GameState.economy.coins == coins + 2, "repeat cannot duplicate reward: " + a.object_id)
	check(GameState.journal.notes.has("village_keepsake"), "all thirteen places unlock the shared keepsake")
	var saved := GameState.world.to_save()
	GameState.world.from_save(saved)
	var a: CozyActivity = activities[0]
	check(a.completed_today(), "daily completion survives serialization")
	p.teleport(a.global_position + Vector3(0, 0.02, 1.1))
	var before := GameState.economy.coins
	TimeManager.day += 1
	TimeManager.day_started.emit(TimeManager.day)
	check(not a.completed_today() and not a.result.visible, "new day resets daily visuals and eligibility")
	a.interact(p)
	check(GameState.is_ui_blocking(), "activity presents a real dialogue choice")
	await frames(2)
	GameState.ui.dialogue._finish(1)
	check(GameState.economy.coins == before and not a.completed_today(), "declining does not change rewards or world")
	a.interact(p)
	await frames(2)
	GameState.ui.dialogue._finish(0)
	check(GameState.economy.coins == before + 2 and a.completed_today(), "accepting on a new day grants one reward")
	p.teleport(Vector3(48, 0.3, -22))
	check(not a.complete(p), "remote completion is rejected")
	GameState.swan.global_position = p.global_position + Vector3(1.5, 0, 0)
	GameState.swan.velocity = Vector3.ZERO
	GameState.swan._bubble_t = 0
	GameState.swan.model.clear_action()
	p.model.clear_action()
	await frames(45)
	GameState.swan._bubble_t = 0
	GameState.swan.model.clear_action()
	Settings.data.idle_conversations = true
	chat._last_character = p.character_id
	chat.cooldown = 0
	chat.tick(34.9)
	check(not chat.active, "chat waits for 35 seconds of inactivity")
	chat.tick(0.2)
	check(chat.active and not GameState.is_ui_blocking(), "idle conversation starts without blocking controls")
	var first_lines := chat.current_lines.duplicate()
	chat.tick(10)
	check(chat.line_index == 1 and chat.current_speaker == "Swan", "conversation passes from Mnki to Swan")
	Input.action_press("move_forward")
	chat.tick(0.01)
	Input.action_release("move_forward")
	check(not chat.active and chat.idle_seconds == 0, "movement input interrupts immediately")
	check(chat.cooldown == CoupleConversations.BETWEEN_CHATS, "interrupted chatter has a long cooldown")
	chat.cooldown = 0
	chat.tick(36)
	check(chat.active and chat.current_lines != first_lines, "next conversation avoids repeating the last")
	GameState.push_ui("inventory")
	chat.tick(0.01)
	check(not chat.active, "opening a menu hides conversation")
	GameState.pop_ui("inventory")
	chat.cooldown = 0
	p.switch_character(true)
	chat.tick(0.01)
	check(chat.speaker_model("Swan") == p.model and chat.speaker_model("Mnki") == GameState.swan.model, "speaker identity follows character switching")
	await frames(20)
	p.toggle_flight()
	chat.tick(60)
	check(not chat.active, "flight suppresses idle chat")
	p.teleport(Vector3(48, 0.3, -22))
	await frames(35)
	Settings.data.idle_conversations = false
	chat.tick(120)
	check(not chat.active, "accessibility setting disables idle chat")
	Settings.data.idle_conversations = true
	var npc: NpcCharacter = get_tree().get_nodes_in_group("village_host")[0]
	var old_pos := npc.global_position
	GameState.push_ui("inventory")
	await frames(30)
	check(npc.global_position == old_pos, "NPC movement pauses during menus")
	GameState.pop_ui("inventory")
	npc.interact(p)
	await frames(2)
	GameState.ui.dialogue._finish(-1)
	var friend_key := npc.object_id + "_friendship"
	check(int(GameState.world.get_state(friend_key).get("days", 0)) == 0, "closing host greeting does not count a visit")
	npc.interact(p)
	await frames(2)
	GameState.ui.dialogue._finish(2)
	check(int(GameState.world.get_state(friend_key).get("days", 0)) == 1, "host remembers a friendly visit")
	GameState.ui.dialogue._finish(-1)
	npc.interact(p)
	await frames(2)
	GameState.ui.dialogue._finish(1)
	check(int(GameState.world.get_state(friend_key).get("days", 0)) == 1, "repeated chat counts only one day of friendship")
	GameState.ui.dialogue._finish(-1)
	npc._talking = 0
	npc.global_position = Vector3(20, 0, -20)
	npc.daily_driver = null # This test isolates the legacy capsule steering contract.
	npc.show()
	npc._body.collision_layer = 8
	npc._target = Vector3(20, 0, -26)
	var wall := EnvKit.solid_box(world, Vector3(5, 2, 0.3), Vector3(20, 1, -21), Color.WHITE)
	await frames(90)
	check(npc.global_position.z > -20.7, "NPC capsule steering respects a blocking wall")
	wall.queue_free()
	print("VILLAGE LIFE: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)
