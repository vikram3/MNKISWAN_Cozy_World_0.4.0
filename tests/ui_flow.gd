extends Node
## Smoke-tests the title → new game → menus → save → title → continue flow and opens every
## UI panel once. Run headless: godot --headless --path . res://tests/ui_flow.tscn

func _ready() -> void:
	SaveManager.delete_save()
	await get_tree().process_frame
	get_tree().root.add_child.call_deferred(_Driver.new())


class _Driver extends Node:
	func _ready() -> void:
		get_tree().change_scene_to_file("res://scenes/menus/title_menu.tscn")
		await get_tree().create_timer(0.5).timeout
		SceneRouter.go_world(false)
		await get_tree().create_timer(2.0).timeout
		var ui = GameState.ui
		for p in [ui.inventory, ui.journal, ui.map, ui.storage, ui.settings, ui.pause]:
			p.open()
			await get_tree().process_frame
			p.close()
		for m in ["stall", "grocer", "decor"]:
			ui.open_shop(m)
			await get_tree().process_frame
			ui.shop.close()
		GameState.economy.add(50, "t")
		GameState.shop.buy("seed_tomato", 2)
		print("bought seeds: ", GameState.inventory.count("seed_tomato"))
		assert(GameState.inventory.count("seed_tomato") == 2)
		ui.sleep_sequence()
		await get_tree().create_timer(4.0).timeout
		print("day after sleep: ", TimeManager.day, " saved: ", SaveManager.has_save())
		assert(TimeManager.day == 2 and SaveManager.has_save())
		SceneRouter.go_title()
		await get_tree().create_timer(1.5).timeout
		print("scene: ", get_tree().current_scene.name)
		assert(get_tree().current_scene.name == "TitleMenu")
		SceneRouter.go_world(true)
		await get_tree().create_timer(2.5).timeout
		print("continued day: ", TimeManager.day, " coins: ", GameState.economy.coins)
		assert(TimeManager.day == 2 and GameState.economy.coins == 42)
		print("UI FLOW OK")
		SaveManager.delete_save()
		get_tree().quit()
