class_name TogetherPanel
extends ModalPanel
var _summary: Label
var _villagers: VBoxContainer
var _memories: Label
var _moment_buttons: Dictionary = {}

func _init() -> void:
	super._init()
	panel_id = "together"
	title_text = "Our days together"

func panel_size() -> Vector2:
	return Vector2(1250, 860)

func build_content() -> void:
	_summary = UITheme.label("", 23, UITheme.FOREST, true)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_summary)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tabs)
	var moments := VBoxContainer.new()
	moments.name = "Together"
	moments.add_theme_constant_override("separation", 16)
	tabs.add_child(moments)
	var intro := UITheme.label("A moment for the two of you. No score, no obligation.\nMovement or Esc ends it gently; your partner never minds.", 25)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moments.add_child(intro)
	for id in ["appreciate", "breathe", "dance"]:
		var key: String = id
		var button := UITheme.button(String(TogetherMoments.MOMENTS[key][0]), func():
			close()
			var ritual := _ritual()
			if ritual: ritual.begin(key), 650)
		button.custom_minimum_size.y = 70
		moments.add_child(button)
		_moment_buttons[key] = button
	var hint := UITheme.label("Find shared rituals by the home, park, flower garden, pond, rice fields and night market.\nTea · picnics · garden dates · watching the sky · helping together", 23, UITheme.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moments.add_child(hint)
	_memories = UITheme.label("", 22, UITheme.CORAL)
	moments.add_child(_memories)
	var day := VBoxContainer.new()
	day.name = "Village day"
	tabs.add_child(day)
	day.add_child(UITheme.label("Children sleep at 8 PM · most neighbours at 9 PM · market closes at midnight", 21, UITheme.MUTED))
	_villagers = scroll_box(day, 490)

func _ritual() -> TogetherMoments:
	return get_parent().get_parent().get_node_or_null("TogetherMoments") as TogetherMoments

func refresh() -> void:
	_summary.text = "Day %d · %s\n%s" % [TimeManager.day, TimeManager.clock_string(), DailyLifeData.public_summary(TimeManager.hour())]
	for child in _villagers.get_children():
		_villagers.remove_child(child)
		child.queue_free()
	var life := get_parent().get_parent().get_node_or_null("DailyLife") as DailyLife
	if life and life.initialized:
		for id in life.residents:
			var row := HBoxContainer.new()
			var name_label := UITheme.label(NpcDB.display_name(id), 23, UITheme.FOREST, true)
			name_label.custom_minimum_size.x = 235
			row.add_child(name_label)
			var location := "On the village paths"
			var pos: Vector3 = life.residents[id].npc.global_position
			for region in GameData.REGIONS:
				var data: Dictionary = GameData.REGIONS[region]
				if absf(pos.x - data.pos.x) < data.size.x * 0.5 and absf(pos.z - data.pos.y) < data.size.y * 0.5:
					location = data.name
			var status := UITheme.label(life.status_for(id) + "\n" + location, 22, UITheme.MUTED)
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(status)
			_villagers.add_child(row)
	var count := 0
	for id in TogetherMoments.MOMENTS:
		count += int(GameState.world.get_state("together_" + id, {"days": 0}).get("days", 0))
	_memories.text = "%d shared memories in your journal. There is no daily target." % count
	var ritual := _ritual()
	for id in _moment_buttons:
		var reason := ritual.unavailable_reason(id) if ritual else "The village is waking up."
		_moment_buttons[id].tooltip_text = reason
	_moment_buttons.appreciate.call_deferred("grab_focus")
