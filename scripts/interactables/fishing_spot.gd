class_name FishingSpot
extends Interactable
## Calm timing fishing (GDD §9.5): cast → wait → bite cue (bobber dip + splash + sound + HUD)
## → press E within a generous window → catch. A miss only costs seconds. Esc/moving cancels.

@export var table_id: String = "pond"
## Local offset of where the bobber lands (over the water).
@export var water_offset: Vector3 = Vector3(0, 0.1, 3.0)

var state := ""            # "", casting, waiting, bite, reeling
var _actor: Node = null
var _timer := 0.0
var _bobber: Node3D
var _line: MeshInstance3D
var _imesh: ImmediateMesh
var _rng := RandomNumberGenerator.new()
var _splash: CPUParticles3D


func setup(id: String, table: String, offset: Vector3) -> FishingSpot:
	object_id = id
	table_id = table
	water_offset = offset
	return self


func _ready() -> void:
	marker_height = 1.0
	interaction_range = 2.2
	priority = 1
	super._ready()
	_rng.randomize()
	# Little wooden fishing mat so the bank position is readable
	CharParts.add(self, CharParts.box_mesh(Vector3(1.4, 0.06, 1.0)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.008), Vector3(0, 0.03, 0))
	CharParts.add(self, CharParts.cyl_mesh(0.05, 0.05, 0.5, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(0.6, 0.25, -0.4))
	_bobber = Node3D.new()
	_bobber.top_level = true
	_bobber.visible = false
	add_child(_bobber)
	CharParts.sphere(_bobber, 0.08, Color("e0473a"), Vector3(0, 0.05, 0), Vector3.ONE, 0.006)
	CharParts.sphere(_bobber, 0.06, Color.WHITE, Vector3(0, 0.12, 0), Vector3.ONE, 0.006)
	_imesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _imesh
	_line.top_level = true
	_line.material_override = CharParts.unshaded(Color(0.95, 0.95, 0.9, 0.9))
	add_child(_line)
	_splash = CPUParticles3D.new()
	_splash.top_level = true
	_splash.emitting = false
	_splash.one_shot = true
	_splash.amount = 18
	_splash.lifetime = 0.6
	_splash.explosiveness = 1.0
	_splash.direction = Vector3.UP
	_splash.spread = 50
	_splash.initial_velocity_min = 1.5
	_splash.initial_velocity_max = 3.0
	_splash.scale_amount_min = 0.04
	_splash.scale_amount_max = 0.08
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0
	_splash.mesh = sm
	_splash.material_override = CharParts.unshaded(Color("d9f3f6"))
	add_child(_splash)


func get_interaction_prompt(_actor: Node) -> String:
	return "Fish here"


func can_interact(_actor: Node) -> bool:
	return state == ""


func is_active() -> bool:
	return state != ""


func interact(actor: Node) -> void:
	if state != "":
		return
	_actor = actor
	state = "casting"
	_timer = 0.7
	if actor.has_method("begin_fishing"):
		actor.begin_fishing(self)
	GameState.companion("player_fishing", {"pos": global_position})
	GameState.notify("Casting... wait for the bobber to dip.", "info")


func water_point() -> Vector3:
	return to_global(water_offset)


## Player pressed interact while fishing.
func press() -> void:
	match state:
		"bite":
			_catch()
		"waiting":
			GameState.notify("Not yet — wait for the splash.", "info")


func cancel() -> void:
	if state == "":
		return
	_end()
	GameState.notify("Reeled in.", "info")


func _process(delta: float) -> void:
	super._process(delta)
	if state == "" or GameState.is_ui_blocking():
		return
	_timer -= delta
	var wp := water_point()
	match state:
		"casting":
			if _timer <= 0.0:
				state = "waiting"
				_bobber.visible = true
				_bobber.global_position = wp
				var first := int(GameState.stats.fish_caught) == 0
				_timer = _rng.randf_range(1.5, 3.0) if first else _rng.randf_range(2.5, 6.0)
				AudioManager.play_sfx("splash", 1.3)
				GameState.emit_signal("fishing_state_changed", "waiting")
		"waiting":
			_bobber.global_position = wp + Vector3(0, sin(Time.get_ticks_msec() * 0.004) * 0.03, 0)
			if _timer <= 0.0:
				state = "bite"
				_timer = 3.0 if Settings.get_value("fishing_easy") else 1.7
				AudioManager.play_sfx("bite")
				_splash.global_position = wp
				_splash.restart()
				_splash.emitting = true
				GameState.emit_signal("fishing_state_changed", "bite")
		"bite":
			_bobber.global_position = wp + Vector3(0, -0.12 + sin(Time.get_ticks_msec() * 0.03) * 0.05, 0)
			if _timer <= 0.0:
				AudioManager.play_sfx("miss")
				GameState.notify("It slipped away — no harm done. Press E to cast again.", "info")
				_end()
		"reeling":
			_bobber.global_position = _bobber.global_position.lerp(global_position + Vector3(0, 1.0, 0), 0.15)
			if _timer <= 0.0:
				_end()
	_draw_line()


func _catch() -> void:
	var fish := GameData.roll_fish(table_id, _rng)
	if int(GameState.stats.fish_caught) == 0 and fish == "fish_koi":
		fish = "fish_carp"  # first catch is always an ordinary fish
	if not GameState.inventory.can_add(fish, 1):
		GameState.notify("Your bag is full — the fish swims free.", "warn")
		_end()
		return
	state = "reeling"
	_timer = 0.6
	GameState.inventory.add(fish, 1)
	GameState.stats.fish_caught = int(GameState.stats.fish_caught) + 1
	AudioManager.play_sfx("catch")
	GameState.notify("Caught a %s!" % ItemDB.display_name(fish), "item")
	GameState.quests.on_event("catch", {"fish": fish})
	GameState.emit_signal("fishing_state_changed", "caught")
	if _actor and _actor.has_method("play_action"):
		_actor.play_action("celebrate", 1.0)
	if int(GameState.stats.fish_caught) == 1:
		GameState.companion("first_fish", {"fish": fish})
	elif fish == "fish_koi":
		GameState.companion("rare_find", {"item": fish})


func _end() -> void:
	state = ""
	_bobber.visible = false
	_imesh.clear_surfaces()
	if _actor and _actor.has_method("end_fishing"):
		_actor.end_fishing()
	_actor = null
	GameState.emit_signal("fishing_state_changed", "")


func _draw_line() -> void:
	_imesh.clear_surfaces()
	if not _bobber.visible or _actor == null or not _actor.has_method("rod_tip"):
		return
	var a: Vector3 = _actor.rod_tip()
	var b := _bobber.global_position + Vector3(0, 0.1, 0)
	_imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 9:
		var t := float(i) / 8.0
		var p := a.lerp(b, t)
		p.y -= sin(t * PI) * 0.35
		_imesh.surface_add_vertex(p)
	_imesh.surface_end()
