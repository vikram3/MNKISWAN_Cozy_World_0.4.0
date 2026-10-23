class_name PauseMenu
extends ModalPanel
## Pause (GDD §12): resume, save, settings, journal/map, return to title. Honest save status.

var _save_info: Label
var root_ui: Node


func _init() -> void:
	super._init()
	panel_id = "pause"
	title_text = "Paused"


func panel_size() -> Vector2:
	return Vector2(640, 820)


func build_content() -> void:
	_save_info = UITheme.label("", 20, UITheme.MUTED)
	_save_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_save_info)
	for entry in [["Resume", close], ["Save game", _save], ["Our days together", func(): _switch("together")], ["Journal", func(): _switch("journal")], ["Map", func(): _switch("map")], ["Settings", func(): _switch("settings")], ["Save & return to title", _to_title], ["Quit to desktop", _quit]]:
		var b := UITheme.button(String(entry[0]), entry[1], 560)
		b.custom_minimum_size.y = 64
		content.add_child(b)


func refresh() -> void:
	if SaveManager.last_save_unix > 0:
		var ago := int(Time.get_unix_time_from_system()) - SaveManager.last_save_unix
		_save_info.text = "Last saved %d min ago. Resting in the treehouse bed also saves." % int(ago / 60.0)
	else:
		_save_info.text = "Not saved yet this session. Resting in the treehouse bed also saves."
	if content.get_child_count() > 1:
		(content.get_child(1) as Button).call_deferred("grab_focus")


func _save() -> void:
	var ok := SaveManager.save_game("manual")
	_save_info.text = "Saved!" if ok else "Save failed — please try again."


func _switch(which: String) -> void:
	close()
	if root_ui:
		root_ui.call("open_" + which)


func _to_title() -> void:
	SaveManager.save_game("title")
	close()
	SceneRouter.go_title()


func _quit() -> void:
	SaveManager.save_game("quit")
	get_tree().quit()
