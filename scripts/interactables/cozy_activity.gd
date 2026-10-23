class_name CozyActivity
extends Interactable
## Daily reward is transactional; repeating an activity is welcome but cannot mint coins.
var region_id := ""
var definition: Array = []
var tint := Color.WHITE
var result: Node3D
var animated: Node3D
var _phase := 0.0
var _pending := false

func setup(region: String, index: int, data: Array, color: Color) -> CozyActivity:
	region_id = region
	object_id = "cozy_%s_%d" % [region, index]
	definition = data
	tint = color
	return self

func _ready() -> void:
	interaction_range = 2.1
	priority = 2
	marker_height = 1.9
	super._ready()
	add_to_group("cozy_activity")
	var prop := VillageDecor.activity_prop(self, String(definition[0]), tint)
	result = prop.result
	animated = prop.animated
	_refresh()
	TimeManager.day_started.connect(func(_d): _refresh())

func completed_today() -> bool:
	return int(GameState.world.get_state(object_id).get("day", -1)) == TimeManager.day

func _refresh() -> void:
	result.visible = completed_today()

func get_interaction_prompt(_actor: Node) -> String:
	return String(definition[1]) + ("  (enjoy again)" if completed_today() else "  (+2 coins today)")

func can_interact(actor: Node) -> bool:
	return not _pending and actor is MnkiController and actor.flight_mode == "grounded" and not GameState.is_ui_blocking()

func interact(actor: Node) -> void:
	if not can_interact(actor) or actor.global_position.distance_to(global_position) > interaction_range + 0.4:
		return
	_pending = true
	var host := String(VillageLifeData.PLACES[region_id][2])
	GameState.request_dialogue([host + ": " + String(definition[1]) + "? Take your time; there is enough for everyone."], ["Let's do it", "Maybe later"], func(choice: int):
		_pending = false
		if choice == 0 and is_instance_valid(actor) and actor.global_position.distance_to(global_position) <= interaction_range + 0.4:
			complete(actor))

func complete(actor: Node) -> bool:
	# Also protects against a stale dialogue callback after teleporting or taking off.
	if not is_instance_valid(actor) or not actor is MnkiController or actor.flight_mode != "grounded" or actor.global_position.distance_to(global_position) > interaction_range + 0.4:
		return false
	var first_today := not completed_today()
	GameState.world.set_state(object_id, {"day": TimeManager.day, "visited": true})
	if first_today:
		GameState.economy.add(2, String(definition[1]))
	_refresh()
	actor.face_towards(global_position)
	actor.play_action("water" if definition[0] == "flower" else "gather", 1.0)
	AudioManager.play_sfx("chime")
	GameState.notify(String(definition[2]) + ("  +2 coins" if first_today else ""), "success")
	GameState.record_note(object_id, String(definition[1]), String(definition[3]))
	var all_here := true
	for i in 3:
		all_here = all_here and bool(GameState.world.get_state("cozy_%s_%d" % [region_id, i]).get("visited", false))
	if all_here:
		GameState.world.set_flag("cozy_visit_" + region_id)
		var count := 0
		for region in VillageLifeData.PLACES:
			if GameState.world.has_flag("cozy_visit_" + region):
				count += 1
		if count == 13:
			GameState.record_note("village_keepsake", "A village full of little memories", "Mnki and Swan shared a little kindness in every corner of the village. Thirteen places, one home.")
	SaveManager.autosave("cozy_activity")
	return first_today

func _process(delta: float) -> void:
	super._process(delta)
	if not animated or bool(Settings.get_value("reduced_motion")) or GameState.is_ui_blocking():
		return
	_phase += delta
	if definition[0] == "water" and completed_today():
		animated.rotation.z += delta * 0.7
	elif definition[0] == "chime":
		animated.rotation.z = sin(_phase * 1.5) * (0.14 if completed_today() else 0.035)
