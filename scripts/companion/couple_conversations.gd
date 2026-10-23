class_name CoupleConversations
extends CanvasLayer
## Non-modal, interruptible conversations. Speaker identity follows the model, not controller role.
const IDLE_DELAY := 35.0
const BETWEEN_CHATS := 95.0
const CHATS := [
	["Mnki: Do we have to do anything right now?", "Swan: We could just be here.", "Mnki: With you? That sounds like a very good plan."],
	["Swan: What makes a place feel like home?", "Mnki: Knowing I can be my ordinary self there.", "Swan: Then you can always be at home with me."],
	["Mnki: Some days I feel like I haven't done enough.", "Swan: You don't have to earn a peaceful moment.", "Mnki: Will you remind me when I forget?", "Swan: As often as you need."],
	["Swan: You saved the last berry for me again.", "Mnki: It looked like your favourite one.", "Swan: Funny. They all look like my favourite when you give them to me."],
	["Mnki: I wish I knew the right thing to say every time.", "Swan: You can start by listening.", "Mnki: I'm here. Take your time."],
	["Swan: The village feels different when we slow down.", "Mnki: I notice the small things. Like how you hum when you're happy.", "Swan: I didn't know you noticed.", "Mnki: Those are my favourite things to notice."],
	["Mnki: If I get lost, will you come find me?", "Swan: Yes. But we should probably bring a map too.", "Mnki: Love and sensible planning. I like us."],
	["Swan: Even trees take a season to rest.", "Mnki: So sitting here counts as being wise?", "Swan: Extremely wise. We might need another minute."],
	["Mnki: We don't always have to agree, do we?", "Swan: No. We just have to remember we're on the same side.", "Mnki: Your hand in mine helps me remember."],
	["Swan: What's your favourite part of today?", "Mnki: This part.", "Swan: You said that earlier.", "Mnki: Today keeps getting better."],
	["Mnki: I can't fix everything that makes you sad.", "Swan: I know. Sitting beside me still helps.", "Mnki: Then I'm staying right here."],
	["Swan: A kind word can travel farther than we ever see.", "Mnki: Like a seed on the breeze?", "Swan: Exactly. Let's plant a few wherever we go."],
	["Mnki: You make quiet moments feel full.", "Swan: Maybe quiet is where we hear each other best.", "Mnki: Then let's leave a little room for it."],
	["Swan: We can try again tomorrow.", "Mnki: Even if we make a muddle of it today?", "Swan: Especially then. Growing takes practice."],
	["Mnki: Your wings are lovely when you fly.", "Swan: The best part is knowing you're here when I land.", "Mnki: Always cheering. Occasionally waving both arms."],
	["Swan: Thank you for the little things.", "Mnki: Which little things?", "Swan: Remembering. Waiting. Asking how I am.", "Mnki: Those never feel little to me."],
]

var idle_seconds := 0.0
var cooldown := 0.0
var active := false
var current_lines: Array = []
var line_index := 0
var line_seconds := 0.0
var current_speaker := ""
var _last_character := ""
var _box: PanelContainer
var _portrait: TextureRect
var _name: Label
var _words: Label

func _ready() -> void:
	name = "CoupleConversations"
	layer = 9
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_box = PanelContainer.new()
	root.add_child(_box)
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_box.offset_left = -450
	_box.offset_right = 450
	_box.offset_top = -330
	_box.offset_bottom = -170
	_box.add_theme_stylebox_override("panel", UITheme.box(Color("fff5e6"), 22, UITheme.GOLD, 2, 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_box.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_name = UITheme.label("", 22, UITheme.CORAL, true)
	col.add_child(_name)
	_words = UITheme.label("", 25, UITheme.FOREST)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_words)
	_ignore_mouse(root)
	_box.hide()
	Settings.settings_changed.connect(func():
		_words.add_theme_font_size_override("font_size", int(25 * float(Settings.get_value("text_scale"))))
		if not bool(Settings.get_value("idle_conversations")): cancel())

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		cancel()
	elif event is InputEventMouseMotion and event.relative.length() > 2.0:
		cancel()

func eligible() -> bool:
	var p := GameState.player as MnkiController
	var friend := GameState.swan as SwanCompanion
	if not p or not friend or not bool(Settings.get_value("idle_conversations")) or GameState.is_ui_blocking():
		return false
	if p.flight_mode != "grounded" or p.state != "free" or not p.is_on_floor() or p.model.is_busy():
		return false
	if p.velocity.length() > 0.15 or friend.velocity.length() > 0.2 or friend._bubble_t > 0 or friend.model.is_busy():
		return false
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "interact", "switch_character", "fly"]:
		if Input.is_action_pressed(action):
			return false
	for npc: NpcCharacter in get_tree().get_nodes_in_group("villager"):
		if npc._bubble_t > 0 and npc.global_position.distance_to(p.global_position) < 7:
			return false
	return p.global_position.distance_to(friend.global_position) < 4.0

func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	var p := GameState.player as MnkiController
	if p and p.character_id != _last_character:
		_last_character = p.character_id
		cancel()
	if not eligible():
		cancel()
		return
	if cooldown > 0:
		cooldown = maxf(0, cooldown - delta)
		return
	if active:
		line_seconds -= delta
		if line_seconds <= 0:
			line_index += 1
			if line_index >= current_lines.size():
				cancel()
			else:
				_show_line()
	else:
		idle_seconds += delta
		if idle_seconds >= IDLE_DELAY:
			begin_chat()

func begin_chat() -> void:
	if not eligible() or active:
		return
	var state := GameState.world.get_state("couple_conversations", {"next": 0})
	var index := int(state.get("next", 0))
	var region := (GameState.player as MnkiController).get_region_id()
	# Every third conversation reflects the current place; the others cycle without repeats.
	if index % 3 == 2 and VillageLifeData.PLACES.has(region):
		var activities: Array = VillageLifeData.PLACES[region][5]
		current_lines = ["Swan: " + String(activities[(index / 3) % 3][3]), "Mnki: I like that. Can we stay here a little longer?", "Swan: Of course. We have time for us."]
	else:
		var general_index := int(state.get("general_next", 0))
		current_lines = CHATS[general_index % CHATS.size()].duplicate()
		state.general_next = general_index + 1
	state.next = index + 1
	GameState.world.set_state("couple_conversations", state)
	active = true
	line_index = 0
	idle_seconds = 0
	_show_line()

func speaker_model(speaker: String) -> CharModel:
	var p := GameState.player as MnkiController
	return p.model if p.character_id == speaker.to_lower() else GameState.swan.model

func _show_line() -> void:
	var line := String(current_lines[line_index])
	var split := line.find(":")
	current_speaker = line.substr(0, split)
	var words := line.substr(split + 1).strip_edges()
	_name.text = current_speaker + "  ·  A moment together"
	_words.text = words
	_portrait.texture = load(DialogueBox.PORTRAITS[current_speaker])
	line_seconds = maxf(5.5, words.length() / 13.0)
	_box.show()
	speaker_model(current_speaker).set_expression("happy", line_seconds)

func cancel() -> void:
	if active:
		cooldown = BETWEEN_CHATS
	active = false
	idle_seconds = 0
	if is_instance_valid(_box):
		_box.hide()
