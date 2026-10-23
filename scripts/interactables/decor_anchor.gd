class_name DecorAnchor
extends Interactable
## Curated decoration anchor (GDD §9.8). Placing moves the item from the bag onto the anchor;
## storing moves it back. Placement persists exactly via WorldStateSystem.decor.

var item_id := ""
var _visual: Node3D
var _ghost: Node3D


func setup(anchor_id: String) -> DecorAnchor:
	object_id = anchor_id
	item_id = String(GameData.DECOR_ANCHORS[anchor_id].item)
	return self


func _ready() -> void:
	marker_height = 1.1
	interaction_range = 1.9
	super._ready()
	_ghost = Node3D.new()
	add_child(_ghost)
	var g := CharParts.add(_ghost, CharParts.cyl_mesh(0.25, 0.25, 0.01, 16), CharParts.unshaded(Color(0.89, 0.73, 0.42, 0.35)), Vector3(0, 0.02, 0))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	GameState.world.object_state_changed.connect(_on_changed)
	GameState.inventory.inventory_changed.connect(func(_i, _d): _refresh())
	_refresh()


func _on_changed(id: String) -> void:
	if id == object_id:
		_refresh()


func is_placed() -> bool:
	return GameState.world.decor.get(object_id, "") == item_id


func can_interact(_actor: Node) -> bool:
	return is_placed() or GameState.inventory.count(item_id) > 0


func get_interaction_prompt(_actor: Node) -> String:
	if is_placed():
		return "Store the %s" % ItemDB.display_name(item_id)
	return "Place the %s here" % ItemDB.display_name(item_id)


func interact(actor: Node) -> void:
	if is_placed():
		if not GameState.inventory.can_add(item_id, 1):
			GameState.notify("Bag full — can't store it right now.", "warn")
			return
		GameState.world.clear_decor(object_id)
		GameState.inventory.add(item_id, 1)
		AudioManager.play_sfx("ui_back")
	else:
		if not GameState.inventory.remove(item_id, 1):
			return
		GameState.world.place_decor(object_id, item_id)
		AudioManager.play_sfx("upgrade")
		GameState.notify("Placed: " + ItemDB.display_name(item_id), "info")
		GameState.companion("decor_placed", {"item": item_id})
		if actor.has_method("play_action"):
			actor.play_action("shop", 0.6)


func _refresh() -> void:
	if _visual:
		_visual.queue_free()
		_visual = null
	var placed := is_placed()
	_ghost.visible = not placed and GameState.inventory.count(item_id) > 0
	if not placed:
		return
	_visual = Node3D.new()
	add_child(_visual)
	var c := ItemDB.color_of(item_id)
	match item_id:
		"decor_rug":
			CharParts.add(_visual, CharParts.cyl_mesh(1.1, 1.1, 0.03, 32), CharParts.mat(c), Vector3(0, 0.02, 0))
			CharParts.add(_visual, CharParts.torus_mesh(0.6, 0.7, 6, 32), CharParts.mat(Color("f3d27a")), Vector3(0, 0.03, 0), Vector3.ZERO, Vector3(1, 0.15, 1))
		"decor_lamp":
			CharParts.add(_visual, CharParts.cyl_mesh(0.04, 0.1, 0.9, 8), CharParts.mat(EnvKit.WOOD_DARK, 0.008), Vector3(0, 0.45, 0))
			var shade := CharParts.sphere(_visual, 0.22, c, Vector3(0, 1.0, 0), Vector3(1, 1.1, 1), 0.01)
			shade.material_override = CharParts.mat(c, 0.01, 1.2)
			CharParts.add(_visual, CharParts.cyl_mesh(0.02, 0.06, 0.1, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(0, 1.22, 0))
			var l := OmniLight3D.new(); l.light_color = Color("ffd59a"); l.omni_range = 4.0; l.light_energy = 0.8; l.position = Vector3(0, 1.0, 0)
			_visual.add_child(l)
		"decor_plant":
			CharParts.add(_visual, CharParts.cyl_mesh(0.22, 0.16, 0.3, 12), CharParts.mat(Color("c97b55"), 0.008), Vector3(0, 0.15, 0))
			for i in 6:
				var lf := CharParts.add(_visual, CharParts.sphere_mesh(0.5, 8), CharParts.mat(c, 0.008), Vector3(cos(i) * 0.15, 0.45, sin(i) * 0.15))
				lf.basis = Basis.from_euler(Vector3(0.6, i, 0)) * Basis.from_scale(Vector3(0.12, 0.4, 0.05))
		"decor_picture":
			CharParts.add(_visual, CharParts.box_mesh(Vector3(0.95, 0.75, 0.05)), CharParts.mat(EnvKit.WOOD, 0.008), Vector3(0, 1.5, 0))
			var tex = load("res://assets/characters/portraits/couple_dayout.png")
			var q := QuadMesh.new(); q.size = Vector2(0.82, 0.62)
			var m := StandardMaterial3D.new()
			m.albedo_texture = tex
			m.albedo_color = Color.WHITE
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			CharParts.add(_visual, q, m, Vector3(0, 1.5, 0.03))
		"decor_stool":
			CharParts.add(_visual, CharParts.cyl_mesh(0.1, 0.13, 0.4, 10), CharParts.mat(Color("f3ead8"), 0.008), Vector3(0, 0.2, 0))
			CharParts.sphere(_visual, 0.28, c, Vector3(0, 0.45, 0), Vector3(1, 0.45, 1), 0.01)
			for i in 4:
				CharParts.sphere(_visual, 0.05, Color.WHITE, Vector3(cos(i * 1.7) * 0.16, 0.55, sin(i * 1.7) * 0.16), Vector3(1, 0.4, 1), 0.0)
		"decor_flowerpot":
			CharParts.add(_visual, CharParts.box_mesh(Vector3(0.7, 0.2, 0.25)), CharParts.mat(Color("c97b55"), 0.008), Vector3(0, 0.1, 0))
			for i in 6:
				CharParts.sphere(_visual, 0.07, c if i % 2 else Color("fbe6ef"), Vector3(-0.25 + i * 0.1, 0.28, 0), Vector3.ONE, 0.006)
		"decor_basket":
			CharParts.add(_visual, CharParts.cyl_mesh(0.3, 0.22, 0.25, 14), CharParts.mat(c, 0.008), Vector3(0, 0.125, 0))
			for i in 5:
				CharParts.sphere(_visual, 0.08, [Color("f4a12a"), Color("d8344a"), Color("f2d84b")][i % 3], Vector3(cos(i * 1.3) * 0.13, 0.28, sin(i * 1.3) * 0.13), Vector3.ONE, 0.006)
		"decor_teapot":
			CharParts.sphere(_visual, 0.16, c, Vector3(0, 0.16, 0), Vector3(1, 0.85, 1), 0.008)
			CharParts.add(_visual, CharParts.cyl_mesh(0.02, 0.035, 0.18, 6), CharParts.mat(c, 0.006), Vector3(0.17, 0.2, 0), Vector3(0, 0, -50))
			CharParts.sphere(_visual, 0.04, c.darkened(0.2), Vector3(0, 0.31, 0), Vector3.ONE, 0.006)
		"decor_lantern":
			CharParts.add(_visual, CharParts.cyl_mesh(0.01, 0.01, 0.6, 4), CharParts.mat(Color("3b2a1e")), Vector3(0, 1.9, 0))
			var lan := CharParts.sphere(_visual, 0.2, c, Vector3(0, 1.5, 0), Vector3(1, 1.2, 1), 0.008)
			lan.material_override = CharParts.mat(c, 0.008, 1.4)
		"key_leaf_charm", "key_guardian_token":
			CharParts.add(_visual, CharParts.cyl_mesh(0.15, 0.18, 0.12, 12), CharParts.mat(EnvKit.WOOD_LIGHT, 0.008), Vector3(0, 0.06, 0))
			var k := CharParts.sphere(_visual, 0.12, c, Vector3(0, 0.3, 0), Vector3(1, 1.3, 0.3), 0.008)
			k.material_override = CharParts.mat(c, 0.008, 0.4)
		_:
			CharParts.sphere(_visual, 0.15, c, Vector3(0, 0.2, 0), Vector3.ONE, 0.008)
