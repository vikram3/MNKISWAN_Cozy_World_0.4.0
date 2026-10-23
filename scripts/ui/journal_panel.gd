class_name JournalPanel
extends ModalPanel
## Journal (GDD §12): current requests with exact next action, completed requests, discoveries
## (regions, fish, forage, animals), Guardian notes, and a small stats page.

var _tabs: TabContainer
var _req: VBoxContainer
var _disc: VBoxContainer
var _notes: VBoxContainer
var _duo: VBoxContainer
var _life: VBoxContainer


func _init() -> void:
	super._init()
	panel_id = "journal"
	title_text = "Our Journal"


func build_content() -> void:
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)
	for n in ["Requests", "Discoveries", "Notes", "Village life", "Mnki & Swan"]:
		var v := VBoxContainer.new()
		v.name = n
		_tabs.add_child(v)
		var inner := scroll_box(v, 600)
		match n:
			"Requests": _req = inner
			"Discoveries": _disc = inner
			"Notes": _notes = inner
			"Village life": _life = inner
			_: _duo = inner


func refresh() -> void:
	UITheme.clear(_life)
	_life.add_child(UITheme.label("Little memories, all around the village", 28, UITheme.CORAL, true))
	_life.add_child(UITheme.label("Three activities in each place. Two coins each per day. No deadlines.", 22))
	for region in VillageLifeData.PLACES:
		var place: Array = VillageLifeData.PLACES[region]
		var known := GameState.world.is_discovered(region)
		if not known:
			_life.add_child(UITheme.label("    An undiscovered gathering place", 22, UITheme.MUTED))
			continue
		var visits := int(GameState.world.get_state("npc_" + VillageLifeData.host_id(region) + "_friendship").get("days", 0))
		_life.add_child(UITheme.label("%s · %s · chatted on %d days" % [GameData.REGIONS[region].name, place[2], visits], 25, UITheme.FOREST, true))
		for i in 3:
			var state := GameState.world.get_state("cozy_%s_%d" % [region, i])
			var status := "[done today]" if int(state.get("day", -1)) == TimeManager.day else ("[memory collected]" if state.get("visited", false) else "[new memory]")
			_life.add_child(UITheme.label("    %s %s" % [status, place[5][i][1]], 21, UITheme.MUTED))
	var q := GameState.quests
	UITheme.clear(_req)
	var act := q.active_ids()
	_req.add_child(UITheme.label("In progress", 28, UITheme.CORAL, true))
	if act.is_empty():
		_req.add_child(UITheme.label("Nothing in progress. Check the community board in the park!", 22, UITheme.MUTED))
	for id in act:
		var d: Dictionary = q.defs[id]
		_req.add_child(UITheme.label(("[Main] " if d.get("main", false) else "") + String(d.title), 26, UITheme.FOREST, true))
		var s := UITheme.label(String(d.get("summary", "")), 20, UITheme.MUTED)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 1180
		_req.add_child(s)
		var objs: Array = d.objectives
		var step := int(q.states[id].step)
		for i in objs.size():
			var mark := "[x] " if i < step else ("[>] " if i == step else "[ ] ")
			var txt: String = q.objective_text(id) if i == step else String(objs[i].text)
			_req.add_child(UITheme.label("    " + mark + txt, 22, UITheme.FOREST if i == step else UITheme.MUTED))
	var avail: Array = []
	for id in q.order:
		var d: Dictionary = q.defs[id]
		if not q.states.has(id) and not d.get("auto_start", false) and q.prereqs_met(id):
			avail.append("%s — ask %s" % [String(d.title), NpcDB.display_name(String(d.giver))])
	if not avail.is_empty():
		_req.add_child(UITheme.label("Someone could use help", 28, UITheme.CORAL, true))
		for a in avail:
			_req.add_child(UITheme.label("    " + String(a), 22))
	_req.add_child(UITheme.label("Completed (%d)" % q.done_ids().size(), 28, UITheme.CORAL, true))
	for id in q.done_ids():
		_req.add_child(UITheme.label("    [x] " + String(q.defs[id].title), 22, UITheme.MUTED))

	UITheme.clear(_disc)
	var w := GameState.world
	_disc.add_child(UITheme.label("Places (%d/%d)" % [w.discovered_regions.size(), GameData.REGIONS.size()], 28, UITheme.CORAL, true))
	var ids: Array = GameData.REGIONS.keys()
	ids.sort_custom(func(a, b): return int(GameData.REGIONS[a].num) < int(GameData.REGIONS[b].num))
	for id in ids:
		var r: Dictionary = GameData.REGIONS[id]
		if w.is_discovered(id):
			_disc.add_child(UITheme.label("    %02d  %s — %s" % [int(r.num), String(r.name), String(r.desc)], 21))
		else:
			_disc.add_child(UITheme.label("    %02d  ???" % int(r.num), 21, UITheme.MUTED))
	var j := GameState.journal
	var fish_total := 0
	for id in ItemDB.ITEMS:
		if ItemDB.category(id) == "fish":
			fish_total += 1
	_disc.add_child(UITheme.label("Fish (%d/%d)" % [j.fish.size(), fish_total], 28, UITheme.CORAL, true))
	for id in ItemDB.ITEMS:
		if ItemDB.category(id) != "fish":
			continue
		if j.fish.has(id):
			_disc.add_child(UITheme.label("    %s — %s (first caught day %d at %s)" % [ItemDB.display_name(id), String(ItemDB.get_def(id).desc), int(j.fish[id].day), String(j.fish[id].get("region", "?"))], 20))
		else:
			_disc.add_child(UITheme.label("    ???", 20, UITheme.MUTED))
	_disc.add_child(UITheme.label("Gathered & grown (%d)" % j["items"].size(), 28, UITheme.CORAL, true))
	var names: Array = []
	for id in j["items"]:
		names.append(ItemDB.display_name(String(id)))
	var nl := UITheme.label("    " + (", ".join(names) if not names.is_empty() else "Nothing yet."), 21)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size.x = 1180
	_disc.add_child(nl)
	_disc.add_child(UITheme.label("Animal care (%d/3)" % j.animals.size(), 28, UITheme.CORAL, true))
	for sp in ["cow", "sheep", "chicken"]:
		_disc.add_child(UITheme.label("    %s %s" % ["[x]" if j.animals.has(sp) else "[ ]", sp.capitalize()], 21))

	UITheme.clear(_notes)
	if j.notes.is_empty():
		_notes.add_child(UITheme.label("No notes yet. The Guardian statues by the gate have plaques...", 22, UITheme.MUTED))
	for id in j.notes:
		var n: Dictionary = j.notes[id]
		_notes.add_child(UITheme.label(String(n.title), 26, UITheme.FOREST, true))
		var t := UITheme.label("    " + String(n.text), 22)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size.x = 1180
		_notes.add_child(t)

	UITheme.clear(_duo)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	_duo.add_child(h)
	for path in ["res://assets/characters/portraits/mnki_cheer.png", "res://assets/characters/portraits/couple_kiss.png", "res://assets/characters/portraits/swan_cheer.png"]:
		var tr := TextureRect.new()
		tr.texture = load(path)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(340, 340)
		h.add_child(tr)
	var st := GameState.stats
	_duo.add_child(UITheme.label("Day %d together · %d coins · Stall level %d · Fish caught %d · Harvests %d · Animal care %d" % [TimeManager.day, GameState.economy.coins, GameState.shop.level, int(st.fish_caught), int(st.harvests), int(st.care_actions)], 22))
	var bond: Array = []
	for f in ["met_thronn", "stall_open", "park_restored", "fisher_friend", "bridge_restored", "festival"]:
		if w.has_flag(f):
			bond.append({"met_thronn": "Visited Thronn's animals", "stall_open": "First sale together", "park_restored": "Restored the park flower bed", "fisher_friend": "Learned patience from Lumi", "bridge_restored": "Mended the old bridge", "festival": "Celebrated Land, Water and Forest"}[f])
	_duo.add_child(UITheme.label("Shared milestones:", 26, UITheme.CORAL, true))
	if bond.is_empty():
		_duo.add_child(UITheme.label("    Your story together is just beginning.", 22, UITheme.MUTED))
	for b in bond:
		_duo.add_child(UITheme.label("    * " + String(b), 22))
