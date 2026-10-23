class_name WorldStateSystem
extends Node
## Owns persistent world flags, unlocks, discoveries and per-object state keyed by stable IDs
## (gather nodes, crop plots, animals, decor anchors). Scene objects read/write through here.

signal flag_set(flag: String)
signal region_discovered(region_id: String)
signal object_state_changed(object_id: String)

var flags: Dictionary = {}          # flag -> true
var discovered_regions: Dictionary = {}
var objects: Dictionary = {}        # object_id -> Dictionary
var decor: Dictionary = {}          # anchor_id -> item_id (placed)


func reset() -> void:
	flags.clear()
	discovered_regions.clear()
	objects.clear()
	decor.clear()


func has_flag(f: String) -> bool:
	return flags.has(f)


func set_flag(f: String) -> void:
	if flags.has(f):
		return
	flags[f] = true
	flag_set.emit(f)


func discover_region(id: String) -> bool:
	if discovered_regions.has(id):
		return false
	discovered_regions[id] = TimeManager.day
	region_discovered.emit(id)
	return true


func is_discovered(id: String) -> bool:
	return discovered_regions.has(id)


func get_state(id: String, default_value: Dictionary = {}) -> Dictionary:
	if not objects.has(id):
		objects[id] = default_value.duplicate(true)
	return objects[id]


func set_state(id: String, state: Dictionary) -> void:
	objects[id] = state
	object_state_changed.emit(id)


func place_decor(anchor_id: String, item_id: String) -> void:
	decor[anchor_id] = item_id
	object_state_changed.emit(anchor_id)


func clear_decor(anchor_id: String) -> void:
	decor.erase(anchor_id)
	object_state_changed.emit(anchor_id)


func is_item_placed(item_id: String) -> bool:
	return decor.values().has(item_id)


func to_save() -> Dictionary:
	return {"flags": flags.keys(), "regions": discovered_regions.duplicate(), "objects": objects.duplicate(true), "decor": decor.duplicate()}


func from_save(d: Dictionary) -> void:
	reset()
	for f in d.get("flags", []):
		flags[String(f)] = true
	var regions: Dictionary = d.get("regions", {})
	for r in regions:
		if GameData.REGIONS.has(String(r)):
			discovered_regions[String(r)] = int(regions[r])
	var objs: Dictionary = d.get("objects", {})
	for k in objs:
		if objs[k] is Dictionary:
			objects[String(k)] = objs[k]
	var dec: Dictionary = d.get("decor", {})
	for a in dec:
		if GameData.DECOR_ANCHORS.has(String(a)) and ItemDB.has(String(dec[a])):
			decor[String(a)] = String(dec[a])
