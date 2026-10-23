class_name NpcCharacter
extends Interactable
## Scheduled villagers use capsule sweeps to steer around scenery. Blocked routes wait;
## they never teleport through walls. Hosts stroll locally and greet visitors sparingly.

var daily_driver: DailyLife
var _name_label: Label3D
var npc_id := ""
var model: CharModel
var schedule: Array = []     # [[hour, Vector3 world pos], ...] sorted by hour
var _body: AnimatableBody3D
var _target := Vector3.ZERO
var _talking := 0.0
var _idle_index := 0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _bubble: Label3D
var _bubble_t := 0.0
var home_region := ""
var _greet_cooldown := 10.0
var _activity_t := 8.0
var _stroll_index := 0
var _probe := CapsuleShape3D.new()
static var next_greeting_ms := 0


func setup(id: String, sched: Array) -> NpcCharacter:
	npc_id = id
	object_id = "npc_" + id
	schedule = sched
	return self


func _ready() -> void:
	add_to_group("villager")
	marker_height = 2.0
	interaction_range = 2.6
	priority = 3
	super._ready()
	model = VillagerModel.new().setup(NpcDB.get_def(npc_id))
	add_child(model)
	_body = AnimatableBody3D.new()
	_body.collision_layer = 8
	_body.collision_mask = 0
	_body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.4
	_probe.radius = 0.34
	_probe.height = 1.4
	cs.shape = cap
	cs.position.y = 0.7
	_body.add_child(cs)
	add_child(_body)
	var nm := EnvKit.label3d(self, NpcDB.display_name(npc_id), Vector3(0, 1.85, 0), 34, Color("173b31"), true)
	_name_label = nm
	nm.no_depth_test = false
	nm.modulate.a = 0.85
	nm.visibility_range_end = 14.0
	_bubble = EnvKit.label3d(self, "", Vector3(0, 2.25, 0), 30, Color("3b2a1e"), true)
	_bubble.visible = false
	_bubble.width = 600
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target = _schedule_point()
	global_position = _target
	TimeManager.hour_changed.connect(func(_h): _target = _schedule_point())


func _schedule_point() -> Vector3:
	if schedule.is_empty():
		return global_position
	var h := TimeManager.hour()
	var pt: Vector3 = schedule[-1][1]
	for e in schedule:
		if h >= int(e[0]):
			pt = e[1]
	return pt


func can_interact(_actor: Node) -> bool:
	return visible

func interaction_point() -> Vector3:
	return model.global_position if model else global_position

func get_interaction_prompt(_actor: Node) -> String:
	var nm := NpcDB.display_name(npc_id)
	if GameState.quests.available_from(npc_id) != "":
		return "Talk to %s  (has a request)" % nm
	return "Talk to %s" % nm


func interact(actor: Node) -> void:
	_talking = 999.0
	if actor is Node3D:
		_face((actor as Node3D).global_position)
	model.play_action("wave", 0.8)
	if npc_id in ["poppy", "finn", "sumi", "ren"]:
		_talk_daily()
		return
	if not home_region.is_empty():
		_talk_host()
		return
	var res := GameState.quests.handle_talk(npc_id)
	var lines: Array = res.lines
	var offer: String = res.offer
	if offer != "":
		var on_choice := func(choice: int):
			_talking = 1.0
			if choice == 0:
				GameState.quests.start(offer)
			else:
				GameState.request_dialogue(["%s: Whenever you have time." % NpcDB.display_name(npc_id)])
		GameState.request_dialogue(lines, ["Of course!", "Maybe later"], on_choice)
		return
	if lines.is_empty():
		lines = [_idle_line()]
	var done := func(_c): _talking = 1.0
	GameState.request_dialogue(lines, [], done)


func _talk_daily() -> void:
	var child := npc_id in ["poppy", "finn"]
	var playtime: bool = daily_driver and daily_driver.residents[npc_id].phase == "play"
	var worktime: bool = daily_driver and daily_driver.residents[npc_id].phase == "work"
	var offer := "Join our game" if child else "Help together for a moment"
	var options: Array = [offer, "Just stopping to say hello"] if (playtime or worktime) else []
	GameState.request_dialogue([_idle_line()], options, func(choice: int):
		_talking = 0.0
		if choice == 0 and not options.is_empty():
			var ritual := daily_driver.world.get_node_or_null("TogetherMoments") as TogetherMoments
			if ritual: ritual.begin("play" if child else "help"))

func _talk_host() -> void:
	var place: Array = VillageLifeData.PLACES[home_region]
	var nm := NpcDB.display_name(npc_id)
	var state := GameState.world.get_state(object_id + "_friendship", {"days": 0, "last_day": -1})
	var greeting := "Welcome back, friends." if int(state.get("days", 0)) > 0 else "I'm %s, the %s. It's lovely to meet you both." % [nm, String(place[3]).to_lower()]
	GameState.request_dialogue([nm + ": " + greeting], ["About this place", "A thought for today", "Just saying hello"], func(choice: int):
		_talking = 1.0
		if choice < 0:
			return
		if int(state.get("last_day", -1)) != TimeManager.day:
			state.days = int(state.get("days", 0)) + 1
			state.last_day = TimeManager.day
			GameState.world.set_state(object_id + "_friendship", state)
			SaveManager.autosave("village_friend")
		var lines: Array = []
		if choice == 0:
			lines = [nm + ": " + String(place[5][0][1]) + ", " + String(place[5][1][1]).to_lower() + ", or " + String(place[5][2][1]).to_lower() + ".",
				nm + ": Each activity earns two thank-you coins once a day. Come back just for the company whenever you like."]
		elif choice == 1:
			lines = [nm + ": " + String(place[5][TimeManager.day % 3][3])]
		else:
			lines = [nm + ": A hello from you two always makes this place warmer. Thank you for stopping by."]
		GameState.request_dialogue(lines))


func _idle_line() -> String:
	var def := NpcDB.get_def(npc_id)
	var idle: Array = def.get("idle", ["Hello!"])
	var flags_line := _flag_line()
	if flags_line != "" and _idle_index % 2 == 0:
		_idle_index += 1
		return "%s: %s" % [NpcDB.display_name(npc_id), flags_line]
	var l := String(idle[_idle_index % idle.size()])
	_idle_index += 1
	return "%s: %s" % [NpcDB.display_name(npc_id), l]


## Lines that react to visible world progress (GDD Pillar C).
func _flag_line() -> String:
	var w := GameState.world
	if w.has_flag("festival"):
		return "The lanterns in the park... it feels like the whole village is smiling."
	if w.has_flag("bridge_restored") and npc_id in ["mira", "pip", "bao"]:
		return "The old bridge is back! I visited the orchard twice already."
	if w.has_flag("park_restored") and npc_id in ["elder", "rosa", "ivo", "tamsin"]:
		return "Did you see the new flower bed in the park? That was you two."
	if GameState.shop.level >= 1 and npc_id == "tamsin":
		return "Your stall looks wonderful. Customers keep asking about the order board."
	return ""


func say(text: String, dur: float = 3.0) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = dur


func _face(p: Vector3) -> void:
	var d := p - global_position
	if d.length() > 0.1:
		model.rotation.y = atan2(d.x, d.z)


func _physics_process(delta: float) -> void:
	if not visible: return
	_name_label.position = model.position + Vector3(0, 1.85 * model.scale.y, 0)
	_bubble.position = model.position + Vector3(0, 2.25 * model.scale.y, 0)
	_marker.position.x = model.position.x
	_marker.position.z = model.position.z
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			_bubble.visible = false
	if GameState.is_ui_blocking():
		_bubble.visible = false
		model.set_locomotion(0, 1, true)
		return
	_greet_cooldown -= delta
	var p := GameState.player as MnkiController
	if p and _greet_cooldown <= 0 and Time.get_ticks_msec() > next_greeting_ms and p.flight_mode == "grounded" and p.global_position.distance_to(global_position) < 3.8:
		_greet_cooldown = 100.0
		next_greeting_ms = Time.get_ticks_msec() + 18000
		var visited := GameState.world.has_flag("cozy_visit_" + home_region)
		say("Lovely to see you again!" if visited else "Hello, you two! A little rest is always welcome.", 3.5)
		model.play_action("wave", 0.8)
	if _talking > 0.0:
		if not GameState.is_ui_blocking():
			_talking -= delta
		model.set_locomotion(0, 1, true)
		return
	if daily_driver:
		daily_driver.step(self, delta)
		return
	var to := _target - global_position
	to.y = 0
	if to.length() < 0.3:
		model.set_locomotion(0, 1, true)
		_stuck_t = 0.0
		_activity_t -= delta
		if _activity_t <= 0 and not home_region.is_empty():
			_activity_t = 12.0 + float(npc_id.hash() % 8)
			_stroll_index = (_stroll_index + 1) % schedule.size()
			_target = schedule[_stroll_index][1]
			model.play_action("think", 1.5)
		return
	var spd := 1.6
	var direction := safe_direction(to.normalized())
	if direction == Vector3.ZERO:
		model.set_locomotion(0, 1, true)
		return
	global_position += direction * min(spd * delta, to.length())
	model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), 0.12)
	model.set_locomotion(spd, 3.0, true)

func safe_direction(desired: Vector3, reach: float = 0.65) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _probe
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.78, 0))
	query.collision_mask = 1 | 16 | 8 | 2 | 4
	query.exclude = [_body.get_rid()]
	var space := get_world_3d().direct_space_state
	for angle in [0.0, 35.0, -35.0, 70.0, -70.0]:
		var direction := desired.rotated(Vector3.UP, deg_to_rad(angle))
		query.motion = direction * reach
		var fractions := space.cast_motion(query)
		if fractions[0] >= 0.99:
			return direction
	return Vector3.ZERO
