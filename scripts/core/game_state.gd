extends Node
## GameState autoload: owns the gameplay services (inventory, economy, quests, world, shop),
## the journal, the modal-UI stack and cross-system events. One source of truth per system.

signal ui_blocking_changed(blocking: bool)
signal toast(text: String, kind: String)
signal dialogue_requested(lines: Array, choices: Array, callback: Callable)
signal journal_changed
signal companion_event(event_id: String, data: Dictionary)
signal seed_selection_changed(seed_id: String)
signal fishing_state_changed(state: String)
signal sale_feedback(total: int)

var inventory: InventorySystem
var economy: EconomySystem
var quests: QuestSystem
var world: WorldStateSystem
var shop: ShopSystem

var journal: Dictionary = {"fish": {}, "items": {}, "animals": {}, "notes": {}}
var stats: Dictionary = {"fish_caught": 0, "harvests": 0, "care_actions": 0}
var selected_seed: String = ""
var player: Node3D = null
var swan: Node3D = null
var in_world := false
var ui: Node = null
var _ui_stack: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory = InventorySystem.new(); inventory.name = "Inventory"; add_child(inventory)
	economy = EconomySystem.new(); economy.name = "Economy"; add_child(economy)
	world = WorldStateSystem.new(); world.name = "World"; add_child(world)
	shop = ShopSystem.new(); shop.name = "Shop"; add_child(shop)
	quests = QuestSystem.new(); quests.name = "Quests"; add_child(quests)
	quests.connect_sources()
	TimeManager.day_started.connect(_on_day_started)


func new_game() -> void:
	inventory.reset()
	economy.reset()
	world.reset()
	shop.reset()
	quests.reset()
	journal = {"fish": {}, "items": {}, "animals": {}, "notes": {}}
	stats = {"fish_caught": 0, "harvests": 0, "care_actions": 0}
	selected_seed = ""
	TimeManager.reset()
	_ui_stack.clear()


## Called by the world once the scene is ready for a new game.
func begin_new_story() -> void:
	quests.start_auto_quests()


# --- Modal UI stack -----------------------------------------------------------------------------

func push_ui(id: String) -> void:
	if not _ui_stack.has(id):
		_ui_stack.append(id)
	_update_ui_mode()


func pop_ui(id: String) -> void:
	_ui_stack.erase(id)
	_update_ui_mode()


func is_ui_blocking() -> bool:
	return not _ui_stack.is_empty()


func top_ui() -> String:
	return "" if _ui_stack.is_empty() else String(_ui_stack[-1])


func clear_ui() -> void:
	_ui_stack.clear()
	_update_ui_mode()


func _update_ui_mode() -> void:
	var blocking := is_ui_blocking()
	if in_world and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocking else Input.MOUSE_MODE_CAPTURED
	ui_blocking_changed.emit(blocking)


# --- Feedback helpers ---------------------------------------------------------------------------

func notify(text: String, kind: String = "info") -> void:
	toast.emit(text, kind)


func request_dialogue(lines: Array, choices: Array = [], callback: Callable = Callable()) -> void:
	if lines.is_empty():
		return
	dialogue_requested.emit(lines, choices, callback)


func companion(event_id: String, data: Dictionary = {}) -> void:
	companion_event.emit(event_id, data)


# --- Journal ------------------------------------------------------------------------------------

func record_item_discovery(id: String) -> void:
	var cat := ItemDB.category(id)
	var book := "fish" if cat == "fish" else "items"
	if not journal[book].has(id):
		journal[book][id] = {"day": TimeManager.day, "region": current_region_name()}
		journal_changed.emit()
		if cat == "fish":
			notify("Journal: new fish — " + ItemDB.display_name(id), "journal")


func record_note(id: String, title: String, text: String) -> void:
	if journal.notes.has(id):
		return
	journal.notes[id] = {"title": title, "text": text, "day": TimeManager.day}
	journal_changed.emit()
	notify("Journal note added: " + title, "journal")


func record_animal(species: String) -> void:
	if not journal.animals.has(species):
		journal.animals[species] = {"day": TimeManager.day}
		journal_changed.emit()
		notify("Journal: Animal Care — %s" % species.capitalize(), "journal")


func current_region_name() -> String:
	if player and player.has_method("get_region_id"):
		var r: String = player.get_region_id()
		if GameData.REGIONS.has(r):
			return String(GameData.REGIONS[r].name)
	return ""


# --- Seeds --------------------------------------------------------------------------------------

func get_selected_seed() -> String:
	var seeds := inventory.seed_ids()
	if seeds.is_empty():
		return ""
	if not seeds.has(selected_seed):
		selected_seed = String(seeds[0])
	return selected_seed


func cycle_seed() -> void:
	var seeds := inventory.seed_ids()
	if seeds.is_empty():
		notify("No seeds — Tamsin sells them at the market.", "warn")
		return
	var i := seeds.find(get_selected_seed())
	selected_seed = String(seeds[(i + 1) % seeds.size()])
	seed_selection_changed.emit(selected_seed)
	notify("Seed selected: " + ItemDB.display_name(selected_seed), "info")


# --- Day ----------------------------------------------------------------------------------------

func _on_day_started(_day: int) -> void:
	shop.ensure_orders()


# --- Save ---------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {
		"inventory": inventory.to_save(),
		"economy": economy.to_save(),
		"world": world.to_save(),
		"shop": shop.to_save(),
		"quests": quests.to_save(),
		"journal": journal.duplicate(true),
		"stats": stats.duplicate(),
		"selected_seed": selected_seed,
	}


func from_save(d: Dictionary) -> void:
	inventory.from_save(d.get("inventory", {}))
	economy.from_save(d.get("economy", {}))
	world.from_save(d.get("world", {}))
	shop.from_save(d.get("shop", {}))
	quests.from_save(d.get("quests", {}))
	var j: Dictionary = d.get("journal", {})
	journal = {"fish": j.get("fish", {}), "items": j.get("items", {}), "animals": j.get("animals", {}), "notes": j.get("notes", {})}
	var st: Dictionary = d.get("stats", {})
	for k in stats:
		stats[k] = int(st.get(k, 0))
	selected_seed = String(d.get("selected_seed", ""))
	journal_changed.emit()
