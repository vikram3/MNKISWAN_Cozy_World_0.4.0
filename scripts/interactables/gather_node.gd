class_name GatherNode
extends Interactable
## Forage source with a stable ID, predictable yield and visible ready/picked states that
## regrow after in-game hours or the next morning (GDD §9.3). Full bag leaves the source intact.

## kind: berry_bush, starberry_bush, mango_tree, banana_plant, coconut_palm, flower_patch, moonbell, keepsake
@export var kind: String = "berry_bush"
@export var item_id: String = "item_berry"
@export var yield_qty: int = 2
@export var regrow_hours: float = 8.0

var _ready_visuals: Array = []
var _picked_visuals: Array = []


func setup(id: String, k: String) -> GatherNode:
	object_id = id
	kind = k
	match k:
		"berry_bush": item_id = "item_berry"; yield_qty = 2; regrow_hours = 8.0
		"starberry_bush": item_id = "item_starberry"; yield_qty = 1; regrow_hours = 24.0
		"mango_tree": item_id = "item_mango"; yield_qty = 1; regrow_hours = 10.0
		"banana_plant": item_id = "item_banana"; yield_qty = 2; regrow_hours = 12.0
		"coconut_palm": item_id = "item_coconut"; yield_qty = 1; regrow_hours = 14.0
		"flower_patch": item_id = "item_flower"; yield_qty = 1; regrow_hours = 6.0
		"moonbell": item_id = "item_moonbell"; yield_qty = 1; regrow_hours = 24.0
		"keepsake": item_id = "key_windchime"; yield_qty = 1; regrow_hours = -1.0
	return self


func _ready() -> void:
	marker_height = 1.5
	match kind:
		"mango_tree", "coconut_palm":
			marker_height = 2.2
			interaction_range = 2.8
		"banana_plant":
			marker_height = 2.0
			interaction_range = 2.6
		"flower_patch", "moonbell", "keepsake":
			marker_height = 0.9
	super._ready()
	_build()
	GameState.world.object_state_changed.connect(_on_state_changed)
	TimeManager.day_started.connect(func(_d): _refresh())
	TimeManager.hour_changed.connect(func(_h): _refresh())
	_refresh()


func _state() -> Dictionary:
	return GameState.world.get_state(object_id, {"ready_at": 0.0})


func is_ready_to_pick() -> bool:
	if kind == "keepsake":
		return not GameState.world.has_flag("found_" + object_id) and GameState.quests.is_active("q_lost_chime")
	return TimeManager.total_minutes() >= float(_state().get("ready_at", 0.0))


func can_interact(_actor: Node) -> bool:
	return is_ready_to_pick()


func get_interaction_prompt(_actor: Node) -> String:
	var verb := "Gather"
	match kind:
		"mango_tree", "coconut_palm", "banana_plant": verb = "Pick"
		"flower_patch", "moonbell": verb = "Pick"
		"keepsake": return "Pick up the little shell wind chime"
	return "%s %s" % [verb, ItemDB.display_name(item_id) + ("s" if yield_qty > 1 else "")]


func interact(actor: Node) -> void:
	if not is_ready_to_pick():
		return
	if not GameState.inventory.can_add(item_id, yield_qty):
		GameState.notify("Your bag is full — the %s stays here for later." % ItemDB.display_name(item_id), "warn")
		AudioManager.play_sfx("error")
		return
	if actor.has_method("play_action"):
		actor.play_action("gather", 0.55)
	GameState.inventory.add(item_id, yield_qty)
	if kind == "keepsake":
		GameState.world.set_flag("found_" + object_id)
		AudioManager.play_sfx("chime")
	else:
		var st := _state()
		st["ready_at"] = TimeManager.total_minutes() + regrow_hours * 60.0
		st["day_picked"] = TimeManager.day
		GameState.world.set_state(object_id, st)
		AudioManager.play_sfx("gather", randf_range(0.95, 1.08))
	GameState.notify("+%d %s" % [yield_qty, ItemDB.display_name(item_id)], "item")
	if kind in ["starberry_bush", "moonbell"]:
		GameState.companion("rare_find", {"item": item_id})
	_refresh()
	_burst()


func _on_state_changed(id: String) -> void:
	if id == object_id:
		_refresh()


## Sources also regrow overnight: a new day resets anything picked on an earlier day.
func _refresh() -> void:
	if kind != "keepsake":
		var st := _state()
		if int(st.get("day_picked", -1)) >= 0 and int(st.get("day_picked", -1)) < TimeManager.day and float(st.get("ready_at", 0.0)) > TimeManager.total_minutes():
			st["ready_at"] = 0.0
	var r := is_ready_to_pick()
	for n in _ready_visuals:
		var a: Node3D = n
		a.visible = r
	for n in _picked_visuals:
		var b: Node3D = n
		b.visible = not r
	if kind == "keepsake":
		visible = r


func _burst() -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.7
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 2.8
	p.gravity = Vector3(0, -4, 0)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.1
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	p.mesh = sm
	p.material_override = CharParts.mat(ItemDB.color_of(item_id).lightened(0.3), 0.0, 0.8)
	p.position = Vector3(0, marker_height * 0.6, 0)
	add_child(p)
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


func _build() -> void:
	var c := ItemDB.color_of(item_id)
	match kind:
		"berry_bush", "starberry_bush":
			EnvKit.bush(self, Vector3.ZERO, 1.0, Color("4f9a50") if kind == "berry_bush" else Color("5c8f3f"))
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(object_id)
			var fruit := Node3D.new()
			add_child(fruit)
			for i in 9:
				var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 1), rng.randf_range(-1, 1)).normalized()
				CharParts.sphere(fruit, 0.075, c, Vector3(0, 0.45, 0) + d * Vector3(0.55, 0.4, 0.55), Vector3.ONE, 0.006)
			if kind == "starberry_bush":
				var l := OmniLight3D.new()
				l.light_color = Color("ffe08a"); l.omni_range = 2.5; l.light_energy = 0.6; l.position = Vector3(0, 0.8, 0)
				fruit.add_child(l)
			_ready_visuals.append(fruit)
			var sb := EnvKit.body(self)
			EnvKit.add_cyl_shape(sb, 0.5, 1.0, Vector3(0, 0.5, 0))
		"mango_tree":
			EnvKit.tree(self, Vector3.ZERO, 1.0, Color("4d9446"))
			var fruit := Node3D.new()
			add_child(fruit)
			for p in [Vector3(0.9, 2.0, 0.6), Vector3(-0.7, 2.1, 0.8), Vector3(0.2, 1.9, 1.0)]:
				CharParts.add(fruit, CharParts.sphere_mesh(0.14, 12), CharParts.mat(c, 0.008), p, Vector3(0, 0, 20), Vector3(0.85, 1.15, 0.85))
			_ready_visuals.append(fruit)
		"banana_plant":
			EnvKit.tree(self, Vector3.ZERO, 1.1, Color("6dbb4f"), "banana")
			var fruit := Node3D.new()
			add_child(fruit)
			for i in 5:
				var bm := CharParts.add(fruit, CharParts.capsule_mesh(0.05, 0.3), CharParts.mat(c, 0.006), Vector3(0.3 + i * 0.04, 1.45 - i * 0.05, 0.25), Vector3(0, 0, 30 + i * 8))
				bm.name = "Banana%d" % i
			_ready_visuals.append(fruit)
		"coconut_palm":
			EnvKit.tree(self, Vector3.ZERO, 1.0, Color("4f9e45"), "palm")
			var fruit := Node3D.new()
			add_child(fruit)
			for p in [Vector3(0.75, 3.75, 0.15), Vector3(0.55, 3.7, -0.15), Vector3(0.95, 3.7, -0.05)]:
				CharParts.sphere(fruit, 0.14, c, p, Vector3.ONE, 0.008)
			_ready_visuals.append(fruit)
			# fallen coconut at ground level so the interaction stays at reach (no climbing)
			var fallen := Node3D.new()
			add_child(fallen)
			CharParts.sphere(fallen, 0.15, c, Vector3(0.6, 0.15, 0.6), Vector3.ONE, 0.008)
			_ready_visuals.append(fallen)
		"flower_patch", "moonbell":
			var fl := Node3D.new()
			add_child(fl)
			var col := Color("fbf3f6") if kind == "flower_patch" else c
			for i in 5:
				var a := TAU * float(i) / 5.0
				var p := Vector3(cos(a), 0, sin(a)) * 0.28
				CharParts.add(fl, CharParts.cyl_mesh(0.012, 0.012, 0.35, 5), CharParts.mat(Color("5fa35a")), p + Vector3(0, 0.17, 0))
				for k in 5:
					var pa := TAU * float(k) / 5.0
					CharParts.sphere(fl, 0.045, col, p + Vector3(cos(pa) * 0.06, 0.36, sin(pa) * 0.06), Vector3(1, 0.5, 1), 0.004)
				CharParts.sphere(fl, 0.035, Color("f2c230"), p + Vector3(0, 0.38, 0), Vector3.ONE, 0.0)
			if kind == "moonbell":
				var l := OmniLight3D.new()
				l.light_color = Color("8fb0ff"); l.omni_range = 2.5; l.light_energy = 0.8; l.position = Vector3(0, 0.6, 0)
				fl.add_child(l)
			_ready_visuals.append(fl)
			var stem := Node3D.new()
			add_child(stem)
			for i in 5:
				var a := TAU * float(i) / 5.0
				CharParts.add(stem, CharParts.cyl_mesh(0.012, 0.012, 0.15, 5), CharParts.mat(Color("5fa35a")), Vector3(cos(a), 0, sin(a)) * 0.28 + Vector3(0, 0.07, 0))
			_picked_visuals.append(stem)
		"keepsake":
			CharParts.add(self, CharParts.cyl_mesh(0.02, 0.02, 0.3, 6), CharParts.mat(Color("d8c7a0")), Vector3(0, 0.15, 0))
			for i in 4:
				CharParts.sphere(self, 0.05, Color("a7d7e0"), Vector3(cos(i * 1.6) * 0.1, 0.06 + i * 0.03, sin(i * 1.6) * 0.1), Vector3(1, 0.6, 1.2), 0.006)
