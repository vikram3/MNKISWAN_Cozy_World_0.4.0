extends Node
## Mobile / touch regression: virtual joystick, swipe-look, pinch, thumb buttons, menu row,
## notch-safe layout, minimap, waypoints & personal pins, and the first-play tutorial.
## Simulates a phone (MobileUI.force_mobile + 90 px notch insets) and drives TouchControls
## through the same entry points real InputEventScreenTouch/Drag events use.
var passed := 0
var failed := 0
var world: Node
var p: MnkiController
var tc: TouchControls


func _ready() -> void:
	MobileUI.force_mobile = true
	MobileUI.debug_safe_insets = Vector4(90, 0, 90, 24)
	Settings.data["touch_controls"] = "auto"
	Settings.data["tutorial_done"] = false
	UITheme.rebuild()
	GameState.new_game()
	SaveManager.clear_pending()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	p = GameState.player
	tc = GameState.ui.touch
	await frames(70)
	GameState.clear_ui()
	p.teleport(Vector3(48, 0.3, -22))
	GameState.swan.global_position = Vector3(50, 0.3, -22)
	await frames(40)
	check(MobileUI.touch_enabled(), "auto mode enables touch controls on a phone")
	check(tc.visible and tc.active(), "touch layer is shown in the world")
	check(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED, "mouse is never captured in touch mode")
	_check_layout()

	# --- Joystick ----------------------------------------------------------------------------
	var vs := tc.get_viewport_rect().size
	var down := tc.stick_rest + Vector2(10, -10)
	check(tc.touch_down(0, down), "left-side touch is claimed by the joystick")
	check(tc.stick_finger == 0, "joystick follows that finger")
	check(tc.stick_center.distance_to(down) < 2.0, "floating stick spawns under the thumb")
	var start := p.global_position
	tc.touch_move(0, tc.stick_center + Vector2(0, -tc.stick_radius * 0.6), Vector2.ZERO)
	check(Input.get_action_strength("move_forward") > 0.4, "push up = move forward strength")
	check(Input.get_action_strength("move_back") == 0.0, "no opposite axis bleed")
	check(not Input.is_action_pressed("run"), "half push walks (no sprint)")
	await frames(40)
	var gv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	check(absf(gv.length() - tc.stick_vec.length()) < 0.03, "game input matches the thumb exactly (deadzone compensated)")
	check(p.global_position.distance_to(start) > 1.0, "player walks with the virtual stick")
	tc.touch_move(0, tc.stick_center + Vector2(tc.stick_radius * 1.1, 0), Vector2.ZERO)
	check(Input.get_action_strength("move_right") > 0.9, "full push right")
	check(Input.is_action_pressed("run"), "stick at the rim sprints")
	await frames(20)
	check(p.velocity.length() > p.walk_speed + 0.3, "sprint reaches running speed")
	var before_center := tc.stick_center
	tc.touch_move(0, tc.stick_center + Vector2(tc.stick_radius * 3.0, 0), Vector2.ZERO)
	check(tc.stick_center.x > before_center.x, "dragging far past the rim pulls the stick along")
	tc.touch_up(0, Vector2.ZERO)
	check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"), "lifting the thumb releases movement and sprint")
	tc.touch_down(0, tc.stick_rest + Vector2(4, 4))
	tc.touch_move(0, tc.stick_center + Vector2(4, 0), Vector2.ZERO)
	check(tc.stick_vec == Vector2.ZERO, "tiny wobble stays in the deadzone")
	tc.touch_up(0, Vector2.ZERO)
	await frames(20)

	# --- Look & pinch ------------------------------------------------------------------------
	var yaw0 := p.rig.yaw_radians()
	var lp := Vector2(vs.x * 0.62, vs.y * 0.5)
	check(tc.touch_down(1, lp), "right-side touch is claimed for camera look")
	tc.touch_move(1, lp + Vector2(200, 0), Vector2(200, 0))
	check(absf(angle_difference(yaw0, p.rig.yaw_radians())) > deg_to_rad(20), "swipe turns the camera")
	tc.touch_down(2, lp + Vector2(0, 160))
	var d0 := p.rig.distance
	tc.touch_move(2, lp + Vector2(0, 40), Vector2(0, -120))
	check(p.rig.distance > d0 + 0.5 or p.rig.distance >= CameraRig.MAX_DIST - 0.01, "pinch-in zooms the camera out")
	tc.touch_move(2, lp + Vector2(0, 420), Vector2(0, 380))
	check(p.rig.distance < d0 + 0.5, "pinch-out zooms back in")
	tc.touch_up(1, Vector2.ZERO)
	tc.touch_up(2, Vector2.ZERO)
	check(tc.look_fingers.is_empty(), "look fingers are released")

	# --- Multi-touch: walk while jumping ------------------------------------------------------
	tc.touch_down(0, tc.stick_rest)
	tc.touch_move(0, tc.stick_center + Vector2(0, -tc.stick_radius), Vector2.ZERO)
	var jb := tc.button("jump")
	check(tc.touch_down(3, jb.pos), "second finger presses Jump while walking")
	await frames(2)
	check(Input.is_action_pressed("jump") and Input.is_action_pressed("move_forward"), "jump and move are held together")
	await frames(10)
	check(not p.is_on_floor(), "touch jump leaves the ground")
	tc.touch_up(3, jb.pos)
	tc.touch_up(0, Vector2.ZERO)
	await frames(2)
	check(not Input.is_action_pressed("jump"), "jump releases with the finger")
	await frames(60)

	# --- Swap & flight buttons ----------------------------------------------------------------
	check(tc.button("swap").show and not tc.button("wings").show, "Mnki shows swap but not wings")
	var sw := tc.button("swap")
	tc.touch_down(4, sw.pos)
	tc.touch_up(4, sw.pos)
	await frames(4)
	check(p.character_id == "swan", "portrait button switches to Swan")
	await frames(2)
	check(tc.button("wings").show, "Swan gets the Fly button")
	var wb := tc.button("wings")
	tc.touch_down(5, wb.pos)
	tc.touch_up(5, wb.pos)
	await frames(4)
	check(p.flight_mode != "grounded", "Fly button takes off")
	await frames(2)
	check(tc.button("descend").show and not tc.button("swap").show, "in flight: Down appears, swap hides")
	check(tc.button("jump").label == "Rise", "jump becomes Rise while flying")
	tc.touch_down(5, tc.button("wings").pos)
	tc.touch_up(5, tc.button("wings").pos)
	for i in 240:
		await get_tree().physics_frame
		if p.flight_mode == "grounded":
			break
	check(p.flight_mode == "grounded", "tapping Land brings Swan down")
	await frames(20)

	# --- Interact button ----------------------------------------------------------------------
	var ab := tc.button("act")
	var probe := _Probe.new()
	add_child(probe)
	tc.touch_down(6, ab.pos)
	await frames(2)
	check(probe.got.has("interact"), "action button sends an interact event")
	tc.touch_up(6, ab.pos)
	await frames(2)
	check(not Input.is_action_pressed("interact"), "interact releases")
	GameState.clear_ui()
	await frames(4)

	# --- Menu row -----------------------------------------------------------------------------
	var mb := tc.button("map")
	tc.touch_down(7, mb.pos)
	tc.touch_up(7, mb.pos)
	await frames(2)
	check(GameState.top_ui() == "map", "map button opens the map")
	check(not tc.visible, "touch controls hide behind menus")
	GameState.ui.map.close()
	await frames(2)
	tc.touch_down(7, tc.button("inventory").pos)
	tc.touch_up(7, tc.button("inventory").pos)
	await frames(2)
	check(GameState.top_ui() == "inventory", "bag button opens the inventory")
	GameState.ui.inventory.close()
	tc.touch_down(7, tc.button("pause").pos)
	tc.touch_up(7, tc.button("pause").pos)
	await frames(2)
	check(GameState.top_ui() == "pause", "pause button pauses")
	GameState.ui.pause.close()
	await frames(2)
	# Holding the stick when a menu opens must not leave the hero walking afterwards.
	tc.touch_down(0, tc.stick_rest)
	tc.touch_move(0, tc.stick_center + Vector2(0, -tc.stick_radius), Vector2.ZERO)
	GameState.ui.journal.open()
	await frames(3)
	check(not Input.is_action_pressed("move_forward") and tc.stick_finger == -1, "opening a menu releases a held stick")
	GameState.ui.journal.close()
	await frames(3)

	# --- Minimap, waypoints, pins --------------------------------------------------------------
	var hud: HUD = GameState.ui.hud
	check(hud.minimap.visible, "minimap is visible")
	var mmr := hud.minimap.get_global_rect()
	check(mmr.end.x <= vs.x - 90.0 + 0.5 and mmr.position.y >= 0.0, "minimap respects the notch inset")
	var targets := Waypoints.active(get_tree())
	print("waypoints: ", targets.size(), " tracked: ", GameState.quests.tracked_quest())
	Waypoints.set_pin(Vector3(-38, 0, 60))
	await frames(3)
	check(Waypoints.active(get_tree()).any(func(w): return w.kind == "pin"), "personal pin becomes a waypoint")
	check(hud.markers.last_positions.has("pin"), "pin is drawn on screen (pin or edge arrow)")
	var pin_mark: Dictionary = hud.markers.last_positions.get("pin", {})
	var pm: Vector2 = pin_mark.get("pos", Vector2(-1, -1))
	check(pm.x >= 90.0 and pm.x <= vs.x - 90.0 and pm.y >= 0.0 and pm.y <= vs.y, "waypoint marker stays inside the safe screen area")
	check(world.get_node_or_null("WaypointBeams") != null and world.get_node("WaypointBeams").get_child_count() > 0, "3D beacon beam exists for the pin")
	p.teleport(Vector3(-38, 0.4, 61.0))
	await frames(10)
	check(Waypoints.custom_pin == null, "arriving at a pin clears it")
	# Map tap → pin
	GameState.ui.map.open()
	await frames(2)
	var canvas = GameState.ui.map._canvas
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = canvas._w2m(Vector3(30, 0, 30))
	canvas._on_input(ev)
	check(Waypoints.custom_pin != null and Vector2(Waypoints.custom_pin.x, Waypoints.custom_pin.z).distance_to(Vector2(30, 30)) < 1.0, "tapping the full map drops a pin there")
	canvas._on_input(ev)
	check(Waypoints.custom_pin == null, "tapping the pin again clears it")
	GameState.ui.map.close()
	await frames(2)
	# Minimap tap opens the map
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = hud.minimap.size * 0.5
	hud.minimap._on_gui_input(click)
	check(GameState.top_ui() == "map", "tapping the minimap opens the full map")
	GameState.ui.map.close()
	await frames(2)
	check(not tc.touch_down(9, mmr.get_center()), "touches on the minimap are left to the minimap")

	# --- Tutorial -----------------------------------------------------------------------------
	var tut: Tutorial = GameState.ui.tutorial
	if not tut.running:
		tut.start()
	tut.step = -1
	tut._advance()
	await frames(2)
	check(tut.current_id() == "move" and tut.visible, "tutorial starts with walking")
	check(tut._body.text.contains("Drag"), "tutorial uses touch wording on phones")
	tc.touch_down(0, tc.stick_rest)
	tc.touch_move(0, tc.stick_center + Vector2(0, -tc.stick_radius * 0.8), Vector2.ZERO)
	for i in 120:
		await get_tree().process_frame
		if tut.current_id() != "move":
			break
	tc.touch_up(0, Vector2.ZERO)
	check(tut.current_id() == "look", "walking completes the first step")
	tc.touch_down(1, lp)
	for i in 6:
		tc.touch_move(1, lp + Vector2(60 * (i + 1), 0), Vector2(60, 0))
		await frames(1)
	tc.touch_up(1, Vector2.ZERO)
	await frames(50)
	check(tut.current_id() == "waypoint", "looking around completes the second step")
	tut.finish(true)
	check(bool(Settings.get_value("tutorial_done")) and not tut.visible, "skip ends the tutorial and remembers it")

	# --- Desktop fallback -----------------------------------------------------------------------
	Settings.data["touch_controls"] = "off"
	await frames(3)
	check(not tc.visible, "touch controls hide when turned off")
	await frames(2)
	Settings.data["touch_controls"] = "auto"
	MobileUI.force_mobile = false
	MobileUI.touch_seen = false
	MobileUI.debug_safe_insets = null
	await frames(3)
	check(not MobileUI.touch_enabled() and not tc.visible, "auto mode stays off on desktop without touches")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	MobileUI.note_event(touch)
	check(MobileUI.touch_enabled(), "a real touch on a desktop touchscreen turns touch controls on")
	var key := InputEventKey.new()
	key.pressed = true
	MobileUI.note_event(key)
	check(not MobileUI.touch_enabled(), "typing on a keyboard turns them back off")
	print("MOBILE UI: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


## Every touch target must be on screen, outside the notch insets, and not overlap another.
func _check_layout() -> void:
	var vs := tc.get_viewport_rect().size
	var ok := true
	var overlap := false
	var shown: Array = tc.buttons.filter(func(b): return b.show or b.id in ["descend", "wings", "seed"])
	for b in shown:
		var r := float(b.r)
		if b.pos.x - r < 90.0 - 0.5 or b.pos.x + r > vs.x - 90.0 + 0.5 or b.pos.y - r < 0.0 or b.pos.y + r > vs.y - 24.0 + 0.5:
			ok = false
			print("  off-safe: ", b.id, " ", b.pos)
	for i in shown.size():
		for j in range(i + 1, shown.size()):
			var a: Dictionary = shown[i]
			var c: Dictionary = shown[j]
			if (a.id == "descend" and c.id == "seed") or (a.id == "seed" and c.id == "descend"):
				continue  # mutually exclusive slot
			if a.pos.distance_to(c.pos) < float(a.r) + float(c.r) + 4.0:
				overlap = true
				print("  overlap: ", a.id, " ", c.id)
	check(ok, "all touch buttons sit inside the safe area")
	check(not overlap, "touch buttons never overlap")
	var stick_ok := tc.stick_rest.x - tc.stick_radius >= 90.0 and tc.stick_rest.y + tc.stick_radius <= vs.y - 24.0
	check(stick_ok, "joystick rests inside the safe area")
	var act := tc.button("act")
	check(float(act.r) * 2.0 >= 150.0, "main action button is thumb-sized")


class _Probe extends Node:
	var got := {}
	func _input(e: InputEvent) -> void:
		if e is InputEventAction and e.pressed:
			got[e.action] = true


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
