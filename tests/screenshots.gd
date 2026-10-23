extends Node
## Renders marketing/QA screenshots of key locations to user://shots/ (needs a display/GPU).
## Run: godot --path . res://tests/screenshots.tscn

const SHOTS := [
	["market_stall", "market_square", Vector3(-4.5, 0, 1.0), 180.0],
	["animal_farm", "animal_farm", Vector3(2.5, 0, -7.5), 0.0],
	["waterfall", "waterfall_ponds", Vector3(-2, 0, 6), 160.0],
	["park_festival", "village_park", Vector3(-3, 0, 10.5), 175.0],
	["paddy", "paddy_field", Vector3(-1.0, 0, 7.5), 180.0],
	["berry_maze", "berry_maze", Vector3(0, 0, -13), 0.0],
	["tropical", "tropical_forest", Vector3(0, 0, -12), 0.0],
	["treehouse", "treehouse", Vector3(5.0, 0, 2.0), -100.0],
]

func _ready() -> void:
	SaveManager.delete_save()
	GameState.new_game()
	# Showcase state: restored village, upgraded stall, decorated home.
	for f in ["gate_open", "park_restored", "festival", "bridge_restored"]:
		GameState.world.set_flag(f)
	GameState.shop.level = 3
	GameState.shop.display_count = 30
	for a in ["anchor_rug", "anchor_lamp", "anchor_stool", "anchor_basket", "anchor_plant", "anchor_picture", "anchor_teapot", "anchor_lantern", "anchor_flowerpot"]:
		GameState.world.decor[a] = GameData.DECOR_ANCHORS[a].item
	TimeManager.minute = 600.0
	var world: Node = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await get_tree().create_timer(0.5).timeout
	GameState.ui.hud.force_hidden = true
	DirAccess.make_dir_recursive_absolute("user://shots")
	for s in SHOTS:
		var pl := GameState.player as MnkiController
		var base := GameData.region_world_pos(s[1])
		var at: Vector3 = base + s[2]
		pl.teleport(at + Vector3(0, 0.3, 0), s[3])
		var f := Vector3(sin(deg_to_rad(s[3])), 0, cos(deg_to_rad(s[3])))
		GameState.swan.global_position = at + Vector3.UP.cross(f) * 1.5 + Vector3(0, 0.2, 0)
		if s[0] == "park_festival":
			TimeManager.minute = 1260.0
		else:
			TimeManager.minute = 600.0
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % s[0])
		print("shot ", s[0])
	get_tree().quit()
