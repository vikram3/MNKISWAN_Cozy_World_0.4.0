class_name FarmAnimal
extends Interactable
## Friendly farm animal (GDD §9.6): pet, feed and brush once per day; capped affection;
## chickens that were fed lay an egg in the nest next morning. No death, no penalties.

@export var species: String = "chicken"
var pen_center := Vector3.ZERO
var pen_size := Vector2(8, 6)
var model: AnimalModel
var _body: AnimatableBody3D
var _target := Vector3.ZERO
var _wait := 0.0
var _speed := 0.8
var _hold := 0.0
var _rng := RandomNumberGenerator.new()
var nest_id := "nest_farm"


func setup(id: String, sp: String, center: Vector3, size: Vector2) -> FarmAnimal:
	object_id = id
	species = sp
	pen_center = center
	pen_size = size
	return self


func _ready() -> void:
	marker_height = 1.7 if species == "cow" else (1.2 if species == "sheep" else 0.8)
	interaction_range = 2.4 if species == "cow" else 2.0
	priority = 2
	super._ready()
	_rng.seed = hash(object_id)
	model = AnimalModel.new().setup(species)
	add_child(model)
	_body = AnimatableBody3D.new()
	_body.collision_layer = 8
	_body.collision_mask = 0
	_body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.7 if species == "cow" else (0.45 if species == "sheep" else 0.25)
	sh.height = 1.2
	cs.shape = sh
	cs.position.y = 0.6
	_body.add_child(cs)
	add_child(_body)
	_speed = 0.9 if species == "chicken" else 0.6
	_pick_target()
	TimeManager.day_started.connect(_on_day)


func _state() -> Dictionary:
	return GameState.world.get_state(object_id, {"pet_day": -1, "fed_day": -1, "brush_day": -1, "affection": 0})


func _next_action() -> String:
	var st := _state()
	var d := TimeManager.day
	if int(st.pet_day) != d:
		return "pet"
	if int(st.fed_day) != d:
		return "feed"
	if species != "chicken" and int(st.brush_day) != d:
		return "brush"
	return "hello"


func get_interaction_prompt(_actor: Node) -> String:
	var nm := species
	match _next_action():
		"pet": return "Gently pet the %s" % nm
		"feed":
			if GameState.inventory.count("item_feed") > 0:
				return "Feed the %s (Hay & Grain)" % nm
			return "Feed the %s — take Hay & Grain from the feed bin first" % nm
		"brush": return "Brush the %s" % nm
	return "Say hello to the %s (all cared for today)" % nm


func interact(actor: Node) -> void:
	var st := _state()
	var d := TimeManager.day
	var act := _next_action()
	_hold = 2.0
	_face(actor)
	match act:
		"pet":
			st.pet_day = d
			st.affection = mini(int(st.affection) + 1, 10)
			model.react("happy", 1.4)
			if actor.has_method("play_action"):
				actor.play_action("pet", 1.0)
			_sound()
			GameState.notify("The %s %s." % [species, "bobs its head happily" if species == "chicken" else "leans into your hand"], "info")
		"feed":
			if not GameState.inventory.remove("item_feed", 1):
				GameState.notify("%s eat Hay & Grain — grab some from the feed bin by the barn." % species.capitalize(), "warn")
				AudioManager.play_sfx("error")
				return
			st.fed_day = d
			st.affection = mini(int(st.affection) + 1, 10)
			model.react("eat", 1.6)
			if actor.has_method("play_action"):
				actor.play_action("feed", 1.0)
			AudioManager.play_sfx("pet")
			GameState.notify("The %s munches happily.%s" % [species, " An egg may appear in the nest tomorrow." if species == "chicken" else ""], "info")
		"brush":
			st.brush_day = d
			st.affection = mini(int(st.affection) + 1, 10)
			model.react("groom", 1.6)
			if actor.has_method("play_action"):
				actor.play_action("brush", 1.2)
			_sound()
			GameState.notify("Soft and fluffy. The %s looks content." % species, "info")
		_:
			model.react("happy", 0.8)
			_sound()
			return
	GameState.world.set_state(object_id, st)
	GameState.stats.care_actions = int(GameState.stats.care_actions) + 1
	GameState.record_animal(species)
	GameState.quests.on_event("care", {"action": act, "species": species})
	if int(GameState.stats.care_actions) == 1:
		GameState.companion("first_care", {"species": species})


func _sound() -> void:
	match species:
		"cow": AudioManager.play_sfx("moo")
		"sheep": AudioManager.play_sfx("baa")
		_: AudioManager.play_sfx("cluck")


func _on_day(day: int) -> void:
	if species != "chicken":
		return
	var st := _state()
	if int(st.fed_day) == day - 1:
		var nest := GameState.world.get_state(nest_id, {"eggs": 0})
		nest.eggs = mini(int(nest.eggs) + 1, 6)
		GameState.world.set_state(nest_id, nest)


func _face(actor: Node) -> void:
	if actor is Node3D:
		var d: Vector3 = (actor as Node3D).global_position - global_position
		if d.length() > 0.1:
			model.rotation.y = atan2(d.x, d.z)


func _pick_target() -> void:
	_target = pen_center + Vector3(_rng.randf_range(-pen_size.x, pen_size.x) * 0.45, 0, _rng.randf_range(-pen_size.y, pen_size.y) * 0.45)
	_wait = _rng.randf_range(1.5, 5.0)


func _physics_process(delta: float) -> void:
	if _hold > 0.0:
		_hold -= delta
		model.moving = 0.0
		return
	if GameState.is_ui_blocking():
		model.moving = 0.0
		return
	var to := _target - global_position
	to.y = 0
	if to.length() < 0.2:
		model.moving = 0.0
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
		return
	var step := to.normalized() * _speed * delta
	global_position += step
	model.moving = 1.0
	model.rotation.y = lerp_angle(model.rotation.y, atan2(to.x, to.z), 0.1)
