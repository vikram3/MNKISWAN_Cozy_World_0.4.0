class_name HUD
extends Control
## Exploration HUD (GDD §12): day/time, coins, one objective, contextual prompt, brief toasts,
## fishing cue with visual backup for audio, region banner, honest save indicator.

var _time_label: Label
var _period_label: Label
var _coin_label: Label
var _seed_label: Label
var _obj_title: Label
var _obj_text: Label
var _obj_box: PanelContainer
var _prompt_box: PanelContainer
var _prompt_key: Label
var _prompt_label: Label
var _toasts: VBoxContainer
var _fish_label: Label
var _region_label: Label
var _save_label: Label
var _hint: Label
var _hint_t := 75.0
var _coin_shown := 0
var _fish_state := ""
var _region_t := 0.0
var _save_t := 0.0
var _connected := false
var force_hidden := false
var _character_name: Label
var _ability: Label
var _portrait: TextureRect
var _portrait_id := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.get_theme()
	# --- Top-left: time + coins ----------------------------------------------------------------
	var tl := PanelContainer.new()
	tl.position = Vector2(24, 20)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tl)
	var tlv := VBoxContainer.new()
	tlv.add_theme_constant_override("separation", 2)
	tl.add_child(tlv)
	_time_label = UITheme.label("Day 1 · 6:00 AM", 28, UITheme.FOREST, true)
	tlv.add_child(_time_label)
	_period_label = UITheme.label("Morning", 20, UITheme.MUTED)
	tlv.add_child(_period_label)
	var coin_row := HBoxContainer.new()
	tlv.add_child(coin_row)
	var coin := PanelContainer.new()
	coin.custom_minimum_size = Vector2(26, 26)
	var csb := UITheme.box(UITheme.GOLD, 13, UITheme.WOOD, 2, 0)
	csb.shadow_size = 0
	coin.add_theme_stylebox_override("panel", csb)
	coin_row.add_child(coin)
	_coin_label = UITheme.label(" 0 coins", 26, UITheme.FOREST, true)
	coin_row.add_child(_coin_label)
	_seed_label = UITheme.label("", 18, UITheme.MUTED)
	tlv.add_child(_seed_label)
	# --- Top-centre: one objective --------------------------------------------------------------
	_obj_box = PanelContainer.new()
	_obj_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.place(_obj_box, Control.PRESET_CENTER_TOP, Vector2(-380, 20))
	_obj_box.custom_minimum_size = Vector2(760, 0)
	add_child(_obj_box)
	var ov := VBoxContainer.new()
	_obj_box.add_child(ov)
	_obj_title = UITheme.label("", 20, UITheme.CORAL, true)
	_obj_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(_obj_title)
	_obj_text = UITheme.label("", 25)
	_obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_obj_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(_obj_text)
	# --- Bottom-centre prompt -------------------------------------------------------------------
	_prompt_box = PanelContainer.new()
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.place(_prompt_box, Control.PRESET_CENTER_BOTTOM, Vector2(-400, -150))
	_prompt_box.custom_minimum_size = Vector2(800, 0)
	add_child(_prompt_box)
	var ph := HBoxContainer.new()
	ph.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_theme_constant_override("separation", 14)
	_prompt_box.add_child(ph)
	var keycap := PanelContainer.new()
	var ksb := UITheme.box(UITheme.FOREST, 10, Color(0, 0, 0, 0), 0, 10)
	ksb.shadow_size = 0
	keycap.add_theme_stylebox_override("panel", ksb)
	ph.add_child(keycap)
	_prompt_key = UITheme.label("E", 26, UITheme.CREAM, true)
	keycap.add_child(_prompt_key)
	_prompt_label = UITheme.label("", 27)
	ph.add_child(_prompt_label)
	_prompt_box.visible = false
	# --- Toasts (right) --------------------------------------------------------------------------
	_toasts = VBoxContainer.new()
	UITheme.place(_toasts, Control.PRESET_TOP_RIGHT, Vector2(-560, 24))
	_toasts.custom_minimum_size = Vector2(530, 0)
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_theme_constant_override("separation", 6)
	add_child(_toasts)
	# --- Fishing cue (centre) -------------------------------------------------------------------
	_fish_label = UITheme.label("", 60, UITheme.CORAL, true)
	UITheme.place(_fish_label, Control.PRESET_CENTER, Vector2(-400, -220))
	_fish_label.custom_minimum_size = Vector2(800, 0)
	_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fish_label.add_theme_constant_override("outline_size", 14)
	_fish_label.add_theme_color_override("font_outline_color", UITheme.CREAM)
	add_child(_fish_label)
	# --- Region banner ---------------------------------------------------------------------------
	_region_label = UITheme.label("", 46, UITheme.FOREST, true)
	UITheme.place(_region_label, Control.PRESET_CENTER_TOP, Vector2(-500, 150))
	_region_label.custom_minimum_size = Vector2(1000, 0)
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_label.add_theme_constant_override("outline_size", 12)
	_region_label.add_theme_color_override("font_outline_color", UITheme.CREAM)
	_region_label.modulate.a = 0.0
	add_child(_region_label)
	# --- Save indicator + controls hint ----------------------------------------------------------
	_save_label = UITheme.label("", 22, UITheme.FOREST, true)
	UITheme.place(_save_label, Control.PRESET_BOTTOM_RIGHT, Vector2(-260, -60))
	add_child(_save_label)
	_hint = UITheme.label("WASD move · Mouse look · E interact · Shift run · Space jump · Tab bag · J journal · M map · Esc pause", 20, UITheme.FOREST)
	UITheme.place(_hint, Control.PRESET_CENTER_BOTTOM, Vector2(-700, -58))
	_hint.custom_minimum_size = Vector2(1400, 0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.add_theme_color_override("font_outline_color", UITheme.CREAM)
	add_child(_hint)
	# --- Signals ---------------------------------------------------------------------------------
	GameState.toast.connect(_on_toast)
	GameState.economy.coins_changed.connect(func(_o, _n): _update_coins())
	GameState.quests.tracked_changed.connect(_update_objective)
	GameState.fishing_state_changed.connect(_on_fish)
	GameState.seed_selection_changed.connect(func(_s): _update_seed())
	GameState.inventory.inventory_changed.connect(func(_i, _d): _update_seed())
	GameState.world.region_discovered.connect(func(_r): pass)
	SaveManager.saved.connect(_on_saved)
	_coin_shown = GameState.economy.coins
	_update_coins()
	_update_objective()
	_update_seed()
	var card := PanelContainer.new()
	UITheme.place(card, Control.PRESET_BOTTOM_LEFT, Vector2(24, -210))
	card.custom_minimum_size = Vector2(360, 150)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(94, 114)
	row.add_child(_portrait)
	var info := VBoxContainer.new()
	row.add_child(info)
	_character_name = UITheme.label("MNKI", 27, UITheme.FOREST, true)
	info.add_child(_character_name)
	_ability = UITheme.label("", 19, UITheme.MUTED)
	info.add_child(_ability)


func _process(delta: float) -> void:
	var active := GameState.player as MnkiController
	if active:
		if _portrait_id != active.character_id:
			_portrait_id = active.character_id
			_portrait.texture = load("res://assets/characters/portraits/%s_happy.png" % _portrait_id)
		_character_name.text = active.character_id.to_upper() + "  ·  " + Settings.binding_label("switch_character") + " switch"
		if active.character_id == "swan":
			if active.flight_mode != "grounded":
				_ability.text = "%s · %.0f m\n%s rise · %s descend\n%s land / hover · Shift cruise" % [active.flight_mode.capitalize(), active.global_position.y, Settings.binding_label("jump"), Settings.binding_label("descend"), Settings.binding_label("fly")]
			else:
				_ability.text = "Sky feathers %d / 6\n%s spread your wings" % [SkyTrail.collected_count(), Settings.binding_label("fly")]
		else:
			_ability.text = "Village explorer\n%s jump · %s run" % [Settings.binding_label("jump"), Settings.binding_label("run")]
	if not _connected and GameState.player:
		var p := GameState.player as MnkiController
		if p and p.scanner:
			p.scanner.focus_changed.connect(_on_focus)
			_connected = true
	_time_label.text = "Day %d · %s" % [TimeManager.day, TimeManager.clock_string()]
	_period_label.text = TimeManager.period_name() + (" · Lantern market open" if DailyLifeData.market_open(TimeManager.hour()) else "") + "\n" + Settings.binding_label("together") + "  Our days together"
	_obj_box.visible = not bool(Settings.get_value("quiet_hud")) and (_obj_title.text != "FREE TIME" or GameState.quests.done_ids().size() > 0)
	# Coin count changes subtly
	if _coin_shown != GameState.economy.coins:
		_coin_shown += signi(GameState.economy.coins - _coin_shown) * maxi(1, absi(GameState.economy.coins - _coin_shown) / 8)
		_coin_label.text = " %d coins" % _coin_shown
	if _hint_t > 0.0:
		_hint_t -= delta
		_hint.modulate.a = clampf(_hint_t / 5.0, 0.0, 1.0)
	if _region_t > 0.0:
		_region_t -= delta
		_region_label.modulate.a = clampf(minf(_region_t, 4.0 - _region_t) * 1.5, 0.0, 1.0)
	if _save_t > 0.0:
		_save_t -= delta
		_save_label.modulate.a = clampf(_save_t, 0.0, 1.0)
	if _fish_state == "bite":
		_fish_label.scale = Vector2.ONE * (1.0 + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.08)
	visible = not force_hidden and not (GameState.top_ui() in ["pause", "map", "journal", "inventory", "shop", "storage", "settings", "together"])
	_check_region_banner()


var _last_region := ""


func _check_region_banner() -> void:
	var p := GameState.player as MnkiController
	if p == null:
		return
	var r := p.get_region_id()
	if r != _last_region:
		_last_region = r
		if r != "":
			_region_label.text = "%d · %s" % [int(GameData.REGIONS[r].num), String(GameData.REGIONS[r].name)]
			_region_t = 4.0


func _update_coins() -> void:
	if Settings.get_value("reduced_motion"):
		_coin_shown = GameState.economy.coins
	_coin_label.text = " %d coins" % _coin_shown


func _update_seed() -> void:
	var s := GameState.get_selected_seed()
	_seed_label.text = ("Seed: %s (%s)" % [ItemDB.display_name(s), Settings.binding_label("cycle_seed")]) if s != "" else ""


func _update_objective() -> void:
	var q := GameState.quests.tracked_quest()
	if q == "":
		_obj_box.visible = GameState.quests.done_ids().size() > 0
		_obj_title.text = "FREE TIME"
		_obj_text.text = "Explore, fish, farm, decorate — check the community board for requests."
		return
	_obj_box.visible = true
	_obj_title.text = String(GameState.quests.defs[q].title).to_upper()
	_obj_text.text = GameState.quests.objective_text(q)


func _on_focus(target, prompt: String, enabled: bool) -> void:
	if target == null or prompt == "":
		_prompt_box.visible = false
		return
	_prompt_box.visible = true
	_prompt_key.text = Settings.binding_label("interact").get_slice(" / ", 0)
	_prompt_label.text = prompt
	_prompt_box.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.55)


func _on_toast(text: String, kind: String) -> void:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := UITheme.CREAM
	var border := UITheme.SAGE
	match kind:
		"quest": border = UITheme.CORAL
		"item": border = UITheme.GOLD
		"warn": border = Color("d9534f")
		"discovery", "journal": border = UITheme.TEAL
	var sb := UITheme.box(col, 14, border, 3, 12)
	pc.add_theme_stylebox_override("panel", sb)
	var l := UITheme.label(text, 22)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 500
	pc.add_child(l)
	_toasts.add_child(pc)
	while _toasts.get_child_count() > 3:
		var old := _toasts.get_child(0)
		_toasts.remove_child(old)
		old.queue_free()
	var tw := pc.create_tween()
	tw.tween_interval(3.6)
	tw.tween_property(pc, "modulate:a", 0.0, 0.6)
	tw.tween_callback(pc.queue_free)
	if kind == "item":
		AudioManager.play_sfx("pickup")


func _on_fish(state: String) -> void:
	_fish_state = state
	_fish_label.scale = Vector2.ONE
	match state:
		"waiting":
			_fish_label.text = "Watch the bobber..."
			_fish_label.add_theme_font_size_override("font_size", 36)
		"bite":
			_fish_label.text = "!  BITE — press %s  !" % Settings.binding_label("interact").get_slice(" / ", 0)
			_fish_label.add_theme_font_size_override("font_size", 64)
		"caught":
			_fish_label.text = "Caught!"
			_fish_label.add_theme_font_size_override("font_size", 56)
		_:
			_fish_label.text = ""


func _on_saved(ok: bool, reason: String) -> void:
	_save_label.text = "Saved" if ok else "Save failed: " + reason
	_save_label.add_theme_color_override("font_color", UITheme.FOREST if ok else Color("b03a2e"))
	_save_t = 3.0
	if ok:
		AudioManager.play_sfx("save")
