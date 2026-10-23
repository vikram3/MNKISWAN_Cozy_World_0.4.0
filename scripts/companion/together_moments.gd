class_name TogetherMoments
extends Node3D
## Short, optional shared rituals. Both actors retain their places; no teleport or currency gate.
const MOMENTS := {
	"play": ["Play catch with the children", "play_ball", "The only rule is that everyone gets a turn.", "And cheering counts as playing too!"],
	"appreciate": ["A little appreciation", "affection", "I love the ordinary days with you.", "You don't need to earn my care. You already have it."],
	"breathe": ["Breathe together", "breathe", "We can let the world wait for a moment.", "One breath, then another. I'm right here."],
	"dance": ["A small dance", "dance", "May I have this very unimportant dance?", "Every silly little dance with you matters to me."],
	"tea": ["Share a cup of tea", "eat", "Tell me one little thing you loved today.", "This. A warm cup, and enough time to hear you."],
	"garden": ["A date among the flowers", "affection", "Nothing needs fixing in this moment.", "Then let's just be here, exactly as we are."],
	"stars": ["Watch the sky together", "breathe", "The sky has room for every kind of weather.", "So do we. You can bring your whole day to me."],
	"picnic": ["Share a quiet picnic", "eat", "I saved the sweetest piece for you.", "Let's share it. That's my favourite way."],
	"help": ["Tend the village together", "farm", "Small things grow when we give them time.", "Like gardens. Like trust. Like us."],
	"market": ["Supper at the lantern market", "eat", "Warm food, lanterns, and your company.", "Let's take the long way home together."]
}
var active := false
var moment := ""
var elapsed := 0.0
var duration := 12.0
var player: MnkiController
var partner: SwanCompanion
var _banner: PanelContainer
var _line: Label
var _props: Array[Node3D] = []

func _ready() -> void:
	name = "TogetherMoments"
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	_banner = PanelContainer.new()
	_banner.theme = UITheme.get_theme()
	_banner.position = Vector2(500, 705)
	_banner.custom_minimum_size = Vector2(920, 0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_banner)
	_line = UITheme.label("", 25, UITheme.FOREST)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_line)
	_banner.hide()
	for spec in [["tea", "treehouse", Vector3(7, 0, 8)], ["garden", "flower_garden", Vector3(0, 0, 11.5)], ["stars", "waterfall_ponds", Vector3(-11, 0, 10.5)], ["picnic", "village_park", Vector3(-7, 0, 3)], ["help", "paddy_field", Vector3(-5, 0, -6)], ["market", "market_square", Vector3(1, 0, 3)]]:
		var id: String = spec[0]
		var point := ActionPoint.new().configure("together_" + id, func(): return String(MOMENTS[id][0]) + " · together", func(_actor): begin(id), Callable(), 2.2, 1.1, 1)
		point.position = GameData.region_world_pos(spec[1]) + spec[2]
		add_child(point)
		point.add_to_group("together_place")
		point.set_meta("region", spec[1])
		if id in ["tea", "picnic", "market"]:
			CharParts.add(point, CharParts.box_mesh(Vector3(1.8, 0.025, 1.5)), CharParts.mat(Color("d59e9c")), Vector3(0, 0.04, 0))
			CharParts.add(point, CharParts.cyl_mesh(0.18, 0.14, 0.18, 12), CharParts.mat(Color("b99160")), Vector3(0, 0.14, -0.6))
		EnvKit.flowers(point, Vector3.ZERO, 8, 0.45, [Color("f2a3c0"), Color("fff1cc")], id.hash())

func unavailable_reason(id: String) -> String:
	var p := GameState.player as MnkiController
	var f := GameState.swan as SwanCompanion
	if active: return "Enjoy this moment first, or move to finish it."
	if not p or not f: return "Your partner is on the way."
	if not MOMENTS.has(id): return "Choose a moment together."
	if p.flight_mode != "grounded" or not p.is_on_floor() or not f.is_on_floor(): return "Find a comfortable place on the ground first."
	if p.state != "free" or p.model.is_busy(): return "Finish what you're doing first."
	if p.global_position.distance_to(f.global_position) > 3.2: return "Let your partner catch up, then try again."
	var query := PhysicsRayQueryParameters3D.create(p.global_position + Vector3(0, 0.9, 0), f.global_position + Vector3(0, 0.9, 0), 1 | 16)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return "Find an open spot where you can see each other."
	if id == "market" and not DailyLifeData.market_open(TimeManager.hour()): return "The lantern market opens at 6 PM and closes at midnight."
	return ""

func begin(id: String) -> bool:
	var reason := unavailable_reason(id)
	if not reason.is_empty():
		GameState.notify(reason, "info")
		return false
	if GameState.is_ui_blocking(): return false
	player = GameState.player
	partner = GameState.swan
	active = true
	moment = id
	elapsed = 0
	player.state = "locked"
	partner.state = "together"
	player.velocity = Vector3.ZERO
	partner.velocity = Vector3.ZERO
	player.face_towards(partner.global_position)
	var to := player.global_position - partner.global_position
	partner.model.rotation.y = atan2(to.x, to.z)
	for model: CharModel in [player.model, partner.model]:
		model.play_action(MOMENTS[id][1], -1)
		model.set_expression("happy", duration)
		if id in ["tea", "picnic", "market"]:
			var cup := Node3D.new()
			model.arm_r.add_child(cup)
			cup.position = Vector3(0, -0.3, 0.05)
			CharParts.add(cup, CharParts.cyl_mesh(0.065, 0.05, 0.11, 12), CharParts.mat(Color("f7e4c6")), Vector3.ZERO)
			_props.append(cup)
	_banner.show()
	_update_line()
	return true

func _update_line() -> void:
	var first := elapsed < duration * 0.5
	var who := player.character_id if first else ("swan" if player.character_id == "mnki" else "mnki")
	_line.text = "%s · %s\n%s: %s\nMove or Esc to finish early" % [MOMENTS[moment][0], "Together", who.capitalize(), MOMENTS[moment][2 if first else 3]]

func _process(delta: float) -> void:
	if not active: return
	if GameState.is_ui_blocking():
		finish(false)
		return
	if Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1:
		finish(false)
		return
	elapsed += delta
	_update_line()
	if elapsed >= duration: finish(true)

func _input(event: InputEvent) -> void:
	if active and (event.is_action_pressed("cancel") or event.is_action_pressed("pause")):
		finish(false)
		get_viewport().set_input_as_handled()

func finish(completed: bool) -> void:
	if not active: return
	active = false
	_banner.hide()
	for prop in _props: prop.queue_free()
	_props.clear()
	if is_instance_valid(player):
		player.state = "free"
		player.model.clear_action()
	if is_instance_valid(partner):
		partner.state = "follow"
		partner.model.clear_action()
	if completed:
		var key := "together_" + moment
		var memory := GameState.world.get_state(key, {"days": 0, "last_day": -1})
		if int(memory.get("last_day", -1)) != TimeManager.day:
			memory.days = int(memory.get("days", 0)) + 1
			memory.last_day = TimeManager.day
			GameState.world.set_state(key, memory)
			GameState.record_note(key, String(MOMENTS[moment][0]), "Our little rituals: " + String(MOMENTS[moment][3]))
			SaveManager.autosave("together")
		GameState.notify("A little moment to keep. Nothing to earn; just time together.", "info")
