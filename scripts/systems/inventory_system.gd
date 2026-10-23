class_name InventorySystem
extends Node
## Single authority for carried items and treehouse storage (GDD §11, §16).
## All mutations are all-or-nothing and emit typed signals.

signal inventory_changed(item_id: String, delta: int)
signal storage_changed(item_id: String, delta: int)

const MAX_SLOTS := 30          # distinct stacks carried; generous early (GDD §11)
const STORAGE_SLOTS := 60

var items: Dictionary = {}     # item_id -> qty
var storage: Dictionary = {}


func reset() -> void:
	items.clear()
	storage.clear()


func count(id: String) -> int:
	if id.begins_with("cat:"):
		return count_category(id.substr(4))
	return int(items.get(id, 0))


func count_category(cat: String) -> int:
	var n := 0
	for id in items:
		if ItemDB.category(id) == cat:
			n += int(items[id])
	return n


func can_add(id: String, qty: int) -> bool:
	if qty <= 0:
		return true
	var have := count(id)
	if have == 0 and items.size() >= MAX_SLOTS:
		return false
	return have + qty <= ItemDB.stack_limit(id)


## Adds the full quantity or nothing. Returns true on success.
func add(id: String, qty: int = 1) -> bool:
	if qty <= 0 or not ItemDB.has(id):
		return false
	if not can_add(id, qty):
		return false
	items[id] = count(id) + qty
	inventory_changed.emit(id, qty)
	GameState.record_item_discovery(id)
	return true


func remove(id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return true
	if id.begins_with("cat:"):
		return _remove_category(id.substr(4), qty)
	if count(id) < qty:
		return false
	items[id] = count(id) - qty
	if int(items[id]) <= 0:
		items.erase(id)
	inventory_changed.emit(id, -qty)
	return true


func _remove_category(cat: String, qty: int) -> bool:
	if count_category(cat) < qty:
		return false
	var left := qty
	# Remove cheapest items of the category first so rare catches are kept.
	var ids: Array = []
	for id in items:
		if ItemDB.category(id) == cat:
			ids.append(id)
	ids.sort_custom(func(a, b): return ItemDB.sell_value(a) < ItemDB.sell_value(b))
	for id in ids:
		var take: int = min(left, count(id))
		remove(id, take)
		left -= take
		if left <= 0:
			break
	return true


func has_all(req: Dictionary) -> bool:
	for id in req:
		if count(String(id)) < int(req[id]):
			return false
	return true


## Validates every requirement first, then removes. Never partial.
func remove_all(req: Dictionary) -> bool:
	if not has_all(req):
		return false
	for id in req:
		remove(String(id), int(req[id]))
	return true


func sorted_ids() -> Array:
	var ids: Array = items.keys()
	ids.sort_custom(func(a, b):
		var ca := ItemDB.CATEGORIES.find(ItemDB.category(a))
		var cb := ItemDB.CATEGORIES.find(ItemDB.category(b))
		if ca != cb:
			return ca < cb
		return ItemDB.display_name(a) < ItemDB.display_name(b))
	return ids


func seed_ids() -> Array:
	var out: Array = []
	for id in sorted_ids():
		if ItemDB.is_seed(id):
			out.append(id)
	return out


# --- Storage ------------------------------------------------------------------------------------

func storage_count(id: String) -> int:
	return int(storage.get(id, 0))


func deposit(id: String, qty: int) -> bool:
	if qty <= 0 or count(id) < qty:
		return false
	if storage_count(id) == 0 and storage.size() >= STORAGE_SLOTS:
		return false
	if not remove(id, qty):
		return false
	storage[id] = storage_count(id) + qty
	storage_changed.emit(id, qty)
	return true


func withdraw(id: String, qty: int) -> bool:
	if qty <= 0 or storage_count(id) < qty:
		return false
	if not can_add(id, qty):
		return false
	storage[id] = storage_count(id) - qty
	if int(storage[id]) <= 0:
		storage.erase(id)
	storage_changed.emit(id, -qty)
	add(id, qty)
	return true


func to_save() -> Dictionary:
	return {"items": items.duplicate(), "storage": storage.duplicate()}


func from_save(d: Dictionary) -> void:
	reset()
	for id in d.get("items", {}):
		if ItemDB.has(String(id)) and int(d["items"][id]) > 0:
			items[String(id)] = int(d["items"][id])
		else:
			push_warning("Save: skipped unknown item id %s" % id)
	for id in d.get("storage", {}):
		if ItemDB.has(String(id)) and int(d["storage"][id]) > 0:
			storage[String(id)] = int(d["storage"][id])
