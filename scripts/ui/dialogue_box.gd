class_name DialogueBox
extends Control
## Dialogue UI (GDD §12): portrait, name, short lines, few choices, skippable. Lines use
## "Speaker: text". Mnki and Swan use their official sticker art as portraits (canon §7).
## Requests are queued so nothing interrupts mid-line.

const PORTRAITS := {
	"Swan": "res://assets/characters/portraits/swan_happy.png",
	"Mnki": "res://assets/characters/portraits/mnki_happy.png",
}

var _queue: Array = []        # [{lines, choices, cb}]
var _cur: Dictionary = {}
var _idx := 0
var _box: PanelContainer
var _portrait: TextureRect
var _badge: PanelContainer
var _badge_label: Label
var _name: Label
var _text: RichTextLabel
var _choices: HBoxContainer
var _cont: Label
var _typing := 0.0
var _active := false
var _open_frame := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	_box = PanelContainer.new()
	UITheme.place(_box, Control.PRESET_CENTER_BOTTOM, Vector2(-760, -330))
	_box.custom_minimum_size = Vector2(1520, 270)
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	_box.add_child(h)
	var pbox := Control.new()
	pbox.custom_minimum_size = Vector2(220, 230)
	h.add_child(pbox)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pbox.add_child(_portrait)
	_badge = PanelContainer.new()
	_badge.custom_minimum_size = Vector2(170, 170)
	_badge.position = Vector2(25, 30)
	pbox.add_child(_badge)
	_badge_label = UITheme.label("", 80, UITheme.CREAM, true)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.add_child(_badge_label)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	h.add_child(v)
	_name = UITheme.label("", 32, UITheme.CORAL, true)
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(1200, 110)
	_text.add_theme_font_size_override("normal_font_size", int(30 * float(Settings.get_value("text_scale"))))
	_text.add_theme_color_override("default_color", UITheme.FOREST)
	v.add_child(_text)
	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", 16)
	v.add_child(_choices)
	_cont = UITheme.label("E / Space / Click to continue", 18, UITheme.MUTED)
	_cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_cont)
	_box.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_advance())
	visible = false
	GameState.dialogue_requested.connect(_enqueue)


func is_active() -> bool:
	return _active


func _enqueue(lines: Array, choices: Array, cb: Callable) -> void:
	_queue.append({"lines": lines.duplicate(), "choices": choices.duplicate(), "cb": cb})
	if not _active:
		_next_request()


func _next_request() -> void:
	if _queue.is_empty():
		_active = false
		visible = false
		GameState.pop_ui("dialogue")
		AudioManager.set_ducked(false)
		return
	_cur = _queue.pop_front()
	_idx = 0
	_active = true
	visible = true
	_open_frame = Engine.get_process_frames()
	GameState.push_ui("dialogue")
	AudioManager.set_ducked(true)
	_show_line()


func _show_line() -> void:
	var lines: Array = _cur.lines
	var raw := String(lines[_idx])
	var speaker := ""
	var body := raw
	var colon := raw.find(": ")
	if colon > 0 and colon < 24:
		speaker = raw.substr(0, colon)
		body = raw.substr(colon + 2)
	_name.text = speaker
	_text.text = body
	_text.visible_ratio = 0.0
	_typing = 0.0
	if Settings.get_value("reduced_motion"):
		_text.visible_ratio = 1.0
	var first_word := speaker.split(" ")[0] if speaker != "" else ""
	if PORTRAITS.has(speaker):
		_portrait.texture = load(PORTRAITS[speaker])
		_portrait.visible = true
		_badge.visible = false
	else:
		_portrait.visible = false
		_badge.visible = speaker != ""
		var npc_id := _npc_id_for(speaker)
		var col := UITheme.WOOD
		if npc_id != "":
			col = Color(String(NpcDB.get_def(npc_id).get("top", "#8b6749")))
		elif speaker in ["Plaque", "Board"]:
			col = Color("8d969c")
		var sb := UITheme.box(col, 85, UITheme.FOREST, 3, 0)
		_badge.add_theme_stylebox_override("panel", sb)
		_badge_label.text = first_word.substr(0, 1)
	UITheme.clear(_choices)
	var last := _idx == lines.size() - 1
	_cont.visible = not (last and not (_cur.choices as Array).is_empty())
	if last and not (_cur.choices as Array).is_empty():
		var choices: Array = _cur.choices
		for i in choices.size():
			var idx := i
			var b := UITheme.button("%d. %s" % [i + 1, String(choices[i])], func(): _choose(idx), 260)
			_choices.add_child(b)
		_focus_choice.call_deferred(_choices.get_child(0))

func _focus_choice(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and button.is_visible_in_tree():
		button.grab_focus()


func _npc_id_for(speaker: String) -> String:
	for region in VillageLifeData.PLACES:
		if VillageLifeData.PLACES[region][2] == speaker:
			return VillageLifeData.host_id(region)
	for id in DailyLifeData.RESIDENTS:
		if String(DailyLifeData.RESIDENTS[id].name) == speaker:
			return id
	for id in NpcDB.NPCS:
		if String(NpcDB.NPCS[id].name) == speaker:
			return id
	return ""


func _process(delta: float) -> void:
	if not _active:
		return
	if _text.visible_ratio < 1.0:
		_typing += delta * 55.0
		var total := maxi(_text.get_total_character_count(), 1)
		_text.visible_ratio = minf(_typing / total, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if Engine.get_process_frames() - _open_frame < 2:
		return  # the key that opened the dialogue must not also advance it
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER):
		_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1, KEY_2, KEY_3]:
		var i: int = event.keycode - KEY_1
		if i < _choices.get_child_count() and _idx == (_cur.lines as Array).size() - 1:
			_choose(i)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel"):
		# Skip to the end of this conversation (choices still need an answer)
		if (_cur.choices as Array).is_empty():
			_finish(-1)
		else:
			_idx = (_cur.lines as Array).size() - 1
			_show_line()
			_text.visible_ratio = 1.0
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _text.visible_ratio < 1.0:
		_text.visible_ratio = 1.0
		_typing = 9999.0
		return
	var lines: Array = _cur.lines
	if _idx < lines.size() - 1:
		_idx += 1
		AudioManager.play_sfx("ui")
		_show_line()
	elif (_cur.choices as Array).is_empty():
		_finish(-1)


func _choose(i: int) -> void:
	AudioManager.play_sfx("ui")
	_finish(i)


func _finish(choice: int) -> void:
	var cb: Callable = _cur.cb
	_cur = {}
	GameState.pop_ui("dialogue")
	_active = false
	if cb.is_valid():
		cb.call(choice)
	if not _active:
		_next_request()
