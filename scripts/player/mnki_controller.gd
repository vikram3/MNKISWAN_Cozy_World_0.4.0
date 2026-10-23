class_name MnkiController
extends CharacterBody3D
## Player-controlled Mnki (GDD §9.1 / §23): locomotion, camera, interaction kept separate.
## Camera-relative, normalised input; smoothed acceleration/braking/turning; gentle jump;
## last-safe-ground recovery; all physics in _physics_process.

@export var walk_speed := 3.6
@export var run_speed := 6.2
@export var accel := 16.0
@export var brake := 22.0
@export var gravity := 15.0
@export var jump_velocity := 5.3
@export var turn_rate := 12.0

signal character_changed(character_id: String)

# One input/camera owner; the two existing models and positions trade roles.
var character_id := "mnki"
var flight_mode := "grounded"  # grounded | flying | landing
var flight_speed := 7.0
var flight_ceiling := 24.0
var _flight_time := 0.0
var model: CharModel
var rig: CameraRig
var scanner: InteractionScanner
var state := "free"      # free | fishing | locked
var fishing_spot: FishingSpot = null
var _facing := Vector3(0, 0, 1)
var _safe_pos := Vector3.ZERO
var _safe_t := 0.0
var _run_toggled := false
var _region := ""
var _region_t := 0.0
var _rod: Node3D
var _step_t := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8 | 16
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.35
	cs.shape = cap
	cs.position.y = 0.675
	add_child(cs)
	model = MnkiModel.new()
	model.name = "MnkiModel"
	add_child(model)
	# Fishing rod (hidden until fishing), held in the right hand
	_rod = Node3D.new()
	_rod.position = Vector3(-0.02, -0.3, 0.02)
	_rod.rotation_degrees = Vector3(-60, 0, 0)
	model.arm_r.add_child(_rod)
	CharParts.add(_rod, CharParts.cyl_mesh(0.012, 0.02, 1.3, 6), CharParts.mat(EnvKit.WOOD, 0.006), Vector3(0, 0.6, 0))
	_rod.visible = false
	scanner = InteractionScanner.new()
	scanner.actor = self
	add_child(scanner)
	rig = CameraRig.new()
	add_child(rig)
	rig.attach(self)
	_safe_pos = global_position
	GameState.player = self


func facing_direction() -> Vector3:
	return _facing


func get_safe_position() -> Vector3:
	return _safe_pos


func get_region_id() -> String:
	return _region


func play_action(a: String, dur: float) -> void:
	model.play_action(a, dur)


func face_towards(p: Vector3) -> void:
	var d := p - global_position
	d.y = 0
	if d.length() > 0.05:
		_facing = d.normalized()
		model.rotation.y = atan2(_facing.x, _facing.z)


func teleport(p: Vector3, yaw_deg: float = 0.0) -> void:
	flight_mode = "grounded"
	if model is SwanModel:
		(model as SwanModel).flight_blend = 0.0
	global_position = p
	velocity = Vector3.ZERO
	_safe_pos = p
	model.rotation.y = deg_to_rad(yaw_deg)
	_facing = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	rig.global_position = p + Vector3(0, 1.25, 0)
	rig.set_yaw_deg(yaw_deg + 180.0)


# --- Fishing hooks ------------------------------------------------------------------------------

func begin_fishing(spot: FishingSpot) -> void:
	state = "fishing"
	fishing_spot = spot
	velocity = Vector3.ZERO
	face_towards(spot.water_point())
	_rod.visible = true
	model.play_action("fish_cast", 0.6)
	get_tree().create_timer(0.6).timeout.connect(_hold_rod)


func _hold_rod() -> void:
	if state == "fishing":
		model.play_action("fish", -1.0)


func end_fishing() -> void:
	state = "free"
	fishing_spot = null
	_rod.visible = false
	if model.action in ["fish", "fish_cast"]:
		model.clear_action()


func rod_tip() -> Vector3:
	return _rod.to_global(Vector3(0, 1.25, 0))


# --- Input --------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_ui_blocking() or state == "locked":
		return
	if event.is_action_pressed("switch_character"):
		switch_character()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fly"):
		toggle_flight()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		if state == "fishing" and fishing_spot:
			fishing_spot.press()
		elif state == "free" and flight_mode == "grounded" and not model.is_busy():
			scanner.try_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel") and state == "fishing" and fishing_spot:
		fishing_spot.cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_seed"):
		GameState.cycle_seed()
	elif event.is_action_pressed("run") and Settings.get_value("run_toggle"):
		_run_toggled = not _run_toggled


func _physics_process(delta: float) -> void:
	if flight_mode != "grounded":
		_fly_physics(delta)
		_update_region()
		return
	var blocked := GameState.is_ui_blocking() or state != "free" or (model.is_busy() and model.action not in ["celebrate", "wave"])
	var input := Vector2.ZERO
	if not blocked:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input.length() > 1.0:
			input = input.normalized()  # diagonal is never faster
	# Moving cancels fishing calmly.
	if state == "fishing" and not GameState.is_ui_blocking():
		var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if mv.length() > 0.5 and fishing_spot and fishing_spot.state in ["waiting", "casting"]:
			fishing_spot.cancel()
	var cam_basis := rig.flat_basis()
	var dir := cam_basis * Vector3(input.x, 0, input.y)
	var running := Input.is_action_pressed("run") if not Settings.get_value("run_toggle") else _run_toggled
	var target_speed := (run_speed if running else walk_speed) * dir.length()
	var hv := Vector3(velocity.x, 0, velocity.z)
	if dir.length() > 0.01:
		hv = hv.move_toward(dir.normalized() * target_speed, accel * delta)
		_facing = _facing.slerp(dir.normalized(), clampf(turn_rate * delta, 0.0, 1.0)).normalized()
		model.rotation.y = atan2(_facing.x, _facing.z)
	else:
		hv = hv.move_toward(Vector3.ZERO, brake * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif not blocked and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	move_and_slide()
	model.set_locomotion(hv.length(), run_speed, is_on_floor())
	# Footstep ticks
	if is_on_floor() and hv.length() > 0.5:
		_step_t -= delta * hv.length()
		if _step_t <= 0.0:
			_step_t = 1.6
			AudioManager.play_sfx("step", randf_range(0.85, 1.15))
	# Safe ground & fall recovery (GDD §8 failure philosophy)
	_safe_t -= delta
	if is_on_floor() and _safe_t <= 0.0:
		_safe_t = 0.5
		_safe_pos = global_position
	if global_position.y < -12.0:
		teleport(_safe_pos + Vector3(0, 0.5, 0), rad_to_deg(model.rotation.y))
		GameState.notify("Whoops! Back on solid ground.", "info")
	# Region discovery
	_region_t -= delta
	if _region_t <= 0.0:
		_region_t = 0.4
		_update_region()


func switch_character(restoring: bool = false) -> bool:
	var friend := GameState.swan as SwanCompanion
	if friend == null:
		return false
	if not restoring and (GameState.is_ui_blocking() or state != "free" or model.is_busy()):
		return false
	if not restoring and (flight_mode != "grounded" or not is_on_floor() or not friend.is_on_floor()):
		GameState.notify("Land on solid ground to switch friends.", "info")
		return false
	var old_model := model
	var old_position := global_position
	model = friend.model
	friend.model = old_model
	old_model.reparent(friend, false)
	model.reparent(self, false)
	_rod.reparent(model.arm_r, false)
	global_position = friend.global_position
	friend.global_position = old_position
	velocity = Vector3.ZERO
	friend.velocity = Vector3.ZERO
	friend.state = "follow"
	friend._retarget_t = 0.0
	friend._bubble.visible = false
	character_id = "swan" if character_id == "mnki" else "mnki"
	_safe_pos = global_position
	_facing = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	_run_toggled = false
	scanner.clear()
	character_changed.emit(character_id)
	if not restoring:
		GameState.notify("Playing as %s" % character_id.capitalize(), "discovery")
		AudioManager.play_sfx("chime")
	return true


func toggle_flight() -> bool:
	if GameState.is_ui_blocking() or state != "free" or model.is_busy():
		return false
	if character_id != "swan":
		GameState.notify("Switch to Swan to spread your wings.", "info")
		return false
	if flight_mode != "grounded":
		flight_mode = "flying" if flight_mode == "landing" else "landing"
		return true
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, global_position + Vector3.UP * 3.0, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		GameState.notify("Find an open space to spread your wings.", "info")
		return false
	flight_mode = "flying"
	_flight_time = 0.0
	velocity.y = 4.2
	scanner.clear()
	model.clear_action()
	GameState.notify("Spread your wings! Space to rise · Ctrl to descend · F to land", "discovery")
	AudioManager.play_sfx("chime")
	return true


func _fly_physics(delta: float) -> void:
	if GameState.is_ui_blocking():
		velocity = Vector3.ZERO
		return
	_flight_time += delta
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := rig.flat_basis() * Vector3(input.x, 0, input.y)
	var speed := flight_speed * (1.55 if Input.is_action_pressed("run") else 1.0)
	velocity.x = move_toward(velocity.x, dir.x * speed, 12.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 12.0 * delta)
	var vertical := Input.get_action_strength("jump") - Input.get_action_strength("descend")
	var lift := vertical * 4.5
	if _flight_time < 0.4:
		lift = 4.2
	if flight_mode == "landing":
		lift = -3.0
	if global_position.y > flight_ceiling - 1.5:
		lift = minf(lift, (flight_ceiling - global_position.y) * 2.0)
	velocity.y = move_toward(velocity.y, lift, 9.0 * delta)
	if dir.length() > 0.1:
		_facing = _facing.slerp(dir.normalized(), minf(delta * 6.0, 1.0)).normalized()
		model.rotation.y = atan2(_facing.x, _facing.z)
	move_and_slide()
	# Flight obeys scene collisions and the village bounds even above the forest wall.
	global_position.x = clampf(global_position.x, -61.0, 61.0)
	global_position.z = clampf(global_position.z, -103.0, 109.0)
	model.set_locomotion(Vector2(velocity.x, velocity.z).length(), speed, false)
	var sw := model as SwanModel
	sw.flight_blend = 1.0
	sw.flight_lift = lift
	sw.flight_bank = clampf(-input.x * 0.16, -0.16, 0.16)
	if is_on_floor() and _flight_time > 0.55 and (flight_mode == "landing" or vertical < 0):
		flight_mode = "grounded"
		velocity = Vector3.ZERO
		_safe_pos = global_position
		sw.flight_blend = 0.0
		sw.flight_bank = 0.0
		GameState.notify("A soft landing.", "info")


func _update_region() -> void:
	var p := Vector2(global_position.x, global_position.z)
	var best := ""
	var best_d := INF
	for id in GameData.REGIONS:
		var r: Dictionary = GameData.REGIONS[id]
		var c: Vector2 = r.pos
		var s: Vector2 = r.size
		var local := (p - c).abs()
		if local.x <= s.x * 0.5 and local.y <= s.y * 0.5:
			var d := p.distance_to(c)
			if d < best_d:
				best_d = d
				best = id
	if best != _region:
		_region = best
		if best != "":
			if GameState.world.discover_region(best):
				GameState.notify("Discovered: " + String(GameData.REGIONS[best].name), "discovery")
				AudioManager.play_sfx("chime")
				GameState.companion("region_discovered", {"region": best})
		GameState.emit_signal("journal_changed")
