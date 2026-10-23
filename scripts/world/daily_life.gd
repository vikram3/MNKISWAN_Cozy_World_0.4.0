class_name DailyLife
extends Node3D
## Clock-driven village routines. Long walks use shared collision-sampled A* routes.
var navigation := VillageNavigation.new()
var residents: Dictionary = {}
var homes: Array[Node3D] = []
var world: Node3D
var initialized := false
var _last_hour := -1
var _ball: Node3D
var _market_lights: Node3D
var _market_sign: Label3D
var _phase := 0.0
var _rebuilding := false
const MARKET_CREW := ["tamsin", "odo", "life_market_square", "life_tropical_forest", "life_village_park"]
const MARKET_GUESTS := ["nila", "arun", "ren", "life_colony_one", "life_colony_two"]

func _ready() -> void:
	name = "DailyLife"
	world = get_parent()
	add_child(navigation)
	_spawn_residents()
	_build_market()
	_ball = CharParts.sphere(self, 0.16, Color("eabf75"), _at("village_park", Vector3(7, 0.2, 4)), Vector3.ONE, 0)
	for n in get_tree().get_nodes_in_group("village_home"):
		homes.append(n)
	GameState.world.flag_set.connect(func(flag: String):
		if flag in ["gate_open", "bridge_restored"]: _rebuild.call_deferred())
	_initialize.call_deferred()

func _at(region: String, pos: Vector3) -> Vector3:
	return GameData.region_world_pos(region) + pos

func _spawn_residents() -> void:
	for id in DailyLifeData.RESIDENTS:
		var region := "village_park"
		var pos := Vector3(7, 0, 4)
		match id:
			"finn": pos = Vector3(6, 0, 6)
			"pearl": pos = Vector3(3, 0, 2.5)
			"rowan": pos = Vector3(4, 0, 2.5)
			"nila": region = "flower_garden"; pos = Vector3(-2, 0, 6)
			"arun": region = "flower_garden"; pos = Vector3(-1, 0, 6)
			"sumi": region = "paddy_field"; pos = Vector3(4.7, 0, -4)
			"ren": region = "tropical_forest"; pos = Vector3(4, 0, -3)
		world.regions[region].add_npc(id, [[6, pos]])

func _initialize() -> void:
	await get_tree().physics_frame
	navigation.rebuild(get_world_3d())
	for npc: NpcCharacter in get_tree().get_nodes_in_group("villager"):
		var reference_position: Vector3 = npc.schedule[0][1] if not npc.schedule.is_empty() else npc.global_position
		var home: Node3D = homes[0]
		var distance := INF
		for candidate in homes:
			var d := candidate.global_position.distance_squared_to(reference_position)
			if d < distance:
				distance = d
				home = candidate
		var door: Vector3 = home.to_global(Vector3(0, 0, 2.4))
		var door_id := navigation.nearest(door)
		if door_id.x >= 0: door = navigation.point(door_id)
		residents[npc.npc_id] = {"npc": npc, "home": home, "door": door, "work": reference_position,
			"phase": "", "status": "Waking up", "route": PackedVector3Array(), "index": 0,
			"sleeping": false, "fade": 1.0, "blocked": 0.0, "pose": "", "seat": Vector3.ZERO}
		npc.daily_driver = self
		if not home.has_meta("residents"): home.set_meta("residents", [])
		var names: Array = home.get_meta("residents")
		names.append(npc.npc_id)
		NPC_home_point(home, door)
	initialized = true
	sync_clock(true)

func NPC_home_point(home: Node3D, door: Vector3) -> void:
	if home.has_meta("door_point"): return
	home.set_meta("door_point", true)
	var point := ActionPoint.new().configure("home_" + str(homes.find(home)), func(): return "Visit the neighbours' door", func(_actor):
		var lines: Array = []
		for id in home.get_meta("residents", []):
			var state: Dictionary = residents[id]
			lines.append("Door: %s — %s." % [NpcDB.display_name(id), state.status])
		lines.append("Door: Everyone welcomes a visit during waking hours. The Village day panel shows where friends spend their day.")
		GameState.request_dialogue(lines), Callable(), 1.8, 1.6, 0)
	point.position = door
	add_child(point)

func _rebuild() -> void:
	if not initialized or _rebuilding: return
	_rebuilding = true
	await get_tree().physics_frame
	navigation.rebuild(get_world_3d())
	for state in residents.values():
		state.route = navigation.route(state.npc.global_position, state.goal)
		state.index = 0
	_rebuilding = false

func routine(id: String, hour: int) -> Dictionary:
	var state: Dictionary = residents[id]
	var work: Vector3 = state.work
	var target := work
	var phase := "work"
	var pose := "chat"
	var status := "Enjoying the neighbourhood"
	var seat := Vector3.ZERO
	var yaw := 0.0
	var child := id in ["poppy", "finn"]
	var late := id in MARKET_CREW or id in MARKET_GUESTS
	var bedtime := 20 if child else (24 if late else 21)
	var wake := 7 if child or late else 6
	if hour < wake or hour >= bedtime:
		return {"phase": "home", "target": state.door, "pose": "", "seat": seat, "yaw": 0.0, "status": "Heading home · asleep until %02d:00" % wake}
	if hour >= 18 and late:
		var index := MARKET_CREW.find(id) if id in MARKET_CREW else MARKET_GUESTS.find(id) + 5
		target = _at("market_square", [Vector3(-6.6, 0, 6.2), Vector3(7.6, 0, -1.4), Vector3(-1.5, 0, 10.9), Vector3(3.2, 0, -9.5), Vector3(3, 0, 6.5), Vector3(-2.4, 0, 1.5), Vector3(-1.4, 0, 1.5), Vector3(1.5, 0, -2), Vector3(4, 0, -2), Vector3(-4, 0, 3)][index])
		return {"phase": "market", "target": target, "pose": "dance" if id == "life_village_park" else "eat", "seat": seat, "yaw": 0.0, "status": "At the lantern market · open until midnight"}
	if hour >= 18:
		return {"phase": "supper", "target": state.door + Vector3(0, 0, 1), "pose": "eat", "seat": seat, "yaw": 180.0, "status": "Supper on the doorstep · bedtime at %02d:00" % bedtime}
	if child:
		phase = "play"
		status = "Playing catch in the park"
		pose = "play_ball"
		target = _at("village_park", Vector3(7.2, 0, 4) if id == "poppy" else Vector3(5.5, 0, 5.5))
		yaw = -45 if id == "poppy" else 135
		if hour >= 12 and hour < 14:
			pose = "eat"; status = "Lunch break at the playground"; phase = "lunch"
		elif id == "poppy" and hour >= 14:
			target = _at("village_park", Vector3(7.5, 0, 7)); seat = _at("village_park", Vector3(9, 0.43, 7)); pose = "sit"; phase = "swing"; status = "Taking a turn on the swing"; yaw = 0
		elif id == "finn" and hour >= 14:
			target = _at("village_park", Vector3(6.5, 0, 7)); pose = "wave"; phase = "watch_swing"; status = "Cheering Poppy on the swing"; yaw = 90
	elif id in ["pearl", "rowan", "elder"]:
		phase = "bench"; pose = "read" if id == "pearl" else "sit"; status = "Resting and sharing stories on a park bench"
		var a := PI / 4 if id != "elder" else PI * 5 / 4
		var center := _at("village_park", Vector3(cos(a), 0, sin(a)) * 4.8)
		yaw = rad_to_deg(-a) - 90
		var basis := Basis(Vector3.UP, deg_to_rad(yaw))
		var offset := -0.5 if id == "pearl" else (0.5 if id == "rowan" else 0.0)
		seat = center + basis.x * offset + Vector3(0, 0.25, 0)
		target = center + basis.x * offset + basis.z * 1.0
	elif id in ["nila", "arun"]:
		phase = "garden"; pose = "affection"; status = "A quiet garden date with " + ("Arun" if id == "nila" else "Nila")
		target = _at("flower_garden", Vector3(-2.5, 0, 5.2) if id == "nila" else Vector3(-1.4, 0, 5.2))
		yaw = 90 if id == "nila" else -90
		if hour < 12:
			phase = "craft"; pose = "farm"; status = "Tending flowers together"
	elif id in ["bao", "sumi", "ren", "life_paddy_field", "life_tropical_forest", "rosa", "ivo", "thronn", "life_animal_farm"]:
		phase = "work"; pose = "farm"; status = "Tending the garden" if id in ["rosa", "ivo"] else "Working gently in the fields"
		if id in ["thronn", "life_animal_farm"]: pose = "feed"; status = "Caring for the farm animals"
		if hour >= 12 and hour < 14: pose = "eat"; status = "Taking a lunch break"; phase = "lunch"
		if hour >= 16: pose = "chat"; status = "Work finished · a little time to rest"; phase = "rest"
	else:
		var npc: NpcCharacter = state.npc
		target = npc._schedule_point()
		if id == "lumi": pose = "fish"; status = "Watching the pond"
		elif id in ["tamsin", "odo"]: pose = "chat"; status = "Welcoming customers"
	return {"phase": phase, "target": target, "pose": pose, "seat": seat, "yaw": yaw, "status": status}

func sync_clock(snap: bool = false) -> void:
	if not initialized: return
	_last_hour = TimeManager.hour()
	for id in residents:
		var state: Dictionary = residents[id]
		var plan := routine(id, _last_hour)
		var npc: NpcCharacter = state.npc
		if not snap and state.phase == plan.phase and state.goal.distance_to(plan.target) < 0.1: continue
		state.phase = plan.phase
		state.goal = plan.target
		state.pose = plan.pose
		state.seat = plan.seat
		state.yaw = plan.yaw
		state.status = plan.status
		state.arrived = false
		state.blocked = 0.0
		npc.model.clear_action()
		npc._body.collision_layer = 8
		if state.sleeping:
			npc.global_position = state.door
			npc.show()
			state.sleeping = false
			npc._body.collision_layer = 8
		state.route = navigation.route(npc.global_position, plan.target)
		state.index = 0
		if snap:
			var cell := navigation.nearest(plan.target)
			if cell.x >= 0: npc.global_position = navigation.point(cell)
			state.route = PackedVector3Array()
			state.arrived = true
			if state.phase == "home": _sleep(state)
	_update_market()

func step(npc: NpcCharacter, delta: float) -> void:
	if not initialized or not residents.has(npc.npc_id): return
	var s: Dictionary = residents[npc.npc_id]
	if s.sleeping: return
	if s.phase == "home" and s.arrived:
		s.fade = maxf(0, s.fade - delta * 2)
		npc.model.set_opacity(s.fade)
		if s.fade <= 0: _sleep(s)
		return
	s.fade = minf(1, s.fade + delta * 2)
	npc.model.set_opacity(s.fade)
	var route: PackedVector3Array = s.route
	if int(s.index) < route.size():
		var to := route[s.index] - npc.global_position
		to.y = 0
		if to.length() < 0.18:
			s.index += 1
			return
		var direction := npc.safe_direction(to.normalized(), minf(to.length(), 0.14))
		if direction.dot(to.normalized()) < 0.3: direction = Vector3.ZERO
		if direction == Vector3.ZERO:
			s.blocked += delta
			npc.model.set_locomotion(0, 3, true)
			if s.blocked > 2.0:
				var occupied: Array[Vector3] = []
				for other in residents.values():
					if other.npc != npc and other.npc.visible and other.npc._body.collision_layer != 0:
						occupied.append(other.npc.global_position)
				var alternate := navigation.route_avoiding(npc.global_position, s.goal, occupied)
				if not alternate.is_empty(): s.route = alternate; s.index = 0
				s.blocked = 0
			return # no teleporting through obstacles
		var speed := 1.25 if npc.npc_id in ["elder", "pearl", "rowan"] else 2.0
		npc.global_position += direction * minf(speed * delta, to.length())
		npc.model.position = npc.model.position.lerp(Vector3.ZERO, 1 - exp(-10 * delta))
		npc.model.rotation.y = lerp_angle(npc.model.rotation.y, atan2(direction.x, direction.z), 1 - exp(-10 * delta))
		npc.model.set_locomotion(speed, 3, true)
		npc.model.clear_action()
		npc._body.collision_layer = 8
		s.blocked = 0.0
		return
	if route.is_empty() and not s.arrived and npc.global_position.distance_to(s.goal) > 3:
		s.status = "Waiting for a clear path · " + String(routine(npc.npc_id, _last_hour).status)
		return
	s.arrived = true
	npc.model.set_locomotion(0, 3, true)
	if npc.model.action != s.pose: npc.model.play_action(s.pose, -1)
	var offset := Vector3.ZERO
	if s.seat != Vector3.ZERO:
		offset = s.seat - npc.global_position
		if s.phase == "swing":
			var angle := sin(_phase * 1.8) * 0.25
			offset += Vector3(0, 1.75 * (1 - cos(angle)), -sin(angle) * 1.75)
	npc.model.position = npc.model.position.lerp(offset, 1 - exp(-5 * delta))
	npc.model.rotation.y = lerp_angle(npc.model.rotation.y, deg_to_rad(s.yaw), 1 - exp(-5 * delta))
	npc._body.collision_layer = 0 if s.seat != Vector3.ZERO else 8

func _sleep(s: Dictionary) -> void:
	s.sleeping = true
	s.status = "Sleeping at home"
	s.npc.hide()
	s.npc._body.collision_layer = 0
	s.npc.model.clear_action()

func status_for(id: String) -> String:
	return String(residents[id].status) if residents.has(id) else "In the village"

func _process(delta: float) -> void:
	if not initialized or GameState.is_ui_blocking(): return
	if _last_hour != TimeManager.hour(): sync_clock()
	if not bool(Settings.get_value("reduced_motion")): _phase += delta
	var playing := TimeManager.hour() >= 8 and TimeManager.hour() < 12 and bool(residents.poppy.arrived) and bool(residents.finn.arrived)
	_ball.visible = playing
	if playing:
		var t := (sin(_phase * 1.7) + 1) * 0.5
		_ball.position = _at("village_park", Vector3(7.2, 0.75, 4).lerp(Vector3(5.5, 0.75, 5.5), t) + Vector3(0, sin(t * PI) * 1.0, 0))
	var park: Node3D = world.regions.village_park
	if park.get("swing_pivot"):
		park.swing_pivot.rotation.x = sin(_phase * 1.8) * 0.25 if TimeManager.hour() >= 14 and TimeManager.hour() < 18 else 0.0

func _build_market() -> void:
	_market_lights = Node3D.new()
	_market_lights.position = GameData.region_world_pos("market_square")
	add_child(_market_lights)
	for x in [-5, 0, 5]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 3, 1)
		light.light_color = Color("ffd59a")
		light.light_energy = 0.9
		light.omni_range = 8
		_market_lights.add_child(light)
	_market_sign = EnvKit.label3d(self, "", _at("market_square", Vector3(0, 2.1, -10)), 38, Color("ffe1a5"), true)
	_market_sign.visibility_range_end = 22
	_update_market()

func _update_market() -> void:
	var open := DailyLifeData.market_open(TimeManager.hour())
	_market_lights.visible = open
	_market_sign.text = "LANTERN MARKET · 18:00–00:00\nWarm food · music · company" if open else "Lantern market opens at 18:00"
