extends Node
## Settings autoload: player preferences, input map (remappable) and window/audio application.
## Stored separately from game progress in user://settings.cfg so resetting one never wipes the other.

signal settings_changed

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"master_volume": 0.9,
	"music_volume": 0.6,
	"ambience_volume": 0.7,
	"sfx_volume": 0.8,
	"mouse_sensitivity": 0.25,
	"invert_y": false,
	"run_toggle": false,
	"fishing_easy": false,
	"idle_conversations": true,
	"day_minutes": 36,
	"quiet_hud": false,
	"reduced_motion": false,
	"camera_shake": true,
	"window_mode": "windowed",
	"text_scale": 1.0,
}

## action id -> [label, default physical keycodes / mouse buttons]
## Mouse buttons are stored as negative numbers (-1 left, -2 right).
const ACTIONS := {
	"move_forward": ["Move forward", [KEY_W, KEY_UP]],
	"move_back": ["Move back", [KEY_S, KEY_DOWN]],
	"move_left": ["Move left", [KEY_A, KEY_LEFT]],
	"move_right": ["Move right", [KEY_D, KEY_RIGHT]],
	"interact": ["Interact / confirm", [KEY_E]],
	"jump": ["Jump", [KEY_SPACE]],
	"switch_character": ["Switch Mnki / Swan", [KEY_C]],
	"fly": ["Swan: take off / land", [KEY_F]],
	"descend": ["Swan: descend", [KEY_CTRL]],
	"run": ["Run", [KEY_SHIFT]],
	"cycle_seed": ["Change seed", [KEY_R]],
	"inventory": ["Inventory", [KEY_TAB, KEY_I]],
	"together": ["Together / village day", [KEY_H]],
	"journal": ["Journal", [KEY_J]],
	"map": ["Map", [KEY_M]],
	"pause": ["Pause", [KEY_ESCAPE]],
	"cancel": ["Cancel / back", [KEY_ESCAPE, -2]],
	"zoom_in": ["Camera closer", [KEY_EQUAL]],
	"zoom_out": ["Camera farther", [KEY_MINUS]],
}

var data: Dictionary = {}
var bindings: Dictionary = {}  # action -> Array[int]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	data = DEFAULTS.duplicate(true)
	for a in ACTIONS:
		bindings[a] = (ACTIONS[a][1] as Array).duplicate()
	load_settings()
	_apply_input_map()
	apply()


func get_value(key: String):
	return data.get(key, DEFAULTS.get(key))


func set_value(key: String, value) -> void:
	data[key] = value
	apply()
	save_settings()
	settings_changed.emit()


func reset_defaults() -> void:
	data = DEFAULTS.duplicate(true)
	for a in ACTIONS:
		bindings[a] = (ACTIONS[a][1] as Array).duplicate()
	_apply_input_map()
	apply()
	save_settings()
	settings_changed.emit()


func rebind(action: String, code: int) -> void:
	# Replace the primary binding, keep secondary defaults.
	var list: Array = bindings.get(action, []).duplicate()
	if list.is_empty():
		list.append(code)
	else:
		list[0] = code
	bindings[action] = list
	_apply_input_map()
	save_settings()
	settings_changed.emit()


func binding_label(action: String) -> String:
	var parts: Array = []
	for code in bindings.get(action, []):
		parts.append(code_label(int(code)))
	return " / ".join(parts)


static func code_label(code: int) -> String:
	if code == -1:
		return "Left Mouse"
	if code == -2:
		return "Right Mouse"
	return OS.get_keycode_string(code)


func _apply_input_map() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		InputMap.action_erase_events(action)
		for code in bindings[action]:
			var c := int(code)
			if c < 0:
				var mb := InputEventMouseButton.new()
				mb.button_index = MOUSE_BUTTON_LEFT if c == -1 else MOUSE_BUTTON_RIGHT
				InputMap.action_add_event(action, mb)
			else:
				var ev := InputEventKey.new()
				ev.physical_keycode = c
				InputMap.action_add_event(action, ev)


func apply() -> void:
	_apply_audio()
	if DisplayServer.get_name() != "headless":
		match String(data.get("window_mode", "windowed")):
			"fullscreen":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			"borderless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_:
				if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_audio() -> void:
	_set_bus("Master", float(data.master_volume))
	_set_bus("Music", float(data.music_volume))
	_set_bus("Ambience", float(data.ambience_volume))
	_set_bus("SFX", float(data.sfx_volume))


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in data:
		cfg.set_value("settings", k, data[k])
	for a in bindings:
		cfg.set_value("bindings", a, bindings[a])
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k in DEFAULTS:
		if cfg.has_section_key("settings", k):
			data[k] = cfg.get_value("settings", k)
	for a in ACTIONS:
		if cfg.has_section_key("bindings", a):
			var v = cfg.get_value("bindings", a)
			if v is Array and not v.is_empty():
				bindings[a] = v
