extends Node
## Renders the phone/tablet UI at several real device shapes to user://shots/mobile_*.png
## (needs a display/GPU, e.g. xvfb-run). Also asserts that touch buttons, minimap and HUD stay
## on screen and clear of the simulated notches at every size.
## Run: godot --path . res://tests/mobile_gallery.tscn

const DEVICES := [
	# name, window size, notch insets (l, t, r, b) in window px, touch?
	["phone_20x9_notch", Vector2i(2400, 1080), Vector4(96, 0, 96, 30), true],
	["phone_16x9", Vector2i(1920, 1080), Vector4(0, 0, 0, 0), true],
	["tablet_4x3", Vector2i(2048, 1536), Vector4(0, 0, 0, 24), true],
	["desktop_16x9", Vector2i(1600, 900), Vector4(0, 0, 0, 0), false],
]
var failed := 0


func _ready() -> void:
	SaveManager.delete_save()
	Settings.data["tutorial_done"] = true
	GameState.new_game()
	TimeManager.minute = 610.0
	var world: Node = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await _frames(60)
	GameState.clear_ui()
	DirAccess.make_dir_recursive_absolute("user://shots")
	var p := GameState.player as MnkiController
	var park := GameData.region_world_pos("village_park")
	for d in DEVICES:
		MobileUI.force_mobile = d[3]
		Settings.data["touch_controls"] = "auto" if d[3] else "off"
		get_window().size = d[1]
		await _frames(4)
		var ratio := get_viewport().get_visible_rect().size.x / float(d[1].x)
		MobileUI.debug_safe_insets = (d[2] as Vector4) * ratio
		UITheme.rebuild()
		GameState.ui.touch._layout()
		p.teleport(park + Vector3(2, 0.3, 9), 200.0)
		GameState.swan.global_position = park + Vector3(3.5, 0.3, 10)
		Waypoints.custom_pin = GameData.region_world_pos("market_square")
		await _frames(30)
		if d[3]:
			var tc: TouchControls = GameState.ui.touch
			tc.touch_down(0, tc.stick_rest)
			tc.touch_move(0, tc.stick_center + Vector2(tc.stick_radius * 0.5, -tc.stick_radius * 0.8), Vector2.ZERO)
			await _frames(25)
			_assert_layout(String(d[0]))
			await _shot("mobile_%s" % d[0])
			tc.touch_up(0, Vector2.ZERO)
		else:
			await _frames(20)
			await _shot("mobile_%s" % d[0])
	# Phone extras: tutorial card, Swan flying, full map with a pin.
	MobileUI.force_mobile = true
	Settings.data["touch_controls"] = "auto"
	get_window().size = Vector2i(2400, 1080)
	await _frames(4)
	MobileUI.debug_safe_insets = Vector4(96, 0, 96, 30) * (get_viewport().get_visible_rect().size.x / 2400.0)
	GameState.ui.touch._layout()
	p.teleport(park + Vector3(2, 0.3, 9), 200.0)
	GameState.ui.tutorial.start()
	await _frames(40)
	await _shot("mobile_tutorial")
	GameState.ui.tutorial.running = false
	Settings.data["tutorial_done"] = true
	p.switch_character()
	await _frames(10)
	p.toggle_flight()
	Input.action_press("jump")
	await _frames(90)
	Input.action_release("jump")
	await _frames(20)
	await _shot("mobile_flying")
	GameState.ui.open_map()
	await _frames(10)
	await _shot("mobile_map")
	GameState.ui.map.close()
	print("MOBILE GALLERY: ", "OK" if failed == 0 else "%d layout failures" % failed)
	get_tree().quit(0 if failed == 0 else 1)


func _assert_layout(dev: String) -> void:
	var tc: TouchControls = GameState.ui.touch
	var vs := tc.get_viewport_rect().size
	var ins := MobileUI.safe_insets(get_viewport())
	var safe := Rect2(Vector2(ins.x, ins.y), vs - Vector2(ins.x + ins.z, ins.y + ins.w))
	for b in tc.buttons:
		if not b.show:
			continue
		var r := float(b.r)
		var box := Rect2(b.pos - Vector2(r, r), Vector2(r, r) * 2.0)
		if not safe.encloses(box):
			failed += 1
			print("FAIL %s: button %s outside safe area" % [dev, b.id])
	var hud: HUD = GameState.ui.hud
	for c in [hud.minimap, hud._tl, hud._obj_box, hud._card]:
		var r: Rect2 = (c as Control).get_global_rect()
		r.size *= (c as Control).scale
		if (c as Control).visible and not safe.grow(1.0).encloses(r):
			failed += 1
			print("FAIL %s: %s outside safe area %s" % [dev, c.get_class(), r])
	# HUD blocks must not collide with each other on the top row.
	var tl: Rect2 = hud._tl.get_global_rect()
	tl.size *= hud._tl.scale
	var ob: Rect2 = hud._obj_box.get_global_rect()
	ob.size *= hud._obj_box.scale
	if tl.intersects(ob) or ob.intersects(hud.minimap.get_global_rect()):
		failed += 1
		print("FAIL %s: top HUD blocks overlap" % dev)
	print("layout %s: %s canvas %s" % [dev, "ok" if failed == 0 else "issues", vs])


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % n)
	print("shot ", n)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
