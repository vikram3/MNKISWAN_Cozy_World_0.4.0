extends RegionBase
## 07 Domestic Animal Farm & Thronn's Treehouse — barn, paddock, troughs, feed bin, egg nest.

const PEN_CENTER := Vector3(3, 0, 2)
const PEN_SIZE := Vector2(14, 10)


func build() -> void:
	# Barn
	var barn := EnvKit.solid_box(self, Vector3(6, 3.4, 4.5), Vector3(-10, 1.7, -4), Color("c0533f"), 0, 0.014)
	CharParts.add(barn, CharParts.cyl_mesh(0.0, 4.4, 2.0, 4), CharParts.mat(Color("7a4a3a"), 0.014), Vector3(0, 2.7, 0), Vector3(0, 45, 0), Vector3(1.0, 1.0, 0.75))
	CharParts.add(barn, CharParts.box_mesh(Vector3(2.0, 2.4, 0.05)), CharParts.mat(Color("f3ead8"), 0.008), Vector3(0, -0.5, 2.27))
	CharParts.add(barn, CharParts.box_mesh(Vector3(1.8, 0.12, 0.06)), CharParts.mat(Color("c0533f")), Vector3(0, -0.5, 2.3), Vector3(0, 0, 45))
	CharParts.add(barn, CharParts.box_mesh(Vector3(1.8, 0.12, 0.06)), CharParts.mat(Color("c0533f")), Vector3(0, -0.5, 2.3), Vector3(0, 0, -45))
	# Paddock fence with an opening facing the path (north side gap)
	var hx := PEN_SIZE.x * 0.5
	var hz := PEN_SIZE.y * 0.5
	var c := PEN_CENTER
	EnvKit.fence(self, c + Vector3(-hx, 0, -hz), c + Vector3(-1.4, 0, -hz))
	EnvKit.fence(self, c + Vector3(1.4, 0, -hz), c + Vector3(hx, 0, -hz))
	EnvKit.fence(self, c + Vector3(-hx, 0, hz), c + Vector3(hx, 0, hz))
	EnvKit.fence(self, c + Vector3(-hx, 0, -hz), c + Vector3(-hx, 0, hz))
	EnvKit.fence(self, c + Vector3(hx, 0, -hz), c + Vector3(hx, 0, hz))
	# Straw patches, troughs, coop
	for i in 5:
		EnvKit.disc(self, c + Vector3(-5 + i * 2.4, 0.03, 2.0 - (i % 2) * 3.5), 0.9, Color("e8cd7a"), 0.03)
	for p in [c + Vector3(-4.5, 0, 3.6), c + Vector3(4.0, 0, 3.6)]:
		CharParts.add(self, CharParts.box_mesh(Vector3(1.8, 0.4, 0.6)), CharParts.mat(EnvKit.WOOD, 0.01), p + Vector3(0, 0.2, 0))
		CharParts.add(self, CharParts.box_mesh(Vector3(1.6, 0.05, 0.45)), CharParts.mat(Color("e8cd7a")), p + Vector3(0, 0.38, 0))
	var coop := EnvKit.solid_box(self, Vector3(1.8, 1.2, 1.4), c + Vector3(5.2, 0.6, -3.0), Color("f3ead8"), 0, 0.01)
	CharParts.add(coop, CharParts.cyl_mesh(0.0, 1.5, 0.8, 4), CharParts.mat(EnvKit.ROOF_RED, 0.01), Vector3(0, 1.0, 0), Vector3(0, 45, 0), Vector3(1, 1, 0.8))
	# Animals (stable IDs; care state persists)
	var animals := [["cow_daisy", "cow"], ["sheep_puff", "sheep"], ["sheep_cloud", "sheep"], ["chicken_pip", "chicken"], ["chicken_dot", "chicken"], ["chicken_nugget", "chicken"]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for a in animals:
		var fa := FarmAnimal.new().setup(String(a[0]), String(a[1]), wpos(PEN_CENTER), PEN_SIZE)
		fa.name = String(a[0])
		world.npc_root.add_child(fa)
		fa.global_position = wpos(c + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
	# Feed bin by the barn
	CharParts.add(self, CharParts.cyl_mesh(0.55, 0.5, 0.9, 12), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(-6.2, 0.45, -1.2))
	CharParts.add(self, CharParts.cyl_mesh(0.5, 0.5, 0.08, 12), CharParts.mat(Color("e8cd7a")), Vector3(-6.2, 0.92, -1.2))
	var sb := EnvKit.body(self, Vector3(-6.2, 0, -1.2))
	EnvKit.add_cyl_shape(sb, 0.55, 1.0, Vector3(0, 0.5, 0))
	var feed_prompt := func(): return "Take Hay & Grain from the feed bin (have %d)" % GameState.inventory.count("item_feed")
	var feed_action := func(actor):
		var have := GameState.inventory.count("item_feed")
		if have >= 10:
			GameState.notify("You're carrying plenty of feed already.", "info")
			return
		var n: int = mini(3, 10 - have)
		if GameState.inventory.add("item_feed", n):
			AudioManager.play_sfx("pickup")
			GameState.notify("+%d Hay & Grain" % n, "item")
			if actor.has_method("play_action"):
				actor.play_action("gather", 0.5)
	add_point("feed_bin", Vector3(-6.2, 0, -1.2), feed_prompt, feed_action, Callable(), 2.0, 1.4, 1)
	# Egg nest inside the paddock
	var nest_pos := c + Vector3(3.8, 0, -3.2)
	CharParts.add(self, CharParts.torus_mesh(0.18, 0.38, 8, 16), CharParts.mat(Color("d9b85c"), 0.008), nest_pos + Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1, 1.4, 1))
	var eggs_root := Node3D.new()
	eggs_root.position = nest_pos
	add_child(eggs_root)
	var refresh_eggs := func():
		for ch in eggs_root.get_children():
			ch.queue_free()
		var n: int = int(GameState.world.get_state("nest_farm", {"eggs": 0}).eggs)
		for i in mini(n, 6):
			CharParts.sphere(eggs_root, 0.07, Color("f6ebd7"), Vector3(cos(i * 1.1) * 0.12, 0.18, sin(i * 1.1) * 0.12), Vector3(1, 1.25, 1), 0.006)
	refresh_eggs.call()
	var on_obj := func(id):
		if id == "nest_farm":
			refresh_eggs.call()
	GameState.world.object_state_changed.connect(on_obj)
	var egg_prompt := func():
		var n: int = int(GameState.world.get_state("nest_farm", {"eggs": 0}).eggs)
		if n > 0:
			return "Collect eggs (%d)" % n
		return "Egg nest - fed chickens lay eggs here overnight"
	var egg_action := func(actor):
		var st := GameState.world.get_state("nest_farm", {"eggs": 0})
		var n := int(st.eggs)
		if n <= 0:
			GameState.notify("No eggs yet. Feed a chicken today and check tomorrow.", "info")
			return
		if not GameState.inventory.add("item_egg", n):
			GameState.notify("Bag full - the eggs will wait safely in the nest.", "warn")
			return
		st.eggs = 0
		GameState.world.set_state("nest_farm", st)
		AudioManager.play_sfx("pickup")
		GameState.notify("+%d Fresh Egg" % n, "item")
		if actor.has_method("play_action"):
			actor.play_action("gather", 0.5)
	add_point("egg_nest", nest_pos, egg_prompt, egg_action, Callable(), 1.8, 0.9, 1)
	# Thronn's treehouse
	EnvKit.tree_home(self, Vector3(12, 0, -6), -30, Color("e4c99a"), Color("6fa35a"), true)
	EnvKit.sign_post(self, Vector3(-2.5, 0, -6.2), "Thronn's Farm\nBe gentle - the animals are neighbours", 0)
	var board_prompt := func(): return "Read Thronn's animal-care board"
	var board_action := func(_a):
		GameState.request_dialogue(["Board: Pet each friend once a day. Hay & Grain from the bin by the barn. Brush the cow and sheep.", "Board: Fed chickens lay eggs in the nest overnight. Nobody is ever in trouble for missing a day."])
	var board := add_point("care_board", Vector3(-3.5, 0, -8.5), board_prompt, board_action, Callable(), 2.0, 1.8)
	CharParts.add(board, CharParts.box_mesh(Vector3(1.4, 1.0, 0.08)), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(0, 1.3, 0))
	CharParts.add(board, CharParts.cyl_mesh(0.05, 0.05, 1.0, 6), CharParts.mat(EnvKit.WOOD_DARK), Vector3(0, 0.5, 0))
	for p in [Vector3(-15, 0, 8), Vector3(15, 0, 8), Vector3(-15, 0, -9)]:
		EnvKit.tree(self, p, 1.2)
	add_npc("thronn", [[5, Vector3(-3.0, 0, -4.5)], [10, Vector3(0.5, 0, -4.8)], [16, Vector3(-7.8, 0, 0.8)], [20, Vector3(9.5, 0, -2.5)]])
