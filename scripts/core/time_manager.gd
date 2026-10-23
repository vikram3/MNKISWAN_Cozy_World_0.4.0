extends Node
## Central clock in in-game minutes (GDD §9.9). 36 real minutes per day by default (adjustable).
## Time pauses while menus/dialogue are open. Crops and animals react to day_started, not polling.

signal minute_changed(total_minutes: float)
signal hour_changed(hour: int)
signal day_started(day: int)

const DAY_START_MINUTE := 360.0      # 6:00

var day: int = 1
var minute: float = DAY_START_MINUTE
var running := false
var _last_hour := -1


func reset() -> void:
	day = 1
	minute = DAY_START_MINUTE
	_last_hour = -1


func _process(delta: float) -> void:
	if not running or GameState.is_ui_blocking():
		return
	minute += delta * 1440.0 / (clampf(float(Settings.get_value("day_minutes")), 12, 60) * 60.0)
	if minute >= 1440.0:
		minute -= 1440.0
		day += 1
		day_started.emit(day)
	var h := int(minute / 60.0)
	if h != _last_hour:
		_last_hour = h
		hour_changed.emit(h)
	minute_changed.emit(total_minutes())


func total_minutes() -> float:
	return float(day) * 1440.0 + minute


func hour() -> int:
	return int(minute / 60.0)


func is_night() -> bool:
	return minute < 330.0 or minute > 1230.0


## Rest to the next morning. Never penalises the player (GDD §9.9).
func sleep_to_morning() -> void:
	if minute < DAY_START_MINUTE:
		minute = DAY_START_MINUTE   # already past midnight: wake the same calendar day
	else:
		day += 1
		minute = DAY_START_MINUTE
		day_started.emit(day)
	_last_hour = hour()
	hour_changed.emit(_last_hour)
	minute_changed.emit(total_minutes())


func clock_string() -> String:
	var h := int(minute / 60.0)
	var m := int(minute) % 60
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]


func period_name() -> String:
	var h := hour()
	if h < 5: return "Night"
	if h < 9: return "Morning"
	if h < 12: return "Late morning"
	if h < 15: return "Midday"
	if h < 18: return "Afternoon"
	if h < 21: return "Evening"
	return "Night"


func to_save() -> Dictionary:
	return {"day": day, "minute": minute}


func from_save(d: Dictionary) -> void:
	day = max(1, int(d.get("day", 1)))
	minute = clampf(float(d.get("minute", DAY_START_MINUTE)), 0.0, 1439.0)
	_last_hour = -1
