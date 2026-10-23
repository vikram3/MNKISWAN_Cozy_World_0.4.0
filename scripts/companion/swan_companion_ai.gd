class_name SwanCompanion
extends CharacterBody3D
## Swan companion state machine (GDD §5, §16): Follow → Wait → React → Recover.
## Follows a point behind/beside Mnki (recomputed at an interval, never the exact player
## position), waits at a non-blocking point during fishing/shopping/dialogue, reacts sparingly
## with cooldowns, and recovers out of view if stuck. Recoveries are logged for debugging.

var model: CharModel
var state := "follow"
var _follow_target := Vector3.ZERO
var _retarget_t := 0.0
var _react_t := 0.0
var _cooldowns: Dictionary = {}
var _global_cd := 0.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _bubble: Label3D
var _bubble_t := 0.0
var _talk: ActionPoint
var _hint_i := 0
var _wait_point := Vector3.ZERO
var _wait_until_free := false

const REGION_LINES := {
	"sunshine_forest": "Morning light through the leaves... my favourite.",
	"waterfall_ponds": "Listen to the falls! Lumi usually fishes here.",
	"berry_maze": "The Berry Maze! Short paths, I promise.",
	"flower_garden": "Rosa and Ivo have been busy. Look at the colours!",
	"paddy_field": "Bao's plots. We could grow our own rice.",
	"tropical_forest": "It smells like mangoes here. Pip lost something around here once...",
	"animal_farm": "Thronn! And the animals!",
	"guardian_gate": "Land, Water, Forest. They always look so calm.",
	"village_park": "The park. Elder Maple's home is just there.",
	"treehouse": "Home.",
	"colony_one": "The lanterns in Colony One are so pretty at night.",
	"colony_two": "Careful on the bridges — they sway a little.",
	"market_square": "Our stall! It's under the red canopy.",
}


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 16
	floor_snap_length = 0.4
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.3
	cs.shape = cap
	cs.position.y = 0.65
	add_child(cs)
	model = SwanModel.new()
	model.name = "SwanModel"
	add_child(model)
	_bubble = EnvKit.label3d(self, "", Vector3(0, 2.05, 0), 30, Color("3b2a1e"), true)
	_bubble.width = 620
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.visible = false
	_talk = ActionPoint.new().configure("swan_talk", func(): return "Talk to " + companion_name(), _on_talk, Callable(), 2.2, 2.0, 4)
	add_child(_talk)
	GameState.swan = self
	GameState.companion_event.connect(_on_event)
	GameState.quests.quest_completed.connect(func(id): _on_event("quest_completed", {"id": id}))
	GameState.shop.shop_transaction_completed.connect(func(total, _i): _on_event("sale", {"total": total}))
	GameState.shop.stall_upgraded.connect(func(lvl): _on_event("stall_upgraded", {"level": lvl}))
	GameState.world.flag_set.connect(func(f): _on_event("flag", {"flag": f}))
	TimeManager.day_started.connect(func(d): _on_event("morning", {"day": d}))


func _player() -> MnkiController:
	return GameState.player as MnkiController


func companion_name() -> String:
	return "Mnki" if model is MnkiModel else "Swan"


# --- Talking ------------------------------------------------------------------------------------

func _on_talk(_actor: Node) -> void:
	var p := _player()
	if p:
		model.rotation.y = atan2(p.global_position.x - global_position.x, p.global_position.z - global_position.z)
	model.play_action("wave", 0.8)
	var res := GameState.quests.handle_talk("swan")
	if not (res.lines as Array).is_empty():
		var lines: Array = []
		for line in res.lines:
			lines.append(String(line).replace("Swan:", companion_name() + ":"))
		GameState.request_dialogue(lines)
		return
	GameState.request_dialogue([_hint_line().replace("Swan:", companion_name() + ":")])


func _hint_line() -> String:
	_hint_i += 1
	var q := GameState.quests.tracked_quest()
	if q != "" and _hint_i % 3 != 0:
		var t := GameState.quests.objective_text(q)
		return "Swan: Next, shall we... %s? No rush, though." % (t.substr(0, 1).to_lower() + t.substr(1))
	var lines := [
		"Swan: I like days like this. Nothing urgent, just us and the village.",
		"Swan: If you get tired, the bed upstairs is very good at being a bed.",
		"Swan: Press J for the journal, M for the map. I drew the map. Mostly.",
		"Swan: Market orders change every morning once the stall has an order board.",
		"Swan: The tail is doing the happy swish again.",
	]
	if GameState.world.has_flag("festival"):
		lines.append("Swan: Thank you for today. All of it.")
	return String(lines[_hint_i % lines.size()])


# --- Reactions (sparse, with cooldowns) --------------------------------------------------------

func _on_event(ev: String, data: Dictionary) -> void:
	var line := ""
	var act := "celebrate"
	match ev:
		"region_discovered":
			line = REGION_LINES.get(String(data.get("region", "")), "")
			act = "wave"
		"first_fish":
			line = "Your first fish! A %s! I knew you could." % ItemDB.display_name(String(data.get("fish", "")))
		"first_care":
			line = "Gentle hands. The %s likes you." % String(data.get("species", "animal"))
		"first_harvest":
			line = "We grew that! Ourselves!"
		"rare_find":
			line = "Ooh — a %s! That's a rare one." % ItemDB.display_name(String(data.get("item", "")))
			act = "surprised"
		"decor_placed":
			line = "It looks perfect there."
			act = "wave"
		"sale":
			if GameState.shop.sales_count == 1:
				line = "Our first sale! %d coins! Let's put some back into the stall." % int(data.get("total", 0))
			elif _ready_cd("sale", 120.0):
				line = ["Another happy customer!", "The stall looks fuller already.", "Fresh fruit, happy village."][randi() % 3]
		"stall_upgraded":
			line = "Look at our stall now!"
		"quest_completed":
			act = "celebrate"
			if _ready_cd("quest", 5.0):
				line = ["That felt good.", "One more friend helped!", "The village feels kinder already."][randi() % 3]
		"flag":
			match String(data.get("flag", "")):
				"park_restored": line = "Flowers in the park again!"
				"bridge_restored": line = "The bridge! We did it!"
				"festival": line = "Lanterns everywhere... it's beautiful."
		"morning":
			if _ready_cd("morning", 1.0):
				line = ["Good morning! Did you sleep well?", "Morning! The plots will have grown if we watered them.", "A new day. What shall we do first?"][int(data.get("day", 0)) % 3]
				act = "wave"
		"player_fishing":
			_enter_wait()
			return
	if line == "":
		return
	if ev != "region_discovered" or _ready_cd("region", 20.0):
		say(line)
		model.play_action(act, 1.2)


func _ready_cd(key: String, seconds: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < float(_cooldowns.get(key, -999.0)):
		return false
	_cooldowns[key] = now + seconds
	return true


func say(text: String, dur: float = 3.5) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = dur


# --- Movement state machine ---------------------------------------------------------------------

func _enter_wait(still: bool = false) -> void:
	var p := _player()
	if p == null:
		return
	state = "wait"
	if still:
		_wait_point = global_position
		return
	var right := p.facing_direction().cross(Vector3.UP).normalized()
	_wait_point = p.global_position - right * 2.2 - p.facing_direction() * 1.0
	_wait_until_free = true


func _physics_process(delta: float) -> void:
	# Expire speech even while a menu is open or Swan is flying.
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			_bubble.visible = false
	var p := _player()
	if p == null:
		return
	if GameState.is_ui_blocking() or state == "together":
		velocity = Vector3.ZERO
		model.set_locomotion(0.0, 6.2, is_on_floor())
		return
	# Mnki waits safely below while Swan flies; never teleport the ground companion into the sky.
	if p.flight_mode != "grounded":
		velocity.x = move_toward(velocity.x, 0.0, delta * 18.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 18.0)
		velocity.y -= 15.0 * delta
		move_and_slide()
		model.set_locomotion(0.0, 6.2, is_on_floor())
		return
	var busy_ui := GameState.is_ui_blocking() and GameState.top_ui() in ["shop", "dialogue", "storage"]
	if state == "follow" and (busy_ui or p.state == "fishing"):
		_enter_wait(GameState.top_ui() == "dialogue" or global_position.distance_to(p.global_position) > 5.0)
	elif state == "wait" and not busy_ui and p.state != "fishing":
		state = "follow"
	var goal := Vector3.ZERO
	var speed := 0.0
	match state:
		"wait":
			goal = _wait_point
		_:
			_retarget_t -= delta
			if _retarget_t <= 0.0:
				_retarget_t = 0.3
				var f := p.facing_direction()
				var left := Vector3.UP.cross(f).normalized()
				# beside and slightly behind: visible in frame, never between camera and Mnki
				_follow_target = p.global_position + left * 1.5 - f * 0.4
			goal = _follow_target
	var to := goal - global_position
	to.y = 0
	var dist := to.length()
	var pdist := global_position.distance_to(p.global_position)
	if dist > 0.45:
		speed = 3.4 if dist < 4.0 else (6.6 if dist < 14.0 else 8.0)
		speed = minf(speed, dist * 4.0)
	var hv := Vector3(velocity.x, 0, velocity.z)
	var want := (to.normalized() * speed) if speed > 0.0 else Vector3.ZERO
	hv = hv.move_toward(want, 18.0 * delta)
	# Don't crowd Mnki: steer away when too close.
	if pdist < 0.9:
		var away := global_position - p.global_position
		away.y = 0
		if away.length() > 0.01:
			hv += away.normalized() * 2.0
	velocity.x = hv.x
	velocity.z = hv.z
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	elif p.velocity.y > 3.0 and pdist < 3.0:
		velocity.y = 4.6  # joyful hop alongside
	move_and_slide()
	if hv.length() > 0.2:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(hv.x, hv.z), 1.0 - exp(-9.751 * delta))
	elif state == "wait" or pdist < 4.0:
		var lp := p.global_position - global_position
		model.rotation.y = lerp_angle(model.rotation.y, atan2(lp.x, lp.z), 1.0 - exp(-3.078 * delta))
	model.set_locomotion(hv.length(), 6.2, is_on_floor())
	_recover_check(delta, p, dist, pdist)


func _recover_check(delta: float, p: MnkiController, dist: float, pdist: float) -> void:
	if dist > 1.0 and global_position.distance_to(_last_pos) < 0.02:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta, 0.0)
	_last_pos = global_position
	var need := (_stuck_t > 2.5 and pdist > 3.0) or pdist > 26.0 or global_position.y < -10.0
	if not need:
		return
	# Rejoin behind the player, preferably out of the camera's view (visible teleporting is a defect).
	var cam := get_viewport().get_camera_3d()
	var f := p.facing_direction()
	var candidates := [p.global_position - f * 2.5, p.global_position - f * 2.0 + f.cross(Vector3.UP) * 1.5, p.global_position + f.cross(Vector3.UP) * 2.0]
	var chosen: Vector3 = candidates[0]
	for c in candidates:
		if cam == null or not cam.is_position_in_frustum(c + Vector3(0, 0.8, 0)):
			chosen = c
			break
	if cam and cam.is_position_in_frustum(global_position + Vector3(0, 0.8, 0)) and pdist < 26.0 and global_position.y > -10.0:
		return  # wait until she is off-screen before recovering
	# Development log for every recovery (GDD §16) — stuck recoveries are warnings worth fixing.
	if _stuck_t > 2.5:
		push_warning("Swan companion recovered from a stuck position %s (dist %.1f)" % [global_position, pdist])
	else:
		print_verbose("[Swan] rejoined from %.1f m away" % pdist)
	global_position = chosen + Vector3(0, 0.3, 0)
	velocity = Vector3.ZERO
	_stuck_t = 0.0
