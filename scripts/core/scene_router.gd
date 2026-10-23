extends CanvasLayer
## SceneRouter: calm fade transitions between title and world (GDD §15).

const TITLE := "res://scenes/menus/title_menu.tscn"
const WORLD := "res://scenes/world/tree_village_world.tscn"

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_fade = ColorRect.new()
	_fade.color = Color(0.984, 0.969, 0.929, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	if "--verify-build" in OS.get_cmdline_user_args():
		_verify_build.call_deferred()


## Packaged-export smoke check. Run with a disposable user-data directory.
func _verify_build() -> void:
	await get_tree().process_frame
	await go_world(false)
	var p := GameState.player as MnkiController
	if p == null:
		printerr("BUILD CHECK FAILED: world did not create the player")
		get_tree().quit(1)
		return
	p.teleport(Vector3(48, 0.3, -22))
	GameState.swan.global_position = Vector3(50, 0.3, -22)
	for i in 50:
		await get_tree().physics_frame
	p.model.clear_action()
	var switched := p.switch_character()
	var took_off := p.toggle_flight()
	Input.action_press("jump")
	for i in 75:
		await get_tree().physics_frame
	Input.action_release("jump")
	var airborne := p.global_position.y > 3.0 and p.character_id == "swan" and p.model is SwanModel
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://build-flight.png")
	p.toggle_flight()
	for i in 180:
		await get_tree().physics_frame
	var landed := p.flight_mode == "grounded" and p.is_on_floor()
	var village: Node3D = p.get_parent()
	var daily := village.get_node("DailyLife") as DailyLife
	var ritual := village.get_node("TogetherMoments") as TogetherMoments
	p.model.clear_action()
	GameState.swan.model.clear_action()
	var together_ok := ritual.begin("appreciate")
	if together_ok: ritual.finish(false)
	TimeManager.minute = 22 * 60
	daily.sync_clock(true)
	var schedule_ok: bool = daily.initialized and daily.residents.poppy.sleeping and not daily.residents.tamsin.sleeping
	var activities := get_tree().get_nodes_in_group("cozy_activity")
	var life_ready := activities.size() == 39 and get_tree().get_nodes_in_group("villager").size() == 31
	var activity_ok := false
	if life_ready:
		var activity: CozyActivity = activities[0]
		p.teleport(activity.global_position + Vector3(0, 0.1, 1.1))
		var coins := GameState.economy.coins
		activity_ok = activity.complete(p) and GameState.economy.coins == coins + 2 and activity.result.visible
	var ok := switched and took_off and airborne and landed and life_ready and activity_ok and together_ok and schedule_ok
	print("PACKAGED BUILD CHECK: switch=%s takeoff=%s airborne=%s landed=%s" % [switched, took_off, airborne, landed])
	print("PACKAGED VILLAGE CHECK: world=%s activity=%s" % [life_ready, activity_ok])
	print("PACKAGED DAILY CHECK: together=%s night_schedule=%s" % [together_ok, schedule_ok])
	get_tree().quit(0 if ok else 1)


func fade(to_alpha: float, time: float = 0.45) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", to_alpha, time)
	await tw.finished


func go_world(load_save: bool) -> void:
	if _busy:
		return
	_busy = true
	if load_save:
		if not SaveManager.prepare_load():
			GameState.notify("Save could not be loaded — starting fresh.", "warn")
			load_save = false
	if not load_save:
		SaveManager.clear_pending()
		GameState.new_game()
	await fade(1.0)
	get_tree().change_scene_to_file(WORLD)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade(0.0, 0.8)
	_busy = false


func go_title() -> void:
	if _busy:
		return
	_busy = true
	await fade(1.0)
	GameState.in_world = false
	GameState.clear_ui()
	TimeManager.running = false
	AudioManager.stop_world_audio()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(TITLE)
	await get_tree().process_frame
	await fade(0.0)
	_busy = false
