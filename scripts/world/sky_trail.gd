class_name SkyTrail
extends Node3D
## A quiet flight route: six persistent feather charms, no timer or failure state.
const STOPS := [Vector3(-34, 6, -81), Vector3(-25, 9, -54), Vector3(-27, 12, -24), Vector3(-24, 10, 0), Vector3(8, 15, -22), Vector3(32, 11, -80)]
var charms: Array[Node3D] = []
var _time := 0.0

func _ready() -> void:
	name = "SkyTrail"
	for i in STOPS.size():
		var root := Node3D.new()
		root.position = STOPS[i]
		add_child(root)
		charms.append(root)
		root.visible = not GameState.world.has_flag("sky_feather_%d" % i)
		CharParts.add(root, CharParts.torus_mesh(0.95, 1.0, 10, 48), CharParts.mat(Color("f0c368"), 0, 0.35), Vector3.ZERO, Vector3(90, 0, 0))
		var feather := CharacterSculpt.lock_mesh([Vector3(-0.2, -0.4, 0), Vector3(0.1, 0, 0.03), Vector3(0.25, 0.45, 0)], 0.18, 0.035, true)
		CharParts.add(root, feather, CharParts.mat(Color("fff4d8"), 0, 0.25))
		var label := EnvKit.label3d(root, "SKY FEATHER  %d / 6" % (i + 1), Vector3(0, 1.35, 0), 25, Color("fff1c3"), true)
		label.visibility_range_end = 45.0
		label.no_depth_test = false
		label.outline_size = 5

func _process(delta: float) -> void:
	if GameState.is_ui_blocking():
		return
	_time += delta
	var player := GameState.player as MnkiController
	for i in charms.size():
		var charm := charms[i]
		if not charm.visible:
			continue
		charm.position.y = STOPS[i].y + sin(_time * 1.2 + i) * 0.15
		charm.rotation.y += delta * 0.3
		if player and player.character_id == "swan" and player.flight_mode != "grounded" and player.global_position.distance_to(charm.global_position - Vector3.UP * 0.7) < 1.55:
			collect(i)

func collect(index: int) -> bool:
	if index < 0 or index >= charms.size():
		return false
	var flag := "sky_feather_%d" % index
	if GameState.world.has_flag(flag):
		return false
	GameState.world.set_flag(flag)
	charms[index].visible = false
	GameState.economy.add(5, flag)
	AudioManager.play_sfx("chime")
	var count := collected_count()
	GameState.notify("Sky feather %d / 6 · +5 coins" % count, "discovery")
	if count == 6:
		GameState.economy.add(20, "sky_trail_complete")
		GameState.record_note("sky_trail", "A village from above", "Swan followed all six feathers over the village. A sky full of little adventures, and a friend waiting below.")
		GameState.notify("The sky trail is complete! +20 coins", "quest")
	SaveManager.autosave("sky_feather")
	return true

static func collected_count() -> int:
	var count := 0
	for i in STOPS.size():
		if GameState.world.has_flag("sky_feather_%d" % i):
			count += 1
	return count
