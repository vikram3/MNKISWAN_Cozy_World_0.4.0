class_name FarmPlot
extends Interactable
## Crop plot state machine (GDD §9.4): empty → planted → growing (stages) → ready → harvest → empty.
## A plot watered on a day grows one stage the next morning. Crops never die; growth just pauses.

var _soil: MeshInstance3D
var _crop_root: Node3D
var _watered_fx: Node3D


func setup(id: String) -> FarmPlot:
	object_id = id
	return self


func _ready() -> void:
	marker_height = 1.2
	interaction_range = 2.2
	super._ready()
	_soil = CharParts.add(self, CharParts.box_mesh(Vector3(1.6, 0.16, 1.6)), CharParts.mat(Color("8a6243"), 0.01), Vector3(0, 0.08, 0))
	for i in 3:
		CharParts.add(self, CharParts.box_mesh(Vector3(1.4, 0.06, 0.18)), CharParts.mat(Color("7a553a")), Vector3(0, 0.17, -0.5 + i * 0.5))
	_crop_root = Node3D.new()
	add_child(_crop_root)
	_watered_fx = Node3D.new()
	add_child(_watered_fx)
	for i in 4:
		CharParts.add(_watered_fx, CharParts.cyl_mesh(0.12, 0.12, 0.01, 10), CharParts.unshaded(Color(0.47, 0.79, 0.83, 0.7)), Vector3(-0.4 + i * 0.27, 0.205, 0.3 * (i % 2) - 0.15))
	GameState.world.object_state_changed.connect(_on_obj_changed)
	TimeManager.day_started.connect(_on_day)
	_refresh()


func _on_obj_changed(id: String) -> void:
	if id == object_id:
		_refresh()


func _state() -> Dictionary:
	return GameState.world.get_state(object_id, {"crop": "", "stage": 0, "growth": 0, "watered_day": -1})


func _crop_def() -> Dictionary:
	return GameData.CROPS.get(String(_state().crop), {})


func is_ready_crop() -> bool:
	var st := _state()
	return st.crop != "" and int(st.growth) >= int(_crop_def().get("days", 99))


func _on_day(day: int) -> void:
	var st := _state()
	if st.crop == "":
		return
	if int(st.watered_day) == day - 1 and not is_ready_crop():
		st.growth = int(st.growth) + 1
		GameState.world.set_state(object_id, st)
	_refresh()


func get_interaction_prompt(_actor: Node) -> String:
	var st := _state()
	if st.crop == "":
		var seed_id := GameState.get_selected_seed()
		if seed_id == "":
			return "Empty plot — buy seeds from Tamsin at the market"
		return "Plant %s  (R: change seed)" % ItemDB.display_name(seed_id)
	var cd := _crop_def()
	if is_ready_crop():
		return "Harvest %s" % String(cd.name)
	if int(st.watered_day) != TimeManager.day:
		return "Water the %s (day %d/%d)" % [String(cd.name).to_lower(), int(st.growth), int(cd.days)]
	return "%s growing — watered today (day %d/%d). Sleep to grow." % [String(cd.name), int(st.growth), int(cd.days)]


func can_interact(_actor: Node) -> bool:
	return true


func interact(actor: Node) -> void:
	var st := _state()
	if st.crop == "":
		var seed_id := GameState.get_selected_seed()
		if seed_id == "":
			GameState.notify("No seeds yet. Tamsin sells them at the market.", "warn")
			AudioManager.play_sfx("error")
			return
		if not GameState.inventory.remove(seed_id, 1):
			return
		st = {"crop": ItemDB.seed_crop(seed_id), "growth": 0, "watered_day": -1, "planted_day": TimeManager.day}
		GameState.world.set_state(object_id, st)
		if actor.has_method("play_action"):
			actor.play_action("plant", 0.6)
		AudioManager.play_sfx("plant")
		GameState.notify("Planted %s. Water it, then sleep." % String(_crop_def().name), "info")
		return
	if is_ready_crop():
		var cd := _crop_def()
		var item := String(cd.harvest)
		var qty := int(cd.yield)
		if not GameState.inventory.can_add(item, qty):
			GameState.notify("Your bag is full — the crop will wait for you.", "warn")
			AudioManager.play_sfx("error")
			return
		var crop_id := String(st.crop)
		GameState.world.set_state(object_id, {"crop": "", "growth": 0, "watered_day": -1})
		GameState.inventory.add(item, qty)
		GameState.stats.harvests = int(GameState.stats.harvests) + 1
		if actor.has_method("play_action"):
			actor.play_action("harvest", 0.6)
		AudioManager.play_sfx("harvest")
		GameState.notify("+%d %s" % [qty, ItemDB.display_name(item)], "item")
		GameState.quests.on_event("harvest", {"crop": crop_id})
		if int(GameState.stats.harvests) == 1:
			GameState.companion("first_harvest")
		return
	if int(st.watered_day) != TimeManager.day:
		st.watered_day = TimeManager.day
		GameState.world.set_state(object_id, st)
		if actor.has_method("play_action"):
			actor.play_action("water", 0.7)
		AudioManager.play_sfx("water")
		GameState.notify("Watered. It will grow overnight.", "info")
		return
	GameState.notify("Already watered today — sleep in the treehouse to let it grow.", "info")


func _refresh() -> void:
	for c in _crop_root.get_children():
		c.queue_free()
	var st := _state()
	_watered_fx.visible = st.crop != "" and int(st.watered_day) == TimeManager.day
	_soil.material_override = CharParts.mat(Color("6b4a33") if _watered_fx.visible else Color("8a6243"), 0.01)
	if st.crop == "":
		return
	var cd := _crop_def()
	var days := int(cd.get("days", 2))
	var stage := 0 if int(st.growth) == 0 else (3 if int(st.growth) >= days else (1 if int(st.growth) * 2 < days + 1 else 2))
	var leaf := Color(String(cd.get("leaf", "#5fa35a")))
	var col := Color(String(cd.get("color", "#ffffff")))
	for i in 4:
		var p := Vector3(-0.4 + (i % 2) * 0.8, 0.18, -0.4 + (i / 2) * 0.8)
		match stage:
			0:
				CharParts.sphere(_crop_root, 0.08, Color("6b4a33"), p, Vector3(1.2, 0.5, 1.2), 0.006)
				CharParts.add(_crop_root, CharParts.cyl_mesh(0.015, 0.015, 0.25, 5), CharParts.mat(Color("d8c7a0")), p + Vector3(0.12, 0.12, 0))
			1:
				CharParts.add(_crop_root, CharParts.cyl_mesh(0.0, 0.08, 0.22, 6), CharParts.mat(leaf, 0.006), p + Vector3(0, 0.11, 0))
			2:
				CharParts.add(_crop_root, CharParts.cyl_mesh(0.02, 0.02, 0.4, 6), CharParts.mat(leaf), p + Vector3(0, 0.2, 0))
				CharParts.sphere(_crop_root, 0.13, leaf, p + Vector3(0, 0.38, 0), Vector3(1, 0.7, 1), 0.008)
			3:
				_mature(String(st.crop), p, leaf, col)


func _mature(crop: String, p: Vector3, leaf: Color, col: Color) -> void:
	match crop:
		"rice":
			for k in 5:
				var st := CharParts.add(_crop_root, CharParts.cyl_mesh(0.012, 0.012, 0.6, 4), CharParts.mat(Color("c9b46a")), p + Vector3((k - 2) * 0.04, 0.3, 0), Vector3(0, 0, (k - 2) * 8))
				st.name = "Stalk"
				CharParts.add(_crop_root, CharParts.capsule_mesh(0.03, 0.16), CharParts.mat(col, 0.005), p + Vector3((k - 2) * 0.06, 0.6, 0), Vector3(0, 0, (k - 2) * 15))
		"lettuce":
			CharParts.sphere(_crop_root, 0.2, col, p + Vector3(0, 0.15, 0), Vector3(1, 0.75, 1), 0.01)
			CharParts.sphere(_crop_root, 0.13, col.lightened(0.2), p + Vector3(0, 0.25, 0), Vector3(1, 0.7, 1), 0.008)
		"tomato":
			CharParts.add(_crop_root, CharParts.cyl_mesh(0.02, 0.02, 0.6, 6), CharParts.mat(leaf), p + Vector3(0, 0.3, 0))
			CharParts.sphere(_crop_root, 0.17, leaf, p + Vector3(0, 0.55, 0), Vector3(1, 0.8, 1), 0.008)
			for k in 3:
				CharParts.sphere(_crop_root, 0.07, col, p + Vector3(cos(k * 2.1) * 0.15, 0.4 + k * 0.05, sin(k * 2.1) * 0.15), Vector3.ONE, 0.006)
		"carrot":
			CharParts.add(_crop_root, CharParts.cyl_mesh(0.06, 0.0, 0.12, 8), CharParts.mat(col, 0.006), p + Vector3(0, 0.2, 0))
			for k in 3:
				CharParts.add(_crop_root, CharParts.cyl_mesh(0.0, 0.04, 0.3, 5), CharParts.mat(leaf, 0.005), p + Vector3(0, 0.4, 0), Vector3((k - 1) * 20, k * 60, 0))
		"sunflower":
			CharParts.add(_crop_root, CharParts.cyl_mesh(0.025, 0.03, 1.1, 6), CharParts.mat(leaf), p + Vector3(0, 0.55, 0))
			var head := CharParts.add(_crop_root, CharParts.cyl_mesh(0.18, 0.18, 0.05, 14), CharParts.mat(col, 0.008), p + Vector3(0, 1.1, 0.04), Vector3(70, 0, 0))
			head.name = "Head"
			CharParts.add(_crop_root, CharParts.cyl_mesh(0.09, 0.09, 0.06, 12), CharParts.mat(Color("6b4423")), p + Vector3(0, 1.11, 0.07), Vector3(70, 0, 0))
		_:
			CharParts.sphere(_crop_root, 0.15, col, p + Vector3(0, 0.2, 0), Vector3.ONE, 0.008)
