class_name Waypoints
extends Node3D
## Waypoint source of truth shared by the full map, minimap, on-screen markers and the 3D beacon
## beams: the tracked quest's target, plus one player-placed pin (tap the map to drop/clear it).
## Instanced once in the world; the static helpers also work without an instance.

const QUEST_COLOR := Color("e77f6e")
const PIN_COLOR := Color("3fa7b5")
const ARRIVE_DIST := 3.5

## Player pin in world space, or null. Session-only by design (a quick "go here" note).
static var custom_pin = null
static var _ground_cache: Dictionary = {}

var _beams: Dictionary = {}  # kind -> Node3D
var _t := 0.0


static func set_pin(p) -> void:
	custom_pin = p
	if p != null:
		GameState.notify("Pin placed — follow the teal marker.", "discovery")
	else:
		GameState.notify("Pin cleared.", "info")


## Active markers: [{kind, pos (Vector3, ground), color, label}]
static func active(tree: SceneTree) -> Array:
	var out: Array = []
	if tree == null:
		return out
	var q = quest_target(tree)
	if q != null:
		var qid := GameState.quests.tracked_quest()
		out.append({"kind": "quest", "pos": _grounded(tree, q), "color": QUEST_COLOR,
			"label": String(GameState.quests.defs[qid].title) if qid != "" else "Next"})
	if custom_pin != null:
		out.append({"kind": "pin", "pos": _grounded(tree, custom_pin), "color": PIN_COLOR, "label": "Your pin"})
	return out


static func quest_target(tree: SceneTree):
	if tree == null or GameState.quests == null:
		return null
	var q := GameState.quests.tracked_quest()
	if q == "":
		return null
	var t := GameState.quests.objective_target(q)
	if t == "":
		var o := GameState.quests.objective(q)
		match String(o.get("type", "")):
			"collect":
				match String(o.get("item", "")):
					"item_berry": return GameData.region_world_pos("berry_maze")
					"item_mango": return GameData.region_world_pos("tropical_forest")
					"key_windchime": return GameData.region_world_pos("tropical_forest")
			"care": return GameData.region_world_pos("animal_farm")
			"catch": return GameData.region_world_pos("waterfall_ponds")
			"harvest": return GameData.region_world_pos("paddy_field")
			"sell", "stall_level": return GameData.region_world_pos("market_square")
		return null
	if t.begins_with("region:"):
		return GameData.region_world_pos(t.substr(7))
	if t == "stall_basket":
		return GameData.region_world_pos("market_square")
	if t == "swan" and GameState.swan:
		return GameState.swan.global_position
	for n in tree.get_nodes_in_group("interactable"):
		if n is NpcCharacter and (n as NpcCharacter).npc_id == t:
			return (n as Node3D).global_position
		if n is Interactable and (n as Interactable).object_id == t:
			return (n as Node3D).global_position
	return null


## Region centres are stored at y=0; find the real ground (cached) so markers sit on terrain.
static func _grounded(tree: SceneTree, p: Vector3) -> Vector3:
	if absf(p.y) > 0.01:
		return p
	var key := Vector2i(roundi(p.x * 2.0), roundi(p.z * 2.0))
	if _ground_cache.has(key):
		return _ground_cache[key]
	if _ground_cache.size() > 256:
		_ground_cache.clear()
	var world := tree.root.get_world_3d()
	var g := p
	if world:
		var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 40.0, p.z), Vector3(p.x, -10.0, p.z), 1)
		var hit := world.direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			g = hit.position
			_ground_cache[key] = g
	return g


# --- 3D beacon beams ---------------------------------------------------------------------------

func _ready() -> void:
	name = "WaypointBeams"
	_ground_cache.clear()


func _process(delta: float) -> void:
	_t += delta
	var show := bool(Settings.get_value("waypoints"))
	var seen := {}
	var player := GameState.player as Node3D
	if show:
		for w in active(get_tree()):
			var kind := String(w.kind)
			seen[kind] = true
			var beam: Node3D = _beams.get(kind)
			if beam == null:
				beam = _make_beam(w.color)
				_beams[kind] = beam
				add_child(beam)
			beam.global_position = w.pos
			var d := 99.0 if player == null else Vector2(player.global_position.x - w.pos.x, player.global_position.z - w.pos.z).length()
			# Fade out near the goal so it never blocks the view of what you came for.
			var a := clampf((d - ARRIVE_DIST) / 6.0, 0.0, 1.0)
			beam.visible = a > 0.01
			var pulse := 1.0 if Settings.get_value("reduced_motion") else 0.85 + sin(_t * 2.4) * 0.15
			(beam.get_meta("beam_mat") as StandardMaterial3D).albedo_color.a = 0.20 * a * pulse
			(beam.get_meta("ring_mat") as StandardMaterial3D).albedo_color.a = 0.55 * a
			var ring := beam.get_meta("ring") as Node3D
			ring.scale = Vector3.ONE * (1.0 + fmod(_t * 0.6, 1.0) * 0.6)
	for k in _beams.keys():
		if not seen.has(k):
			(_beams[k] as Node3D).queue_free()
			_beams.erase(k)


func _make_beam(color: Color) -> Node3D:
	var root := Node3D.new()
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.42
	cyl.height = 26.0
	cyl.radial_segments = 16
	cyl.cap_top = false
	cyl.cap_bottom = false
	beam.mesh = cyl
	beam.position.y = 13.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.albedo_color = Color(color.lightened(0.25), 0.2)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam.material_override = m
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(beam)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.9
	tor.outer_radius = 1.05
	tor.rings = 32
	tor.ring_segments = 6
	ring.mesh = tor
	ring.position.y = 0.08
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(color, 0.55)
	ring.material_override = rm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	root.set_meta("beam_mat", m)
	root.set_meta("ring_mat", rm)
	root.set_meta("ring", ring)
	return root
