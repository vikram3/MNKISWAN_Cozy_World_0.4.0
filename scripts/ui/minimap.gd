class_name Minimap
extends Control
## Round corner minimap (HUD): regions, paths, the stream, villagers, Swan, gathering places,
## shared-ritual hearts, sky feathers (as Swan) and waypoints. Rotates with the camera by
## default so "up" is always where you are looking; off-map waypoints cling to the rim as
## arrows. Tap/click it to open the full map.

const RANGE := 40.0  # metres from the centre to the rim

var _region_name := ""
var _yaw := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("touch_passthrough")
	tooltip_text = ""
	gui_input.connect(_on_gui_input)


func _on_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var c := size * 0.5
		if (ev.position - c).length() <= size.x * 0.5 + 6.0 and GameState.ui and not GameState.is_ui_blocking():
			AudioManager.play_sfx("ui")
			MobileUI.vibrate(10)
			GameState.ui.open_map()
			accept_event()


func _process(_d: float) -> void:
	var r := TouchControls.minimap_rect_for(get_viewport())
	position = r.position
	size = r.size
	visible = bool(Settings.get_value("minimap")) and GameState.player != null
	if visible:
		queue_redraw()


func _w2m(p: Vector3, center: Vector3, scale: float, c: Vector2) -> Vector2:
	var rel := Vector2(p.x - center.x, p.z - center.z)
	if Settings.get_value("minimap_rotate"):
		rel = rel.rotated(_yaw)
	return c + rel * scale


func _draw() -> void:
	var p := GameState.player as MnkiController
	if p == null:
		return
	_yaw = p.rig.yaw_radians() if p.rig else 0.0
	var R := size.x * 0.5
	var c := size * 0.5
	var sc := (R - 6.0) / RANGE
	var center := p.global_position
	var circle := TouchIcons.circle_poly(c, R - 5.0, 48)
	var font := get_theme_default_font()
	# Shadow + parchment
	draw_circle(c + Vector2(0, 5), R, Color(0.09, 0.23, 0.19, 0.22))
	draw_circle(c, R, Color("eef3e3"))
	# Regions
	for id in GameData.REGIONS:
		var reg: Dictionary = GameData.REGIONS[id]
		var rc: Vector2 = reg.pos
		var rs: Vector2 = reg.size
		var corners := PackedVector2Array()
		for off in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]:
			corners.append(_w2m(Vector3(rc.x + rs.x * off.x, 0, rc.y + rs.y * off.y), center, sc, c))
		var known := GameState.world.is_discovered(id)
		var col := Color(String(reg.color))
		col.a = 0.62 if known else 0.2
		for piece in Geometry2D.intersect_polygons(corners, circle):
			if piece.size() >= 3:
				draw_colored_polygon(piece, col)
	# Paths and stream
	for pair in GameData.PATHS:
		_clipped_line(GameData.region_world_pos(pair[0]), GameData.region_world_pos(pair[1]), center, sc, c, circle, Color("e3cfa3"), 7.0)
	_clipped_line(GameData.region_world_pos("colony_two"), Vector3(0, 0, 60), center, sc, c, circle, Color("e3cfa3"), 5.0)
	_clipped_line(Vector3(0, 0, 60), GameData.region_world_pos("tropical_forest"), center, sc, c, circle, Color("e3cfa3"), 5.0)
	_clipped_line(Vector3(0, 0, 12), Vector3(0, 0, 78), center, sc, c, circle, Color("78c9d4"), 6.0)
	var rr := R - 10.0
	# Villagers (tiny dots), gathering places, together hearts, sky feathers
	for npc in get_tree().get_nodes_in_group("villager"):
		var n3 := npc as Node3D
		if n3 and n3.is_visible_in_tree():
			var at := _w2m(n3.global_position, center, sc, c)
			if (at - c).length() < rr:
				draw_circle(at, 3.0, Color("8b6749", 0.85))
	for region in VillageLifeData.PLACES:
		if not GameState.world.is_discovered(region):
			continue
		var at := _w2m(GameData.region_world_pos(region) + Vector3(VillageLifeData.PLACES[region][0]), center, sc, c)
		if (at - c).length() < rr:
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(5, 0), at + Vector2(0, 5), at + Vector2(-5, 0)]), Color("367e7a"))
	for place in get_tree().get_nodes_in_group("together_place"):
		var at := _w2m((place as Node3D).global_position, center, sc, c)
		if (at - c).length() < rr and GameState.world.is_discovered(place.get_meta("region", "")):
			TouchIcons.draw(self, "heart", at, 6.0, Color("bc6284"))
	if p.character_id == "swan":
		for i in SkyTrail.STOPS.size():
			if not GameState.world.has_flag("sky_feather_%d" % i):
				var at := _w2m(SkyTrail.STOPS[i], center, sc, c)
				if (at - c).length() < rr:
					draw_arc(at, 5, 0, TAU, 14, Color("bd8a2e"), 2.0, true)
	# Friend
	if GameState.swan:
		var at := _w2m(GameState.swan.global_position, center, sc, c)
		if (at - c).length() > rr:
			at = c + (at - c).normalized() * rr
		draw_circle(at, 6.5, Color.WHITE)
		draw_arc(at, 6.5, 0, TAU, 16, Color("f2861f"), 2.0, true)
	# Waypoints: inside → pin; outside → rim arrow
	if Settings.get_value("waypoints"):
		for w in Waypoints.active(get_tree()):
			var at := _w2m(w.pos, center, sc, c)
			var col: Color = w.color
			var d := at - c
			if d.length() <= rr - 8.0:
				var pulse := 0.0 if Settings.get_value("reduced_motion") else sin(Time.get_ticks_msec() * 0.006) * 2.0
				draw_circle(at, 11.0 + pulse, Color(col, 0.3))
				draw_circle(at, 6.5, col)
				draw_arc(at, 6.5, 0, TAU, 16, Color.WHITE, 2.0, true)
			else:
				var dir := d.normalized()
				var tip := c + dir * (R - 4.0)
				var n := Vector2(-dir.y, dir.x)
				draw_colored_polygon(PackedVector2Array([tip, tip - dir * 18.0 + n * 10.0, tip - dir * 18.0 - n * 10.0]), col)
				draw_polyline(PackedVector2Array([tip, tip - dir * 18.0 + n * 10.0, tip - dir * 18.0 - n * 10.0, tip]), Color.WHITE, 1.5, true)
	# Player arrow (always centre)
	var f := p.facing_direction()
	var fd := Vector2(f.x, f.z)
	if Settings.get_value("minimap_rotate"):
		fd = fd.rotated(_yaw)
	fd = fd.normalized() if fd.length() > 0.01 else Vector2(0, -1)
	var side := Vector2(-fd.y, fd.x)
	# view cone
	var cone := PackedVector2Array([c])
	var look := Vector2(0, -1) if Settings.get_value("minimap_rotate") else Vector2(0, -1).rotated(-_yaw)
	for i in 9:
		cone.append(c + look.rotated(deg_to_rad(-32.0 + i * 8.0)) * R * 0.55)
	draw_colored_polygon(cone, Color(1, 1, 1, 0.22))
	var arrow := PackedVector2Array([c + fd * 13.0, c - fd * 8.0 + side * 9.0, c - fd * 4.0, c - fd * 8.0 - side * 9.0])
	draw_colored_polygon(arrow, Color("d8302b"))
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), Color.WHITE, 2.0, true)
	# Frame ring + north marker
	draw_arc(c, R - 2.5, 0, TAU, 64, UITheme.CREAM, 6.0, true)
	draw_arc(c, R - 6.0, 0, TAU, 64, Color(UITheme.WOOD, 0.85), 2.5, true)
	var north := Vector2(0, -1)
	if Settings.get_value("minimap_rotate"):
		north = north.rotated(_yaw)
	var np := c + north * (R - 4.0)
	draw_circle(np, 13.0, UITheme.FOREST)
	var nw := font.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, np + Vector2(-nw * 0.5, 6.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UITheme.CREAM)
	# Region name ribbon under the map
	var region := GameState.current_region_name()
	if region != "":
		var fs := 18
		var tw := font.get_string_size(region, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var w := minf(tw + 24.0, size.x + 60.0)
		var rect := Rect2(Vector2(c.x - w * 0.5, size.y - 18.0), Vector2(w, 30.0))
		draw_style_box(_ribbon(), rect)
		draw_string(font, Vector2(c.x - minf(tw, w - 24.0) * 0.5, rect.position.y + 21.0), region, HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, fs, UITheme.CREAM)


var _ribbon_sb: StyleBoxFlat


func _ribbon() -> StyleBoxFlat:
	if _ribbon_sb == null:
		_ribbon_sb = UITheme.box(Color(UITheme.FOREST, 0.88), 15, UITheme.CREAM, 2, 0)
		_ribbon_sb.shadow_size = 0
	return _ribbon_sb


func _clipped_line(a: Vector3, b: Vector3, center: Vector3, sc: float, c: Vector2, circle: PackedVector2Array, col: Color, w: float) -> void:
	var line := PackedVector2Array([_w2m(a, center, sc, c), _w2m(b, center, sc, c)])
	for seg in Geometry2D.intersect_polyline_with_polygon(line, circle):
		if seg.size() >= 2:
			draw_polyline(seg, col, w, true)
