extends Node3D
## TreeVillageWorld — assembles the compact connected village (GDD §7, §15 example scene tree):
## WorldEnvironment, sun/day cycle, ground & paths, 13 region modules, NPCs/animals, player,
## companion, the restoration stream bridge and the UI host.

const REGION_SCENES := "res://scenes/regions/%s.tscn"
const PLAYER_SCENE := "res://scenes/characters/mnki.tscn"
const SWAN_SCENE := "res://scenes/characters/swan_companion.tscn"
const UI_SCENE := "res://scenes/ui/ui_root.tscn"

const BOUNDS_MIN := Vector2(-62, -104)
const BOUNDS_MAX := Vector2(62, 110)
const STREAM_Z := Vector2(12, 78)
const BRIDGE_Z := 60.0

var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var npc_root: Node3D
var regions: Dictionary = {}
var player: MnkiController
var swan: SwanCompanion
var ui: Node
var _bridge_broken: Node3D
var _bridge_fixed: Node3D
var _bridge_block: StaticBody3D
var _bridge_body: StaticBody3D


func _ready() -> void:
	GameState.in_world = true
	_build_environment()
	add_child(VillageBackdrop.new())
	_build_ground()
	npc_root = Node3D.new()
	npc_root.name = "NPCs"
	add_child(npc_root)
	var loading := not SaveManager.pending_load.is_empty()
	if loading:
		SaveManager.apply_pending_load()   # state first, so regions build in the right state
	_build_regions()
	_build_stream_and_bridge()
	_build_scatter()
	add_child(VillageLife.new())
	_spawn_characters(loading)
	add_child(SkyTrail.new())
	ui = load(UI_SCENE).instantiate()
	add_child(ui)
	GameState.ui = ui
	add_child(CoupleConversations.new())
	add_child(DailyLife.new())
	add_child(TogetherMoments.new())
	GameState.shop.ensure_orders()
	GameState.world.flag_set.connect(_on_flag)
	TimeManager.running = true
	AudioManager.start_world_audio()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if loading:
		SaveManager.clear_pending()
		GameState.notify("Welcome back! Day %d." % TimeManager.day, "info")
	else:
		_start_new_story()
	_update_daylight()


func _exit_tree() -> void:
	GameState.in_world = false
	GameState.player = null
	GameState.swan = null
	GameState.ui = null
	TimeManager.running = false


func _start_new_story() -> void:
	# First minutes: control is given immediately (no long cinematic — GDD §10).
	GameState.world.discover_region("sunshine_forest")
	GameState.begin_new_story()
	await get_tree().create_timer(0.8).timeout
	swan.say("Good morning! Come say hi — press E near me.", 6.0)


# --- Environment & day cycle ---------------------------------------------------------------------

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("8ccbe8")
	sky_mat.sky_horizon_color = Color("f6e9cf")
	sky_mat.ground_horizon_color = Color("e8dcc0")
	sky_mat.ground_bottom_color = Color("9fbf86")
	sky_mat.sun_angle_max = 20.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.85
	env.ssao_enabled = true
	env.ssao_intensity = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("e9eef0")
	env.fog_density = 0.004
	env.fog_sky_affect = 0.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	sun.light_energy = 1.1
	add_child(sun)


func _process(_delta: float) -> void:
	_update_daylight()


func _update_daylight() -> void:
	var m := TimeManager.minute
	var day_t := clampf((m - 330.0) / (1230.0 - 330.0), 0.0, 1.0)   # 5:30 → 20:30
	var is_day := m >= 330.0 and m <= 1230.0
	var elev := sin(day_t * PI)
	var night_k := 0.0
	if not is_day:
		night_k = 1.0
	elif day_t < 0.08:
		night_k = 1.0 - day_t / 0.08
	elif day_t > 0.92:
		night_k = (day_t - 0.92) / 0.08
	var golden := clampf(1.0 - elev * 1.6, 0.0, 1.0)
	if is_day:
		sun.rotation = Vector3(-deg_to_rad(10.0 + 60.0 * elev), deg_to_rad(-60.0 + 120.0 * day_t), 0.0)
		sun.light_color = Color("fff4e0").lerp(Color("ffb877"), golden * 0.8)
		sun.light_energy = lerpf(0.65, 0.25, night_k)
	else:
		sun.rotation = Vector3(-deg_to_rad(50.0), deg_to_rad(30.0), 0.0)
		sun.light_color = Color("9fb4ff")
		sun.light_energy = 0.28
	sky_mat.sky_top_color = Color("8ccbe8").lerp(Color("f2a76d"), golden * 0.35).lerp(Color("1c2a4a"), night_k)
	sky_mat.sky_horizon_color = Color("f6e9cf").lerp(Color("f6b98a"), golden * 0.6).lerp(Color("3a3f63"), night_k)
	env.ambient_light_energy = lerpf(0.32, 0.3, night_k)
	env.fog_light_color = Color("e9eef0").lerp(Color("3a4566"), night_k)
	for l in get_tree().get_nodes_in_group("night_light"):
		var ol: OmniLight3D = l
		ol.light_energy = night_k * 1.4


# --- Ground, paths, boundary ---------------------------------------------------------------------

func _build_ground() -> void:
	var size := BOUNDS_MAX - BOUNDS_MIN + Vector2(40, 40)
	var center := (BOUNDS_MAX + BOUNDS_MIN) * 0.5
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	g.mesh = pm
	g.material_override = EnvKit.ground_material()
	g.position = Vector3(center.x, 0, center.y)
	g.name = "Ground"
	add_child(g)
	var sb := EnvKit.body(self, Vector3(center.x, -0.5, center.y))
	sb.name = "GroundBody"
	EnvKit.add_box_shape(sb, Vector3(size.x, 1.0, size.y))
	var paths := Node3D.new()
	paths.name = "GroundAndPaths"
	add_child(paths)
	for pair in GameData.PATHS:
		EnvKit.path_segment(paths, GameData.region_world_pos(pair[0]), GameData.region_world_pos(pair[1]), 3.0)
	# Old-bridge route: Colony Two ↔ stream ↔ Tropical Fruit Forest
	EnvKit.path_segment(paths, GameData.region_world_pos("colony_two"), Vector3(-2.6, 0, BRIDGE_Z), 2.6)
	EnvKit.path_segment(paths, Vector3(2.6, 0, BRIDGE_Z), GameData.region_world_pos("tropical_forest"), 2.6)
	# Boundary walls (visual barrier is the forest band; invisible walls are a safety net)
	var w := BOUNDS_MAX.x - BOUNDS_MIN.x
	var h := BOUNDS_MAX.y - BOUNDS_MIN.y
	EnvKit.invisible_wall(self, Vector3(w + 4, 8, 2), Vector3(center.x, 4, BOUNDS_MIN.y - 1))
	EnvKit.invisible_wall(self, Vector3(w + 4, 8, 2), Vector3(center.x, 4, BOUNDS_MAX.y + 1))
	EnvKit.invisible_wall(self, Vector3(2, 8, h + 4), Vector3(BOUNDS_MIN.x - 1, 4, center.y))
	EnvKit.invisible_wall(self, Vector3(2, 8, h + 4), Vector3(BOUNDS_MAX.x + 1, 4, center.y))


func _build_regions() -> void:
	var root := Node3D.new()
	root.name = "RegionModules"
	add_child(root)
	for id in GameData.REGIONS:
		var path := REGION_SCENES % id
		var r: RegionBase
		if ResourceLoader.exists(path):
			r = load(path).instantiate()
		else:
			r = RegionBase.new()
		r.region_id = id
		r.name = String(id).to_pascal_case()
		root.add_child(r)
		r.global_position = GameData.region_world_pos(id)
		r.setup_region(self)
		regions[id] = r


func _build_stream_and_bridge() -> void:
	var s := Node3D.new()
	s.name = "OldStream"
	add_child(s)
	var length := STREAM_Z.y - STREAM_Z.x
	var mid := (STREAM_Z.x + STREAM_Z.y) * 0.5
	var water := CharParts.add(s, CharParts.box_mesh(Vector3(2.6, 0.06, length)), EnvKit.water_material(), Vector3(0, 0.06, mid))
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in range(int(STREAM_Z.x), int(STREAM_Z.y), 3):
		for side in [-1.0, 1.0]:
			var st := CharParts.add(s, CharParts.sphere_mesh(0.3, 8), CharParts.mat(EnvKit.STONE, 0.008), Vector3(1.45 * side, 0.08, float(z) + randf() * 1.5))
			st.scale = Vector3(1.1, 0.5, 1.3)
	# Banks: block the stream except at the bridge
	EnvKit.invisible_wall(s, Vector3(2.6, 3, BRIDGE_Z - 1.6 - STREAM_Z.x), Vector3(0, 1.5, (STREAM_Z.x + BRIDGE_Z - 1.6) * 0.5))
	EnvKit.invisible_wall(s, Vector3(2.6, 3, STREAM_Z.y - BRIDGE_Z - 1.6), Vector3(0, 1.5, (STREAM_Z.y + BRIDGE_Z + 1.6) * 0.5))
	_bridge_block = EnvKit.invisible_wall(s, Vector3(2.6, 3, 3.2), Vector3(0, 1.5, BRIDGE_Z))
	# Broken bridge: posts + two loose planks
	_bridge_broken = Node3D.new()
	s.add_child(_bridge_broken)
	for x in [-1.6, 1.6]:
		for z in [-1.2, 1.2]:
			CharParts.add(_bridge_broken, CharParts.cyl_mesh(0.09, 0.1, 1.0, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 0.4, BRIDGE_Z + z), Vector3(randf_range(-12, 12), 0, randf_range(-12, 12)))
	CharParts.add(_bridge_broken, CharParts.box_mesh(Vector3(1.4, 0.08, 0.5)), CharParts.mat(EnvKit.WOOD, 0.008), Vector3(-1.3, 0.12, BRIDGE_Z - 0.3), Vector3(0, 20, 8))
	CharParts.add(_bridge_broken, CharParts.box_mesh(Vector3(1.2, 0.08, 0.5)), CharParts.mat(EnvKit.WOOD, 0.008), Vector3(1.2, 0.05, BRIDGE_Z + 0.6), Vector3(0, -15, -6))
	# Fixed bridge
	_bridge_fixed = Node3D.new()
	s.add_child(_bridge_fixed)
	for i in 8:
		var x := -2.1 + i * 0.6
		var hgt := 0.35 * (1.0 - pow(x / 2.4, 2.0))
		CharParts.add(_bridge_fixed, CharParts.box_mesh(Vector3(0.56, 0.1, 2.4)), CharParts.mat(EnvKit.WOOD_LIGHT if i % 2 else EnvKit.WOOD, 0.008), Vector3(x, 0.12 + hgt, BRIDGE_Z))
	for z in [-1.25, 1.25]:
		CharParts.add(_bridge_fixed, CharParts.box_mesh(Vector3(4.6, 0.08, 0.08)), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(0, 1.0, BRIDGE_Z + z))
		for x in [-2.0, 0.0, 2.0]:
			CharParts.add(_bridge_fixed, CharParts.cyl_mesh(0.05, 0.05, 0.8, 6), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(x, 0.6, BRIDGE_Z + z))
	_bridge_body = EnvKit.body(_bridge_fixed)
	var r1 := EnvKit.add_box_shape(_bridge_body, Vector3(2.6, 0.2, 2.4), Vector3(-1.2, 0.2, BRIDGE_Z))
	r1.rotation.z = deg_to_rad(8)
	var r2 := EnvKit.add_box_shape(_bridge_body, Vector3(2.6, 0.2, 2.4), Vector3(1.2, 0.2, BRIDGE_Z))
	r2.rotation.z = deg_to_rad(-8)
	# Bridge site interaction
	var bprompt := func():
		if GameState.quests.has_deliver_for("bridge_site"):
			return "Mend the old bridge (%d/4 planks)" % mini(GameState.inventory.count("item_plank"), 4)
		return "Inspect the broken bridge"
	var baction := func(_a):
		if GameState.quests.has_deliver_for("bridge_site"):
			var res := GameState.quests.try_deliver("bridge_site")
			if not res.ok:
				GameState.notify(String(res.reason), "warn")
				AudioManager.play_sfx("error")
			else:
				AudioManager.play_sfx("upgrade")
				if not (res.lines as Array).is_empty():
					GameState.request_dialogue(res.lines)
		else:
			GameState.request_dialogue(["Swan: The old bridge... it used to join Colony Two and the orchard. Maybe Elder Maple knows how to mend it."])
	var benabled := func(): return not GameState.world.has_flag("bridge_restored")
	var ap := ActionPoint.new().configure("bridge_site", bprompt, baction, benabled, 2.6, 1.4, 2)
	ap.position = Vector3(-2.4, 0, BRIDGE_Z)
	s.add_child(ap)
	EnvKit.sign_post(s, Vector3(-3.6, 0, BRIDGE_Z + 2.2), "Old Stream Bridge", 90)
	_apply_bridge()


func _on_flag(f: String) -> void:
	if f == "bridge_restored":
		_apply_bridge()


func _apply_bridge() -> void:
	var fixed := GameState.world.has_flag("bridge_restored")
	_bridge_broken.visible = not fixed
	_bridge_fixed.visible = fixed
	for c in _bridge_block.get_children():
		(c as CollisionShape3D).disabled = fixed
	for c in _bridge_body.get_children():
		(c as CollisionShape3D).disabled = not fixed


## Border forest + interior scatter + grass, avoiding regions, paths and the stream.
func _build_scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var border: Array = []
	var x := BOUNDS_MIN.x
	while x <= BOUNDS_MAX.x:
		for k in 2:
			border.append(Vector3(x + rng.randf_range(-1, 1), 0, BOUNDS_MIN.y + 1.5 + k * 3.5))
			border.append(Vector3(x + rng.randf_range(-1, 1), 0, BOUNDS_MAX.y - 1.5 - k * 3.5))
		x += 3.6
	var z := BOUNDS_MIN.y
	while z <= BOUNDS_MAX.y:
		for k in 2:
			border.append(Vector3(BOUNDS_MIN.x + 1.5 + k * 3.5, 0, z + rng.randf_range(-1, 1)))
			border.append(Vector3(BOUNDS_MAX.x - 1.5 - k * 3.5, 0, z + rng.randf_range(-1, 1)))
		z += 3.6
	var scatter_root := Node3D.new()
	scatter_root.name = "Scatter"
	add_child(scatter_root)
	var interior: Array = []
	for i in 900:
		var p := Vector3(rng.randf_range(BOUNDS_MIN.x + 8, BOUNDS_MAX.x - 8), 0, rng.randf_range(BOUNDS_MIN.y + 8, BOUNDS_MAX.y - 8))
		if _blocked(p, 3.8):
			continue
		var ok := true
		for q in interior:
			if (q as Vector3).distance_to(p) < 4.5:
				ok = false
				break
		if ok:
			interior.append(p)
	var all := border + interior
	EnvKit.forest_band(scatter_root, all, 77)
	EnvKit.grass_tufts(scatter_root, BOUNDS_MIN, BOUNDS_MAX, 2600, 5, func(p): return _on_path(p, 1.8) or _in_stream(p))
	for i in 60:
		var p := Vector3(rng.randf_range(BOUNDS_MIN.x + 8, BOUNDS_MAX.x - 8), 0, rng.randf_range(BOUNDS_MIN.y + 8, BOUNDS_MAX.y - 8))
		if not _blocked(p, 2.5):
			EnvKit.rock(scatter_root, p, rng.randf_range(0.6, 1.2))
	for i in 40:
		var p := Vector3(rng.randf_range(BOUNDS_MIN.x + 8, BOUNDS_MAX.x - 8), 0, rng.randf_range(BOUNDS_MIN.y + 8, BOUNDS_MAX.y - 8))
		if not _blocked(p, 2.0):
			EnvKit.flowers(scatter_root, p, 14, 1.2, [Color("fbe6ef"), Color("f7d36b"), Color("f2a3c0"), Color.WHITE], i)


func _blocked(p: Vector3, margin: float) -> bool:
	for id in GameData.REGIONS:
		var r: Dictionary = GameData.REGIONS[id]
		var c: Vector2 = r.pos
		var s: Vector2 = r.size
		if absf(p.x - c.x) < s.x * 0.5 + margin and absf(p.z - c.y) < s.y * 0.5 + margin:
			return true
	return _on_path(p, margin) or _in_stream(p)


func _in_stream(p: Vector3) -> bool:
	return absf(p.x) < 3.5 and p.z > STREAM_Z.x - 2.0 and p.z < STREAM_Z.y + 2.0


func _on_path(p: Vector3, margin: float) -> bool:
	var segs: Array = []
	for pair in GameData.PATHS:
		segs.append([GameData.region_world_pos(pair[0]), GameData.region_world_pos(pair[1])])
	segs.append([GameData.region_world_pos("colony_two"), GameData.region_world_pos("tropical_forest")])
	for sg in segs:
		var a: Vector3 = sg[0]
		var b: Vector3 = sg[1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(p) < 1.5 + margin:
			return true
	return false


# --- Characters ----------------------------------------------------------------------------------

func _spawn_characters(loading: bool) -> void:
	player = load(PLAYER_SCENE).instantiate()
	add_child(player)
	swan = load(SWAN_SCENE).instantiate()
	add_child(swan)
	var spawn := GameData.region_world_pos("sunshine_forest") + Vector3(0.5, 0.1, 0.5)
	var yaw := 0.0
	if loading:
		var pp = SaveManager.pending_player_position()
		if pp != null:
			spawn = pp + Vector3(0, 0.3, 0)
			yaw = 0.0
	player.teleport(spawn, yaw)
	swan.global_position = spawn + Vector3(1.6, 0, 1.2)
	if loading and SaveManager.pending_load.get("player", {}).get("character", "mnki") == "swan":
		player.switch_character(true)
		player.teleport(spawn, yaw)
		swan.global_position = spawn + Vector3(1.6, 0, 1.2)
