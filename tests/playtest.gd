extends Node
## Automated end-to-end playtest (GDD §18 acceptance): new game → opening quests → animal care
## → first sale → village basket → farming → fishing → upgrade → save/load round trip.
## Run headless:  godot --headless --path . res://tests/playtest.tscn
## Optional screenshots (needs a display):  add  -- --shots

var world: Node
var passed := 0
var failed := 0
var shots := false


func _ready() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	SaveManager.delete_save()
	GameState.new_game()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await _frames(20)
	await _run()
	print("\n==== PLAYTEST: %d passed, %d failed ====" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("  [PASS] ", label)
	else:
		failed += 1
		printerr("  [FAIL] ", label)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _drain() -> void:
	var d: DialogueBox = GameState.ui.dialogue
	var guard := 0
	while d.is_active() and guard < 50:
		d._finish(0)
		guard += 1
		await _frames(1)


func _find(id: String) -> Node:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is NpcCharacter and (n as NpcCharacter).npc_id == id:
			return n
		if (n as Interactable).object_id == id:
			return n
	return null


func _go(p: Vector3) -> void:
	var pl := GameState.player as MnkiController
	pl.teleport(p + Vector3(0, 0.3, 0), 0)
	await _frames(20)


func _shot(name: String, at: Vector3, yaw: float) -> void:
	if not shots:
		return
	var pl := GameState.player as MnkiController
	pl.teleport(at + Vector3(0, 0.3, 0), yaw)
	var f := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	GameState.swan.global_position = at + Vector3.UP.cross(f) * 1.5 + Vector3(0, 0.2, 0)
	await _frames(45)
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot_%s.png" % name)
	print("  [shot] ", name)


func _run() -> void:
	var pl := GameState.player as MnkiController
	var q := GameState.quests
	print("-- Boot")
	check(pl != null and GameState.swan != null, "player and Swan spawned")
	check(q.is_active("q_arrival"), "opening quest started")
	check(GameState.world.is_discovered("sunshine_forest"), "start region discovered")
	await _shot("01_forest_start", GameData.region_world_pos("sunshine_forest") + Vector3(0, 0, 3), 180)

	print("-- A Morning Together")
	GameState.swan._on_talk(pl)
	await _drain()
	check(int(q.states["q_arrival"].step) == 1, "talked to Swan")
	(_find("sf_berry_1") as GatherNode).interact(pl)
	await _frames(40)
	check(GameState.inventory.count("item_berry") == 2, "gathered 2 berries")
	check(not (_find("sf_berry_1") as GatherNode).is_ready_to_pick(), "berry bush shows picked state")
	(_find("sf_berry_1") as GatherNode).interact(pl)
	check(GameState.inventory.count("item_berry") == 2, "picked bush cannot be harvested twice")
	check(int(q.states["q_arrival"].step) == 2, "collect objective advanced")
	(_find("gate_main") as ActionPoint).interact(pl)
	await _drain()
	check(GameState.world.has_flag("gate_open"), "Guardian Gate opened")
	await _shot("02_guardian_gate", GameData.region_world_pos("guardian_gate") + Vector3(-1.5, 0, -6), 170)
	await _go(GameData.region_world_pos("treehouse"))
	await _frames(30)
	await _drain()
	check(q.is_done("q_arrival"), "arrived home: quest complete")
	check(q.is_active("q_gentle_hands"), "Gentle Hands auto-started")
	check(GameState.economy.coins == 5, "reward coins paid once (5)")
	await _shot("03_treehouse", GameData.region_world_pos("treehouse") + Vector3(5.5, 0, 2.5), -100)

	print("-- Gentle Hands")
	await _go(GameData.region_world_pos("animal_farm") + Vector3(-2, 0, -6))
	var thronn := _find("thronn") as NpcCharacter
	thronn.interact(pl)
	await _drain()
	check(int(q.states["q_gentle_hands"].step) == 1, "talked to Thronn")
	var cow := _find("cow_daisy") as FarmAnimal
	cow.interact(pl)
	await _frames(5)
	check(int(q.states["q_gentle_hands"].step) == 2, "petted an animal")
	cow.interact(pl)
	check(GameState.inventory.count("item_feed") == 0, "feeding without feed is refused safely")
	(_find("feed_bin") as ActionPoint).interact(pl)
	check(GameState.inventory.count("item_feed") == 3, "took 3 Hay & Grain")
	var hen := _find("chicken_pip") as FarmAnimal
	hen.interact(pl)   # pet
	hen.interact(pl)   # feed
	await _drain()
	check(q.is_done("q_gentle_hands"), "Gentle Hands complete")
	check(GameState.inventory.count("seed_tomato") == 2 and GameState.inventory.count("seed_rice") == 3, "seed rewards received")
	await _shot("04_animal_farm", GameData.region_world_pos("animal_farm") + Vector3(3, 0, -7), 0)

	print("-- Open the Stall")
	await _go(GameData.region_world_pos("market_square") + Vector3(-5, 0, 6))
	(_find("tamsin") as NpcCharacter).interact(pl)
	await _drain()
	var coins_before := GameState.economy.coins
	var res := GameState.shop.sell({"item_berry": 2})
	check(res.ok, "valid berry sale succeeds")
	check(GameState.economy.coins == coins_before + 4, "sold 2 berries for 4 coins")
	var res_bad := GameState.shop.sell({"item_berry": 99})
	check(not res_bad.ok and GameState.economy.coins == coins_before + 4, "oversell rejected, coins unchanged")
	GameState.inventory.add("item_mango", 2)
	GameState.shop.sell({"item_mango": 2})
	await _drain()
	check(q.is_done("q_open_stall"), "Open the Stall complete (10 coins of sales)")
	check(q.is_active("q_village_basket"), "Village Basket auto-started")
	await _shot("05_market", GameData.region_world_pos("market_square") + Vector3(-4.5, 0, 0.5), 180)

	print("-- A Basket for the Village")
	await _go(GameData.region_world_pos("berry_maze") + Vector3(0, 0, -11))
	for id in ["bm_berry_0", "bm_berry_1"]:
		(_find(id) as GatherNode).interact(pl)
		await _frames(40)
	check(GameState.inventory.count("item_berry") >= 3, "gathered maze berries")
	(_find("tf_mango_1") as GatherNode).interact(pl)
	await _frames(40)
	check(GameState.inventory.count("item_mango") >= 1, "picked a mango")
	await _drain()
	cow.interact(pl)   # brush (pet & feed done today) counts as care
	await _drain()
	check(GameState.quests.has_deliver_for("stall_basket"), "basket step reached")
	var berries_before := GameState.inventory.count("item_berry")
	var r2 := GameState.quests.try_deliver("stall_basket")
	await _drain()
	check(r2.ok and GameState.inventory.count("item_berry") == berries_before - 3, "basket consumed exactly 3 berries")
	(_find("elder") as NpcCharacter).interact(pl)
	await _drain()
	check(q.is_done("q_village_basket"), "basket delivered to Elder")
	check(GameState.world.has_flag("park_restored"), "park flower bed restored (world change)")
	await _shot("06_park_restored", GameData.region_world_pos("village_park") + Vector3(-5, 0, -1), 160)

	print("-- Farming: plant, water, sleep, harvest")
	await _go(GameData.region_world_pos("paddy_field") + Vector3(0, 0, 3))
	GameState.selected_seed = "seed_rice"
	var plot := _find("plot_01") as FarmPlot
	plot.interact(pl)
	check(String(GameState.world.get_state("plot_01").crop) == "rice", "planted rice")
	plot.interact(pl)
	check(int(GameState.world.get_state("plot_01").watered_day) == TimeManager.day, "watered")
	TimeManager.sleep_to_morning()
	await _frames(5)
	plot.interact(pl)
	TimeManager.sleep_to_morning()
	await _frames(5)
	check(plot.is_ready_crop(), "rice ready after 2 watered days")
	var rice_before := GameState.inventory.count("item_rice")
	plot.interact(pl)
	check(GameState.inventory.count("item_rice") == rice_before + 2, "harvested 2 rice")
	check(String(GameState.world.get_state("plot_01").crop) == "", "plot empty after harvest")
	plot.interact(pl)  # pressing again replants instead of harvesting twice
	check(GameState.inventory.count("item_rice") == rice_before + 2, "no double harvest")
	await _shot("07_paddy", GameData.region_world_pos("paddy_field") + Vector3(0, 0, 6), 180)

	print("-- Eggs next morning")
	var nest: Dictionary = GameState.world.get_state("nest_farm", {"eggs": 0})
	check(int(nest.eggs) >= 1, "fed chicken laid an egg overnight")

	print("-- Fishing")
	await _go(GameData.region_world_pos("waterfall_ponds") + Vector3(1.0, 0, -0.4))
	var spot := _find("fish_pond") as FishingSpot
	spot.interact(pl)
	check(pl.state == "fishing", "player entered fishing state")
	var guard := 0
	while spot.state != "bite" and guard < 600:
		await _frames(1)
		guard += 1
	check(spot.state == "bite", "bite cue fired")
	spot.press()
	check(GameState.stats.fish_caught == 1, "caught a fish")
	await get_tree().create_timer(1.0).timeout
	check(pl.state == "free", "fishing ended cleanly")
	await _drain()
	await _shot("08_waterfall", GameData.region_world_pos("waterfall_ponds") + Vector3(2, 0, 4), 180)

	print("-- Stall upgrade & orders")
	GameState.economy.add(200, "test")
	var up := GameState.shop.upgrade()
	check(up.ok and GameState.shop.level == 1, "stall upgraded to level 1")
	GameState.shop.ensure_orders()
	check(GameState.shop.orders.size() == 2, "order board shows 2 orders")
	await _shot("09_stall_upgraded", GameData.region_world_pos("market_square") + Vector3(-4.5, 0, 0.5), 180)

	print("-- Decor")
	GameState.shop.buy("decor_rug", 1)
	var anchor := _find("anchor_rug") as DecorAnchor
	anchor.interact(pl)
	check(GameState.world.decor.get("anchor_rug", "") == "decor_rug" and GameState.inventory.count("decor_rug") == 0, "rug placed on anchor")
	var anchor2 := _find("anchor_keepsake_1") as DecorAnchor
	anchor2.interact(pl)
	check(GameState.world.decor.get("anchor_keepsake_1", "") == "key_leaf_charm", "leaf charm displayed")

	print("-- Save / load round trip")
	var snap_coins := GameState.economy.coins
	var snap_day := TimeManager.day
	check(SaveManager.save_game("test"), "save succeeded")
	GameState.economy.add(999, "test_dirty")
	check(SaveManager.prepare_load(), "save file valid")
	world.queue_free()
	await _frames(3)
	GameState.new_game()
	check(GameState.economy.coins == 0, "state cleared before load")
	SaveManager.prepare_load()
	world = load("res://scenes/world/tree_village_world.tscn").instantiate()
	add_child(world)
	await _frames(30)
	check(GameState.economy.coins == snap_coins, "coins restored (%d)" % GameState.economy.coins)
	check(TimeManager.day == snap_day, "day restored")
	check(GameState.quests.is_done("q_village_basket"), "quest completion restored")
	check(GameState.world.has_flag("park_restored"), "world flags restored")
	check(GameState.world.decor.get("anchor_rug", "") == "decor_rug", "decor placement restored")
	check(GameState.shop.level == 1, "stall level restored")
	# corrupt primary -> backup recovery
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	check(SaveManager.prepare_load(), "corrupt primary save falls back to backup")
	SaveManager.clear_pending()
	await _shot("10_treehouse_decor", GameData.region_world_pos("treehouse") + Vector3(3.0, 0, 0.6), -90)
	SaveManager.delete_save()
