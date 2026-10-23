class_name StoragePanel
extends ModalPanel
## Treehouse storage (GDD §9.8): distinct from carried inventory, shows counts, never discards.

var _bag: VBoxContainer
var _store: VBoxContainer


func _init() -> void:
	super._init()
	panel_id = "storage"
	title_text = "Treehouse Storage"


func build_content() -> void:
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 24)
	content.add_child(h)
	var l := VBoxContainer.new()
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	l.add_child(UITheme.label("In your bag", 28, UITheme.CORAL, true))
	_bag = scroll_box(l, 600)
	var r := VBoxContainer.new()
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(r)
	r.add_child(UITheme.label("In storage", 28, UITheme.CORAL, true))
	_store = scroll_box(r, 600)


func refresh() -> void:
	UITheme.clear(_bag)
	UITheme.clear(_store)
	var inv := GameState.inventory
	for id in inv.sorted_ids():
		_bag.add_child(_row(id, inv.count(id), "Store 1", "Store all", func(q): inv.deposit(id, q)))
	var sids: Array = inv.storage.keys()
	sids.sort()
	for id in sids:
		_store.add_child(_row(id, inv.storage_count(id), "Take 1", "Take all", func(q):
			if not inv.withdraw(id, q):
				GameState.notify("Your bag can't hold that many.", "warn")))
	if inv.items.is_empty():
		_bag.add_child(UITheme.label("Empty", 22, UITheme.MUTED))
	if inv.storage.is_empty():
		_store.add_child(UITheme.label("Empty", 22, UITheme.MUTED))


func _row(id: String, n: int, one: String, all: String, act: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UITheme.item_icon(id, 38))
	var nm := UITheme.label("%s x%d" % [ItemDB.display_name(id), n], 22)
	nm.custom_minimum_size.x = 300
	row.add_child(nm)
	row.add_child(UITheme.button(one, func():
		act.call(1)
		refresh(), 110))
	row.add_child(UITheme.button(all, func():
		act.call(n)
		refresh(), 120))
	return row
