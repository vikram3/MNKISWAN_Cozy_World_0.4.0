extends Node
## Regression for "First Harvest hides every other request": the HUD request card, crop hints,
## waypoint targets, switching the tracked request, new-request givers, toast de-duplication,
## and finishing First Harvest end to end. Mirrors a real save: story done up to the basket,
## First Harvest accepted, rice watered and waiting for the night.
var passed := 0
var failed := 0
var q: QuestSystem
var pl: MnkiController


func _ready() -> void:
	Settings.data["tutorial_done"] = true
	GameState.new_game()
	SaveManager.clear_pending()
	var world: Node = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await _frames(40)
	await _drain()
	GameState.clear_ui()
	q = GameState.quests
	pl = GameState.player
	for id in ["q_arrival", "q_gentle_hands", "q_open_stall", "q_village_basket"]:
		q.states[id] = {"state": "done", "step": 99, "progress": 0, "targets": []}
	q.states.erase("q_mend_bridge")
	check(q.start("q_first_harvest", true), "First Harvest accepted")
	q.tracked_changed.emit()
	await _frames(2)
	var hud: HUD = GameState.ui.hud
	check(q.tracked_quest() == "q_first_harvest", "only running request is tracked")
	check(q.available_requests().any(func(r): return r.id == "q_mend_bridge"), "next story request is waiting at the Elder")
	check(hud._obj_more.text.contains("Elder"), "request card tells the player the Elder has a new request")
	check(Waypoints.request_givers(get_tree()).size() > 0, "request givers are found in the world (gold !)")

	# --- Plant / water / sleep with live hints -------------------------------------------------
	await _go(GameData.region_world_pos("paddy_field") + Vector3(0, 0, 3))
	GameState.inventory.add("seed_rice", 2)
	GameState.selected_seed = "seed_rice"
	var plot := _find("plot_01") as FarmPlot
	check(q.objective_text("q_first_harvest").contains("Plant rice"), "hint before planting says to plant")
	check(q.objective_target("q_first_harvest").begins_with("plot_"), "waypoint points at an empty plot")
	plot.interact(pl)
	check(q.objective_text("q_first_harvest").contains("Water the rice today"), "hint after planting says to water")
	check(q.objective_target("q_first_harvest") == "plot_01", "waypoint points at the dry plot")
	plot.interact(pl)
	await _frames(2)
	check(q.is_waiting("q_first_harvest"), "watered rice is waiting for the night")
	check(q.objective_text("q_first_harvest").contains("Sleep in the treehouse bed"), "hint says to sleep")
	check(q.objective_target("q_first_harvest") == "bed", "waypoint points at the treehouse bed")
	var bed_target = Waypoints.quest_target(get_tree())
	check(bed_target != null and Vector2(bed_target.x, bed_target.z).distance_to(Vector2(GameData.region_world_pos("treehouse").x, GameData.region_world_pos("treehouse").z)) < 15.0, "bed waypoint is in the treehouse")
	check(hud._obj_text.text.contains("Sleep"), "HUD card shows the sleep hint")

	# --- A waiting request steps aside for one you can do now ------------------------------------
	check(q.start("q_patience", true), "second request accepted (Lumi)")
	check(q.tracked_quest() == "q_patience", "waiting rice steps aside for a request you can do now")
	check(hud._obj_more.text.contains("of 2"), "card shows how many requests are running")
	q.cycle_tracked()
	check(q.tracked_quest() == "q_first_harvest", "switch brings First Harvest back")
	var saved := q.to_save()
	q.from_save(saved)
	check(q.tracked_quest() == "q_first_harvest", "chosen request survives save/load")
	q.cycle_tracked()
	check(q.tracked_quest() == "q_patience", "switch cycles onward")
	q.pinned = ""

	# --- Toast spam ------------------------------------------------------------------------------
	for i in 4:
		plot.interact(pl)
	await _frames(2)
	var same := 0
	for t in hud._toasts.get_children():
		if String(t.get_meta("text", "")).begins_with("Already watered"):
			same += 1
	check(same == 1, "repeated 'already watered' shows one toast, not a stack")

	# --- Night, second watering, harvest, finish --------------------------------------------------
	TimeManager.sleep_to_morning()
	await _frames(3)
	check(q.objective_text("q_first_harvest").contains("Water the rice today"), "next morning: water again")
	check(not q.is_waiting("q_first_harvest"), "dry rice is actionable again")
	plot.interact(pl)
	TimeManager.sleep_to_morning()
	await _frames(3)
	check(plot.is_ready_crop(), "rice ripe after two watered nights")
	check(q.objective_text("q_first_harvest").contains("Ready!"), "hint says ready to harvest")
	check(q.objective_target("q_first_harvest") == "plot_01", "waypoint points at the ripe plot")
	plot.interact(pl)
	await _frames(2)
	await _drain()
	check(q.objective("q_first_harvest").get("type", "") == "talk", "harvest advances to 'Show Bao your rice'")
	var bao := _find("bao") as NpcCharacter
	check(bao != null, "Bao found")
	bao.interact(pl)
	await _frames(2)
	await _drain()
	check(q.is_done("q_first_harvest"), "First Harvest completes and leaves the card")
	check(q.tracked_quest() != "q_first_harvest", "card moves on to the next request")
	print("QUEST TRACKING: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _drain() -> void:
	var d: DialogueBox = GameState.ui.dialogue
	var guard := 0
	while d.is_active() and guard < 50:
		d._finish(0)
		guard += 1
		await _frames(1)


func _find(id: String) -> Node:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is NpcCharacter and (n as NpcCharacter).npc_id == id:
			return n
		if (n as Interactable).object_id == id:
			return n
	return null


func _go(p: Vector3) -> void:
	pl.teleport(p + Vector3(0, 0.3, 0), 0)
	await _frames(20)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
