extends RegionBase
## 08 Entrance & the Three Guardian Statues — Land, Water, Forest. The ceremonial gate opens the
## main village route; plaques feed the journal and the guardian quest.

const PLAQUES := {
	"statue_land": ["Guardian of Land", "LAND - Tend the ground that feeds you, and it will remember your hands."],
	"statue_water": ["Guardian of Water", "WATER - Keep the water clear, and every reflection will be kind."],
	"statue_forest": ["Guardian of Forest", "FOREST - Share the shade. Every living thing is a neighbour."],
}

var _door_l: Node3D
var _door_r: Node3D
var _gate_block: StaticBody3D
var _glows: Array = []


func build() -> void:
	# Ceremonial stone path
	for i in 7:
		EnvKit.disc(self, Vector3(0, 0.04, -7.5 + i * 2.5), 0.9, Color("cfc6b4"), 0.05)
	# Gate wall: hedges + stones across the region, gap at the path
	for x in [-11.0, -7.0, 7.0, 11.0]:
		EnvKit.bush(self, Vector3(x, 0, 2.5), 1.4, Color("4f8f45"), true)
	EnvKit.invisible_wall(self, Vector3(10, 3, 1.2), Vector3(-7.4, 1.5, 2.5))
	EnvKit.invisible_wall(self, Vector3(10, 3, 1.2), Vector3(7.4, 1.5, 2.5))
	for x in [-2.6, 2.6]:
		var pillar := EnvKit.solid_box(self, Vector3(0.9, 3.6, 0.9), Vector3(x, 1.8, 2.5), Color("b9c4cf"), 0, 0.012)
		CharParts.sphere(pillar, 0.45, Color("cdd5dc"), Vector3(0, 2.0, 0), Vector3.ONE, 0.01)
	var arch := CharParts.add(self, CharParts.box_mesh(Vector3(6.2, 0.6, 1.0)), CharParts.mat(Color("b9c4cf"), 0.012), Vector3(0, 3.9, 2.5))
	arch.name = "GateArch"
	var sign := EnvKit.label3d(self, "TREE VILLAGE", Vector3(0, 3.9, 3.02), 70, Color("173b31"))
	sign.outline_size = 0
	# Doors (hinged at pillars)
	_door_l = CharParts.pivot(self, Vector3(-2.15, 0, 2.5))
	CharParts.add(_door_l, CharParts.box_mesh(Vector3(2.1, 2.6, 0.15)), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(1.05, 1.3, 0))
	_door_r = CharParts.pivot(self, Vector3(2.15, 0, 2.5))
	CharParts.add(_door_r, CharParts.box_mesh(Vector3(2.1, 2.6, 0.15)), CharParts.mat(EnvKit.WOOD, 0.01), Vector3(-1.05, 1.3, 0))
	for d in [_door_l, _door_r]:
		var dn: Node3D = d
		var sx := 1.0 if dn == _door_l else -1.0
		for y in [0.6, 2.0]:
			CharParts.add(dn, CharParts.box_mesh(Vector3(2.0, 0.12, 0.05)), CharParts.mat(EnvKit.WOOD_DARK), Vector3(1.05 * sx, y, 0.1))
	_gate_block = EnvKit.invisible_wall(self, Vector3(4.4, 3, 0.6), Vector3(0, 1.5, 2.5))
	var gate_prompt := func(): return "Open the Guardian Gate"
	var gate_enabled := func(): return not GameState.world.has_flag("gate_open")
	add_point("gate_main", Vector3(0, 0, 1.2), gate_prompt, _open_gate, gate_enabled, 2.6, 2.8, 2)
	# Statues
	_statue("statue_land", Vector3(-5.5, 0, -2.5), 120)
	_statue("statue_water", Vector3(5.5, 0, -2.5), -120)
	_statue("statue_forest", Vector3(6, 0, -8.5), -100)
	GameState.world.flag_set.connect(_on_flag)
	_apply_state(false)


func _statue(id: String, p: Vector3, rot: float) -> void:
	var root := Node3D.new()
	root.position = p
	root.rotation_degrees.y = rot
	add_child(root)
	EnvKit.solid_box(root, Vector3(1.6, 0.6, 1.6), Vector3(0, 0.3, 0), Color("a7adb0"), 0, 0.01)
	var stone := Color("c9cfd4")
	match id:
		"statue_land":
			CharParts.sphere(root, 0.7, stone, Vector3(0, 1.3, 0), Vector3(1, 1.2, 0.9), 0.014)
			CharParts.add(root, CharParts.cyl_mesh(0.0, 0.5, 0.8, 3), CharParts.mat(Color("b5a07a"), 0.01), Vector3(0, 2.4, 0))
		"statue_water":
			CharParts.sphere(root, 0.7, stone, Vector3(0, 1.3, 0), Vector3(1, 1.2, 0.9), 0.014)
			CharParts.add(root, CharParts.torus_mesh(0.25, 0.45, 8, 20), CharParts.mat(Color("78c9d4"), 0.01), Vector3(0, 2.25, 0), Vector3(90, 0, 0))
			CharParts.add(root, CharParts.cyl_mesh(0.45, 0.3, 0.25, 14), CharParts.mat(Color("a7adb0"), 0.01), Vector3(0.0, 0.75, 0.9))
			CharParts.add(root, CharParts.cyl_mesh(0.4, 0.4, 0.04, 14), EnvKit.water_material(), Vector3(0.0, 0.86, 0.9))
		"statue_forest":
			CharParts.sphere(root, 0.7, stone, Vector3(0, 1.3, 0), Vector3(1, 1.2, 0.9), 0.014)
			CharParts.sphere(root, 0.5, Color("7fae6a"), Vector3(0, 2.4, 0), Vector3(1, 0.8, 1), 0.012)
	# Simple carved face (eyes + smile) — gentle, never threatening
	for s in [-1.0, 1.0]:
		CharParts.sphere(root, 0.06, Color("6b6f72"), Vector3(0.2 * s, 1.55, 0.6), Vector3(1, 0.5, 0.5), 0.0)
	var smile := PackedVector3Array()
	for i in 7:
		var a := PI + PI * i / 6.0
		smile.append(Vector3(cos(a) * 0.16, 1.3 + sin(a) * 0.06, 0.62))
	CharParts.add(root, CharParts.tube_mesh(smile, 0.018, 0.018, 5), CharParts.mat(Color("6b6f72")))
	# Offering bowl that lights up after the celebration
	var glow := CharParts.sphere(root, 0.18, Color("ffe08a"), Vector3(0.55, 0.75, 0.55), Vector3(1, 0.6, 1), 0.006)
	glow.material_override = CharParts.mat(Color("ffe08a"), 0.006, 2.0)
	glow.visible = false
	_glows.append(glow)
	var sb := EnvKit.body(root)
	EnvKit.add_cyl_shape(sb, 0.75, 3.0, Vector3(0, 1.5, 0))
	var plaque: Array = PLAQUES[id]
	var pprompt := func(): return "Read the plaque: %s" % String(plaque[0])
	var paction := func(actor):
		GameState.request_dialogue(["Plaque: " + String(plaque[1])])
		GameState.record_note(id, String(plaque[0]), String(plaque[1]))
		GameState.quests.on_event("interact", {"target": id})
		AudioManager.play_sfx("chime")
		if actor.has_method("face_towards"):
			actor.face_towards(root.global_position)
	var ap := add_point(id, p + Vector3(sin(deg_to_rad(rot)), 0, cos(deg_to_rad(rot))) * 1.4, pprompt, paction, Callable(), 2.0, 1.6, 1)
	ap.name = "Plaque_" + id


func _open_gate(actor: Node) -> void:
	if GameState.world.has_flag("gate_open"):
		return
	GameState.world.set_flag("gate_open")
	GameState.quests.on_event("interact", {"target": "gate_main"})
	AudioManager.play_sfx("door")
	if actor.has_method("play_action"):
		actor.play_action("shop", 0.6)
	GameState.request_dialogue(["Plaque: Welcome home. Land, Water and Forest keep watch over Tree Village.", "Swan: The treehouse is just past the park. Follow the path south!"])


func _on_flag(f: String) -> void:
	if f in ["gate_open", "festival"]:
		_apply_state(true)


func _apply_state(animate: bool) -> void:
	var open := GameState.world.has_flag("gate_open")
	_gate_block.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
	for c in _gate_block.get_children():
		(c as CollisionShape3D).disabled = open
	var target_l := deg_to_rad(-100.0) if open else 0.0
	var target_r := deg_to_rad(100.0) if open else 0.0
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_door_l, "rotation:y", target_l, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_door_r, "rotation:y", target_r, 1.2).set_trans(Tween.TRANS_SINE)
	else:
		_door_l.rotation.y = target_l
		_door_r.rotation.y = target_r
	for g in _glows:
		var gn: Node3D = g
		gn.visible = GameState.world.has_flag("festival")
