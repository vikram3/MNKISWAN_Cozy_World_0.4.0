class_name InventoryPanel
extends ModalPanel
## Inventory (GDD §11/§12): stacks by category with values and descriptions. Quest-needed items
## are marked. Nothing can be destroyed from here (no accidental loss).

var _list: VBoxContainer
var _detail: Label
var _summary: Label


func _init() -> void:
	super._init()
	panel_id = "inventory"
	title_text = "Bag"


func build_content() -> void:
	_summary = UITheme.label("", 22, UITheme.MUTED)
	content.add_child(_summary)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 20)
	content.add_child(h)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	h.add_child(left)
	_list = scroll_box(left, 600)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", UITheme.box(Color(1, 1, 1, 0.6), 16, UITheme.SAGE, 2, 16))
	h.add_child(right)
	_detail = UITheme.label("Select an item to read about it.", 24)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x = 420
	right.add_child(_detail)


func refresh() -> void:
	UITheme.clear(_list)
	var inv := GameState.inventory
	_summary.text = "%d / %d stacks · %d coins · Seeds selected for planting: %s" % [inv.items.size(), InventorySystem.MAX_SLOTS, GameState.economy.coins, ItemDB.display_name(GameState.get_selected_seed()) if GameState.get_selected_seed() != "" else "none"]
	var needed := _quest_needed()
	var last_cat := ""
	if inv.items.is_empty():
		_list.add_child(UITheme.label("Your bag is empty. Berries grow in the Sunshine Forest and the Berry Maze!", 24, UITheme.MUTED))
	for id in inv.sorted_ids():
		var cat := ItemDB.category(id)
		if cat != last_cat:
			last_cat = cat
			_list.add_child(UITheme.label(cat.capitalize(), 22, UITheme.CORAL, true))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(UITheme.item_icon(id))
		var nm := UITheme.label(ItemDB.display_name(id), 24)
		nm.custom_minimum_size.x = 300
		row.add_child(nm)
		row.add_child(UITheme.label("x%d" % inv.count(id), 24, UITheme.FOREST, true))
		var val := UITheme.label(("%d coins each" % ItemDB.sell_value(id)) if ItemDB.can_sell(id) else "not for sale", 20, UITheme.MUTED)
		val.custom_minimum_size.x = 190
		row.add_child(val)
		if needed.has(id):
			row.add_child(UITheme.label("needed for a request", 18, UITheme.CORAL))
		var b := UITheme.button("Info", func(): _show(id), 90)
		row.add_child(b)
		if ItemDB.is_seed(id):
			row.add_child(UITheme.button("Select", func():
				GameState.selected_seed = id
				GameState.seed_selection_changed.emit(id)
				refresh(), 110))
		_list.add_child(row)


func _show(id: String) -> void:
	var d := ItemDB.get_def(id)
	_detail.text = "%s\n\n%s\n\nCategory: %s\nSell value: %s\nCarrying: %d" % [ItemDB.display_name(id), String(d.get("desc", "")), ItemDB.category(id).capitalize(), ("%d coins" % ItemDB.sell_value(id)) if ItemDB.can_sell(id) else "—", GameState.inventory.count(id)]


static func _quest_needed() -> Dictionary:
	var out := {}
	for qid in GameState.quests.active_ids():
		var o := GameState.quests.objective(qid)
		if o.is_empty():
			continue
		if String(o.type) == "deliver":
			for item in o["items"]:
				if String(item) == "cat:fish":
					for f in GameState.inventory.items:
						if ItemDB.category(f) == "fish":
							out[f] = int(o["items"][item])
				else:
					out[String(item)] = int(o["items"][item])
		elif String(o.type) == "collect":
			out[String(o.item)] = int(o.qty)
	return out
