extends Node
## Versioned JSON saves under user:// (GDD §16). Writes to a temp file, verifies it parses,
## keeps a .bak of the previous good save, then replaces the primary file.

signal saved(ok: bool, reason: String)
signal loaded(ok: bool)

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://mnkiswan_save_1.json"
const TMP_PATH := "user://mnkiswan_save_1.tmp"
const BAK_PATH := "user://mnkiswan_save_1.bak"

var pending_load: Dictionary = {}
var last_save_unix: int = 0


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BAK_PATH)


func build_snapshot() -> Dictionary:
	var player_pos := Vector3.ZERO
	var safe_pos := Vector3.ZERO
	if GameState.player:
		player_pos = GameState.player.global_position
		if GameState.player.has_method("get_safe_position"):
			safe_pos = GameState.player.get_safe_position()
	return {
		"schema_version": SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_version": ProjectSettings.get_setting("application/config/version", "0"),
		"time": TimeManager.to_save(),
		"player": {"character": GameState.player.character_id if GameState.player else "mnki", "pos": [safe_pos.x, safe_pos.y, safe_pos.z] if safe_pos != Vector3.ZERO else [player_pos.x, player_pos.y, player_pos.z]},
		"game": GameState.to_save(),
	}


func save_game(reason: String = "manual") -> bool:
	if not GameState.in_world:
		return false
	var snap := build_snapshot()
	var text := JSON.stringify(snap, "\t")
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		saved.emit(false, "Could not write save file")
		return false
	f.store_string(text)
	f.close()
	# Verify the temp file before replacing anything.
	var check := _read_json(TMP_PATH)
	if check.is_empty() or int(check.get("schema_version", -1)) != SCHEMA_VERSION:
		saved.emit(false, "Save verification failed")
		return false
	var dir := DirAccess.open("user://")
	# A corrupt primary must never replace the last known good backup.
	if _valid(_read_json(SAVE_PATH)):
		if dir.copy(SAVE_PATH, BAK_PATH) != OK:
			saved.emit(false, "Could not protect previous save")
			return false
	var err := dir.rename(TMP_PATH, SAVE_PATH)
	if err != OK:
		saved.emit(false, "Could not finalise save")
		return false
	last_save_unix = int(Time.get_unix_time_from_system())
	saved.emit(true, reason)
	return true


func autosave(reason: String) -> void:
	# Deferred so the state mutation that triggered it is fully complete first.
	call_deferred("save_game", reason)


## Reads the save into pending_load. The world applies it once its scene is built.
func prepare_load() -> bool:
	var d := _read_json(SAVE_PATH)
	if not _valid(d):
		push_warning("Primary save invalid; trying backup")
		d = _read_json(BAK_PATH)
		if not _valid(d):
			loaded.emit(false)
			return false
	pending_load = _migrate(d)
	return true


func apply_pending_load() -> void:
	if pending_load.is_empty():
		return
	TimeManager.from_save(pending_load.get("time", {}))
	GameState.from_save(pending_load.get("game", {}))
	loaded.emit(true)


func pending_player_position() -> Variant:
	if pending_load.is_empty():
		return null
	var p: Array = pending_load.get("player", {}).get("pos", [])
	if p.size() == 3:
		return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return null


func clear_pending() -> void:
	pending_load = {}


func save_summary() -> String:
	var d := _read_json(SAVE_PATH)
	if not _valid(d):
		d = _read_json(BAK_PATH)
	if not _valid(d):
		return ""
	var day := int(d.get("time", {}).get("day", 1))
	var coins := int(d.get("game", {}).get("economy", {}).get("coins", 0))
	return "Day %d · %d coins" % [day, coins]


func _valid(d: Dictionary) -> bool:
	if int(d.get("schema_version", -1)) != SCHEMA_VERSION or not d.get("game") is Dictionary:
		return false
	if not d.get("player") is Dictionary or not d.get("time") is Dictionary:
		return false
	var p = d.player.get("pos")
	if not p is Array or p.size() != 3:
		return false
	for value in p:
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	for key in ["inventory", "economy", "world", "shop", "quests", "journal", "stats"]:
		if not d.game.get(key, {}) is Dictionary:
			return false
	return true


func _migrate(d: Dictionary) -> Dictionary:
	# Future schema migrations go here (v1 is current).
	return d


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parser := JSON.new()
	if parser.parse(f.get_as_text()) != OK:
		return {}
	return parser.data if parser.data is Dictionary else {}


func delete_save() -> void:
	var dir := DirAccess.open("user://")
	for p in [SAVE_PATH, BAK_PATH, TMP_PATH]:
		if FileAccess.file_exists(p):
			dir.remove(p.get_file())
