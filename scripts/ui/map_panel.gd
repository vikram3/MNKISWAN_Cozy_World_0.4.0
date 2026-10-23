class_name MapPanel
extends ModalPanel
## Region map (GDD §12): known regions, paths, player, Swan, home, market and the current quest
## marker. Undiscovered regions stay "???" so secrets are not spoiled.

var _canvas: MapCanvas


func _init() -> void:
	super._init()
	panel_id = "map"
	title_text = "Tree Village Map"


func panel_size() -> Vector2:
	return Vector2(1100, 1000)


func build_content() -> void:
	_canvas = MapCanvas.new()
	_canvas.custom_minimum_size = Vector2(1050, 860)
	content.add_child(_canvas)


func refresh() -> void:
	_canvas.queue_redraw()


func _process(_d: float) -> void:
	if visible:
		_canvas.queue_redraw()


class MapCanvas extends Control:
	const WMIN := Vector2(-64, -106)
	const WMAX := Vector2(64, 112)

	func _w2m(p: Vector3) -> Vector2:
		var s := size
		var sc := minf(s.x / (WMAX.x - WMIN.x), s.y / (WMAX.y - WMIN.y))
		var off := (s - (WMAX - WMIN) * sc) * 0.5
		return off + (Vector2(p.x, p.z) - WMIN) * sc

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_rect(Rect2(Vector2.ZERO, size), Color("eef3e3"))
		draw_rect(Rect2(_w2m(Vector3(WMIN.x + 2, 0, WMIN.y + 2)), _w2m(Vector3(WMAX.x - 2, 0, WMAX.y - 2)) - _w2m(Vector3(WMIN.x + 2, 0, WMIN.y + 2))), Color("cfe0b8"))
		for pair in GameData.PATHS:
			draw_line(_w2m(GameData.region_world_pos(pair[0])), _w2m(GameData.region_world_pos(pair[1])), Color("e3cfa3"), 10.0, true)
		var bridge_ok := GameState.world.has_flag("bridge_restored")
		draw_line(_w2m(GameData.region_world_pos("colony_two")), _w2m(Vector3(0, 0, 60)), Color("e3cfa3"), 7.0)
		draw_line(_w2m(Vector3(0, 0, 60)), _w2m(GameData.region_world_pos("tropical_forest")), Color("e3cfa3"), 7.0)
		draw_line(_w2m(Vector3(0, 0, 12)), _w2m(Vector3(0, 0, 78)), Color("78c9d4"), 8.0)
		draw_string(font, _w2m(Vector3(1.5, 0, 63)), "bridge" if bridge_ok else "broken bridge", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("173b31") if bridge_ok else Color("b03a2e"))
		for id in GameData.REGIONS:
			var r: Dictionary = GameData.REGIONS[id]
			var c: Vector2 = r.pos
			var sz: Vector2 = r.size
			var a := _w2m(Vector3(c.x - sz.x * 0.5, 0, c.y - sz.y * 0.5))
			var b := _w2m(Vector3(c.x + sz.x * 0.5, 0, c.y + sz.y * 0.5))
			var known := GameState.world.is_discovered(id)
			var col := Color(String(r.color))
			col.a = 0.75 if known else 0.25
			draw_rect(Rect2(a, b - a), col)
			draw_rect(Rect2(a, b - a), Color("173b31", 0.6), false, 2.0)
			var label := ("%d %s" % [int(r.num), String(r.name)]) if known else ("%d ???" % int(r.num))
			draw_string(font, a + Vector2(6, 22), label, HORIZONTAL_ALIGNMENT_LEFT, b.x - a.x - 8, 17, Color("173b31"))
		# Quest marker
		for region in VillageLifeData.PLACES:
			if not GameState.world.is_discovered(region):
				continue
			var at := _w2m(GameData.region_world_pos(region) + Vector3(VillageLifeData.PLACES[region][0]))
			var color := Color("367e7a")
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -7), at + Vector2(7, 0), at + Vector2(0, 7), at + Vector2(-7, 0)]), color)
			if GameState.world.has_flag("cozy_visit_" + region):
				draw_circle(at, 2.5, Color("ffecb4"))
		# Quest marker
		var target = _quest_target()
		if target != null:
			var tp := _w2m(target)
			var pulse := 10.0 + sin(Time.get_ticks_msec() * 0.006) * 3.0
			draw_circle(tp, pulse + 6, Color("e77f6e", 0.35))
			draw_circle(tp, 8, Color("e77f6e"))
			draw_string(font, tp + Vector2(12, -10), "next", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b03a2e"))
		for place in get_tree().get_nodes_in_group("together_place"):
			if not GameState.world.is_discovered(place.get_meta("region", "")): continue
			var at := _w2m(place.global_position)
			var pink := Color("bc6284")
			draw_circle(at + Vector2(-3, -2), 4, pink)
			draw_circle(at + Vector2(3, -2), 4, pink)
			draw_colored_polygon(PackedVector2Array([at + Vector2(-7, -1), at + Vector2(7, -1), at + Vector2(0, 8)]), pink)
		# Swan
		if GameState.swan:
			draw_circle(_w2m(GameState.swan.global_position), 7, Color.WHITE)
			draw_arc(_w2m(GameState.swan.global_position), 7, 0, TAU, 16, Color("f2861f"), 2.0)
		# Player arrow
		var p := GameState.player as MnkiController
		if p:
			var pp := _w2m(p.global_position)
			var f := p.facing_direction()
			var fd := Vector2(f.x, f.z).normalized()
			var side := Vector2(-fd.y, fd.x)
			draw_colored_polygon(PackedVector2Array([pp + fd * 16, pp - fd * 9 + side * 9, pp - fd * 9 - side * 9]), Color("d8302b"))
			draw_polyline(PackedVector2Array([pp + fd * 16, pp - fd * 9 + side * 9, pp - fd * 9 - side * 9, pp + fd * 16]), Color("173b31"), 2.0)
		for i in SkyTrail.STOPS.size():
			if not GameState.world.has_flag("sky_feather_%d" % i):
				var pos := _w2m(SkyTrail.STOPS[i])
				draw_arc(pos, 6, 0, TAU, 20, Color("bd8a2e"), 2.5)
		draw_string(font, Vector2(16, size.y - 36), "Teal: gathering places · Pink hearts: shared rituals · Gold centres: completed", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("173b31"))
		draw_string(font, Vector2(16, size.y - 14), "Arrow: you · White: friend · Gold rings: sky feathers · Coral: objective", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("173b31"))

	func _quest_target():
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
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is NpcCharacter and (n as NpcCharacter).npc_id == t:
				return (n as Node3D).global_position
			if n is Interactable and (n as Interactable).object_id == t:
				return (n as Node3D).global_position
		return null
