class_name QuestSystem
extends Node
## Data-driven quests (data/quests/quests.json). Objectives run in order, one visible next step at a time.
## Completion is decided by authoritative game state/events, never by dialogue text (GDD §10, §16).

signal quest_started(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal tracked_changed

const QUEST_FILE := "res://data/quests/quests.json"

var defs: Dictionary = {}        # id -> def
var order: Array = []            # ids in file order
var states: Dictionary = {}      # id -> {state, step, progress, targets}
var _completing: Dictionary = {} # re-entrancy guard against duplicate rewards


func _ready() -> void:
	_load_defs()


func _load_defs() -> void:
	var f := FileAccess.open(QUEST_FILE, FileAccess.READ)
	if f == null:
		push_error("Quest file missing: " + QUEST_FILE)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		push_error("Quest file is not valid JSON")
		return
	for q in parsed.get("quests", []):
		defs[String(q.id)] = q
		order.append(String(q.id))


func connect_sources() -> void:
	GameState.inventory.inventory_changed.connect(func(_id, _d): _recheck_all())
	GameState.world.region_discovered.connect(func(_r): _recheck_all())
	GameState.world.flag_set.connect(func(_f): _recheck_all())
	GameState.shop.stall_upgraded.connect(func(_l): _recheck_all())
	GameState.shop.shop_transaction_completed.connect(func(total, _items): on_event("sell", {"total": total}))


func reset() -> void:
	states.clear()
	_completing.clear()


# --- Queries ------------------------------------------------------------------------------------

func is_done(id: String) -> bool:
	return states.has(id) and states[id].state == "done"


func is_active(id: String) -> bool:
	return states.has(id) and states[id].state == "active"


func prereqs_met(id: String) -> bool:
	for p in defs[id].get("prereq", []):
		if not is_done(String(p)):
			return false
	return true


func active_ids() -> Array:
	var out: Array = []
	for id in order:
		if is_active(id):
			out.append(id)
	return out


func done_ids() -> Array:
	var out: Array = []
	for id in order:
		if is_done(id):
			out.append(id)
	return out


func available_from(npc_id: String) -> String:
	for id in order:
		var d: Dictionary = defs[id]
		if states.has(id) or d.get("auto_start", false):
			continue
		if String(d.get("giver", "")) == npc_id and prereqs_met(id):
			return id
	return ""


func objective(id: String) -> Dictionary:
	if not is_active(id):
		return {}
	var objs: Array = defs[id].objectives
	var step := int(states[id].step)
	if step < 0 or step >= objs.size():
		return {}
	return objs[step]


func objective_text(id: String) -> String:
	var o := objective(id)
	if o.is_empty():
		return ""
	var t := String(o.get("text", ""))
	var s: Dictionary = states[id]
	match String(o.type):
		"collect":
			t += " (%d/%d)" % [min(GameState.inventory.count(String(o.item)), int(o.qty)), int(o.qty)]
		"care", "catch", "harvest":
			t += " (%d/%d)" % [int(s.progress), int(o.qty)]
		"sell":
			t += " (%d/%d coins)" % [min(int(s.progress), int(o.value)), int(o.value)]
		"interact":
			var targets: Array = o.targets
			if targets.size() > 1:
				t += " (%d/%d)" % [(s.targets as Array).size(), targets.size()]
		"deliver":
			var parts: Array = []
			for item in o["items"]:
				var need := int(o["items"][item])
				var have: int = min(GameState.inventory.count(String(item)), need)
				var nm := "fish" if String(item) == "cat:fish" else ItemDB.display_name(String(item))
				parts.append("%s %d/%d" % [nm, have, need])
			t += "  [" + ", ".join(parts) + "]"
	return t


func tracked_quest() -> String:
	var act := active_ids()
	for id in act:
		if defs[id].get("main", false):
			return id
	return act[0] if not act.is_empty() else ""


## Which NPC/target is the current objective about (for map markers & Swan hints).
func objective_target(id: String) -> String:
	var o := objective(id)
	if o.is_empty():
		return ""
	match String(o.type):
		"talk", "deliver":
			return String(o.npc)
		"discover":
			return "region:" + String(o.region)
		"interact":
			return String(o.targets[0])
	return ""


# --- Mutations ----------------------------------------------------------------------------------

func start(id: String, silent: bool = false) -> bool:
	if not defs.has(id) or states.has(id) or not prereqs_met(id):
		return false
	states[id] = {"state": "active", "step": 0, "progress": 0, "targets": []}
	var d: Dictionary = defs[id]
	var acc: Dictionary = d.get("on_accept", {})
	for item in acc.get("items", {}):
		_give_item(String(item), int(acc["items"][item]))
	quest_started.emit(id)
	if not silent:
		GameState.notify("New request: " + String(d.title), "quest")
		AudioManager.play_sfx("quest_start")
		if d.get("auto_start", false) and d.has("offer"):
			GameState.request_dialogue(d.offer)
	tracked_changed.emit()
	_check_immediate(id)
	return true


func start_auto_quests() -> void:
	for id in order:
		if not states.has(id) and defs[id].get("auto_start", false) and prereqs_met(id):
			start(id)


func on_event(event_type: String, data: Dictionary = {}) -> void:
	for id in active_ids():
		var o := objective(id)
		if o.is_empty():
			continue
		var s: Dictionary = states[id]
		match event_type:
			"care":
				if String(o.type) == "care":
					var act := String(o.get("action", "any"))
					if act == "any" or act == String(data.get("action", "")):
						s.progress = int(s.progress) + 1
						_progress_or_advance(id, int(o.qty))
			"catch":
				if String(o.type) == "catch":
					s.progress = int(s.progress) + 1
					_progress_or_advance(id, int(o.qty))
			"harvest":
				if String(o.type) == "harvest" and (String(o.get("crop", "any")) in ["any", String(data.get("crop", ""))]):
					s.progress = int(s.progress) + 1
					_progress_or_advance(id, int(o.qty))
			"sell":
				if String(o.type) == "sell":
					s.progress = int(s.progress) + int(data.get("total", 0))
					_progress_or_advance(id, int(o.value))
			"interact":
				if String(o.type) == "interact":
					var tid := String(data.get("target", ""))
					var targets: Array = o.targets
					if targets.has(tid) and not (s.targets as Array).has(tid):
						(s.targets as Array).append(tid)
						if (s.targets as Array).size() >= targets.size():
							_advance(id)
						else:
							quest_objective_updated.emit(id, int(s.step))
							tracked_changed.emit()


func _progress_or_advance(id: String, need: int) -> void:
	if int(states[id].progress) >= need:
		_advance(id)
	else:
		quest_objective_updated.emit(id, int(states[id].step))
		tracked_changed.emit()


## Talking to an NPC: advances talk/deliver objectives, or offers a quest. Returns
## {"lines": Array, "offer": quest_id}. Caller shows the dialogue.
func handle_talk(npc_id: String) -> Dictionary:
	for id in active_ids():
		var o := objective(id)
		if o.is_empty():
			continue
		var step_key := str(int(states[id].step))
		if String(o.type) == "talk" and String(o.npc) == npc_id:
			var lines: Array = defs[id].get("talk_lines", {}).get(step_key, [])
			if lines.is_empty():
				lines = ["%s: Good to see you both." % NpcDB.display_name(npc_id)]
			lines = lines.duplicate()
			_advance(id, lines)
			return {"lines": lines, "offer": ""}
		if String(o.type) == "deliver" and String(o.npc) == npc_id:
			var res := try_deliver(npc_id)
			return {"lines": res.lines, "offer": ""}
	var offer := available_from(npc_id)
	if offer != "":
		return {"lines": defs[offer].get("offer", ["%s: Could you help me with something?" % NpcDB.display_name(npc_id)]), "offer": offer}
	return {"lines": [], "offer": ""}


## Delivery to an NPC or world target (stall basket, bridge site). Validates then consumes.
func try_deliver(target_id: String) -> Dictionary:
	for id in active_ids():
		var o := objective(id)
		if o.is_empty() or String(o.type) != "deliver" or String(o.npc) != target_id:
			continue
		var req: Dictionary = o["items"]
		if not GameState.inventory.has_all(req):
			var missing: Array = []
			for item in req:
				var need := int(req[item]) - GameState.inventory.count(String(item))
				if need > 0:
					var nm := "fish" if String(item) == "cat:fish" else ItemDB.display_name(String(item))
					missing.append("%d %s" % [need, nm])
			var speaker := NpcDB.display_name(target_id) if NpcDB.NPCS.has(target_id) else "Swan"
			return {"ok": false, "lines": ["%s: Whenever you have time — still needed: %s." % [speaker, ", ".join(missing)]], "reason": "Still needed: " + ", ".join(missing)}
		GameState.inventory.remove_all(req)
		var lines: Array = defs[id].get("talk_lines", {}).get(str(int(states[id].step)), []).duplicate()
		_advance(id, lines)
		return {"ok": true, "lines": lines, "reason": ""}
	return {"ok": false, "lines": [], "reason": "Nothing to deliver here right now."}


func has_deliver_for(target_id: String) -> bool:
	for id in active_ids():
		var o := objective(id)
		if not o.is_empty() and String(o.type) == "deliver" and String(o.npc) == target_id:
			return true
	return false


func _advance(id: String, lines_out = null) -> void:
	var s: Dictionary = states[id]
	s.step = int(s.step) + 1
	s.progress = 0
	s.targets = []
	if int(s.step) >= (defs[id].objectives as Array).size():
		_complete(id, lines_out)
		return
	quest_objective_updated.emit(id, int(s.step))
	tracked_changed.emit()
	AudioManager.play_sfx("quest_step")
	_check_immediate(id)


func _check_immediate(id: String) -> void:
	if not is_active(id):
		return
	var o := objective(id)
	if o.is_empty():
		return
	match String(o.type):
		"collect":
			if GameState.inventory.count(String(o.item)) >= int(o.qty):
				_advance(id)
		"discover":
			if GameState.world.is_discovered(String(o.region)):
				_advance(id)
		"stall_level":
			if GameState.shop.level >= int(o.level):
				_advance(id)
		"flag":
			if GameState.world.has_flag(String(o.flag)):
				_advance(id)


func _recheck_all() -> void:
	for id in active_ids():
		_check_immediate(id)
	tracked_changed.emit()


func _complete(id: String, lines_out) -> void:
	if _completing.has(id) or is_done(id):
		return
	_completing[id] = true
	var d: Dictionary = defs[id]
	states[id].state = "done"
	var r: Dictionary = d.get("rewards", {})
	if int(r.get("coins", 0)) > 0:
		GameState.economy.add(int(r.coins), "quest_" + id)
	for item in r.get("items", {}):
		_give_item(String(item), int(r["items"][item]))
	for f in r.get("flags", []):
		GameState.world.set_flag(String(f))
	_completing.erase(id)
	quest_completed.emit(id)
	tracked_changed.emit()
	GameState.notify("Request complete: " + String(d.title), "quest")
	AudioManager.play_sfx("quest_complete")
	var complete_lines: Array = d.get("complete", [])
	if lines_out is Array:
		for l in complete_lines:
			lines_out.append(l)
	elif not complete_lines.is_empty():
		GameState.request_dialogue(complete_lines)
	start_auto_quests()
	SaveManager.autosave("quest_complete")


func _give_item(item: String, qty: int) -> void:
	if not GameState.inventory.add(item, qty):
		# Bag full: rewards are never lost — they go to treehouse storage.
		GameState.inventory.storage[item] = GameState.inventory.storage_count(item) + qty
		GameState.inventory.storage_changed.emit(item, qty)
		GameState.notify("%s sent to treehouse storage (bag full)." % ItemDB.display_name(item), "warn")
	else:
		GameState.notify("+%d %s" % [qty, ItemDB.display_name(item)], "item")


func to_save() -> Dictionary:
	return {"states": states.duplicate(true)}


func from_save(d: Dictionary) -> void:
	reset()
	var st: Dictionary = d.get("states", {})
	for id in st:
		if defs.has(String(id)) and st[id] is Dictionary:
			var s: Dictionary = st[id]
			states[String(id)] = {"state": String(s.get("state", "active")), "step": int(s.get("step", 0)),
				"progress": int(s.get("progress", 0)), "targets": Array(s.get("targets", []))}
		else:
			push_warning("Save: skipped unknown quest %s" % id)
	tracked_changed.emit()
