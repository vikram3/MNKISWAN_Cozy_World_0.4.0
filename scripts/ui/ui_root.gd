extends CanvasLayer
## UIHost (GDD §15): owns HUD, dialogue and modal screens. UI issues commands; systems remain
## authoritative. Handles the menu hotkeys (Tab/I, J, M, Esc) without fighting gameplay input.

var together: TogetherPanel
var hud: HUD
var inventory: InventoryPanel
var shop: ShopPanel
var storage: StoragePanel
var journal: JournalPanel
var map: MapPanel
var settings: SettingsPanel
var pause: PauseMenu
var dialogue: DialogueBox
var _fade: ColorRect
var _sleeping := false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = HUD.new(); add_child(hud)
	together = TogetherPanel.new(); add_child(together)
	inventory = InventoryPanel.new(); add_child(inventory)
	shop = ShopPanel.new(); add_child(shop)
	storage = StoragePanel.new(); add_child(storage)
	journal = JournalPanel.new(); add_child(journal)
	map = MapPanel.new(); add_child(map)
	settings = SettingsPanel.new(); add_child(settings)
	pause = PauseMenu.new(); pause.root_ui = self; add_child(pause)
	dialogue = DialogueBox.new(); add_child(dialogue)
	_fade = ColorRect.new()
	_fade.color = Color(0.09, 0.12, 0.2, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _panels() -> Array:
	return [together, inventory, shop, storage, journal, map, settings, pause]


func _top_panel() -> ModalPanel:
	var top := GameState.top_ui()
	for p in _panels():
		if (p as ModalPanel).panel_id == top and (p as ModalPanel).visible:
			return p
	return null


func _input(event: InputEvent) -> void:
	if _sleeping or not (event is InputEventKey or event is InputEventMouseButton):
		return
	if dialogue.is_active():
		return
	var top := _top_panel()
	if event.is_action_pressed("pause") or (event.is_action_pressed("cancel") and top != null):
		var p := GameState.player as MnkiController
		if top:
			if top == settings and settings._listening_action != "":
				return
			top.close()
			get_viewport().set_input_as_handled()
		elif p and p.state == "fishing":
			return  # let the player cancel fishing first
		elif event.is_action_pressed("pause"):
			pause.open()
			get_viewport().set_input_as_handled()
		return
	if top != null and top != inventory and top != journal and top != map and top != together:
		return
	if event.is_action_pressed("together"):
		_toggle(together)
	elif event.is_action_pressed("inventory"):
		_toggle(inventory)
	elif event.is_action_pressed("journal"):
		_toggle(journal)
	elif event.is_action_pressed("map"):
		_toggle(map)


func _toggle(p: ModalPanel) -> void:
	var top := _top_panel()
	if top == p:
		p.close()
	else:
		if top:
			top.close()
		p.open()
	get_viewport().set_input_as_handled()


# --- Public API used by world interactables ----------------------------------------------------

func open_shop(mode: String) -> void:
	if mode in ["grocer", "decor"] and TimeManager.hour() < 7:
		GameState.notify("The vendors are resting. Counters open at 7 AM; the lantern market starts at 6 PM.", "info")
		return
	shop.open_mode(mode)


func open_storage() -> void:
	storage.open()


func open_journal() -> void:
	journal.open()


func open_map() -> void:
	map.open()


func open_inventory() -> void:
	inventory.open()


func open_together() -> void:
	together.open()


func open_settings() -> void:
	settings.open()


## Rest until morning: fade, advance the clock (crops grow, eggs appear), autosave, wake.
func sleep_sequence() -> void:
	if _sleeping:
		return
	_sleeping = true
	GameState.push_ui("sleep")
	AudioManager.play_sfx("sleep")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 1.0)
	await tw.finished
	TimeManager.sleep_to_morning()
	var life := get_parent().get_node_or_null("DailyLife")
	if life: life.sync_clock(true)
	var p := GameState.player as MnkiController
	if p:
		p.model.set_expression("happy", 2.0)
	await get_tree().create_timer(0.8).timeout
	SaveManager.save_game("sleep")
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 1.2)
	await tw2.finished
	GameState.pop_ui("sleep")
	_sleeping = false
	GameState.notify("Good morning! Day %d. Watered crops have grown." % TimeManager.day, "info")
