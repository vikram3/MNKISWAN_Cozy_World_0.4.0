class_name GameData
extends RefCounted
## Data tables: crops, fish, regions, shop upgrades/offers, animals.
## Kept in one place so designers can tune without touching system code.

# --- Crops (GDD §9.4 CropDefinition) -----------------------------------------------------------
const CROPS := {
	"rice": {"name": "Rice", "seed": "seed_rice", "harvest": "item_rice", "days": 2, "yield": 2, "color": "#E8D58A", "leaf": "#8CC96B"},
	"lettuce": {"name": "Leafy Greens", "seed": "seed_lettuce", "harvest": "item_lettuce", "days": 2, "yield": 1, "color": "#7CC461", "leaf": "#5DAF4A"},
	"tomato": {"name": "Tomato", "seed": "seed_tomato", "harvest": "item_tomato", "days": 3, "yield": 2, "color": "#E0473A", "leaf": "#4F9E45"},
	"carrot": {"name": "Carrot", "seed": "seed_carrot", "harvest": "item_carrot", "days": 2, "yield": 2, "color": "#F08A2C", "leaf": "#62B04F"},
	"sunflower": {"name": "Sunflower", "seed": "seed_sunflower", "harvest": "item_sunflower", "days": 3, "yield": 1, "color": "#F5C531", "leaf": "#5AA448"},
}

# --- Fish tables per fishing spot (weights) ----------------------------------------------------
const FISH_TABLES := {
	"pond": [["fish_minnow", 50], ["fish_carp", 40], ["fish_koi", 10]],
	"falls": [["fish_trout", 55], ["fish_minnow", 30], ["fish_koi", 15]],
	"garden_pond": [["fish_carp", 70], ["fish_minnow", 30]],
}

# --- Regions (GDD §7) — centres used by world build, map and discovery ------------------------
const REGIONS := {
	"sunshine_forest": {"num": 1, "name": "Sunshine Forest", "pos": Vector2(-38, -84), "size": Vector2(30, 24), "color": "#9ED36A",
		"desc": "Starting clearing. Flowers, berries and butterflies."},
	"waterfall_ponds": {"num": 2, "name": "Waterfall & Ponds", "pos": Vector2(38, -84), "size": Vector2(32, 26), "color": "#78C9D4",
		"desc": "Fishing banks, lily pads and the old timber bridge."},
	"berry_maze": {"num": 3, "name": "Cherry Berry Maze", "pos": Vector2(38, -56), "size": Vector2(24, 22), "color": "#D8344A",
		"desc": "Waist-high hedges and berry bushes."},
	"flower_garden": {"num": 4, "name": "Village Flower Garden", "pos": Vector2(38, -28), "size": Vector2(26, 22), "color": "#F2A3C0",
		"desc": "Flower beds, a trellis and two gardeners."},
	"paddy_field": {"num": 5, "name": "Paddy Field & Farm", "pos": Vector2(38, 30), "size": Vector2(28, 24), "color": "#C9D98A",
		"desc": "Crop plots, water channels and Bao's shed."},
	"tropical_forest": {"num": 6, "name": "Tropical Fruit Forest", "pos": Vector2(38, 60), "size": Vector2(28, 24), "color": "#F4A12A",
		"desc": "Mango, banana and coconut trees."},
	"animal_farm": {"num": 7, "name": "Animal Farm & Thronn's Treehouse", "pos": Vector2(0, 92), "size": Vector2(34, 24), "color": "#C0874F",
		"desc": "Barn, paddock and Thronn's home."},
	"guardian_gate": {"num": 8, "name": "Three Guardian Statues", "pos": Vector2(-38, -56), "size": Vector2(22, 18), "color": "#B9C4CF",
		"desc": "Land, Water and Forest watch the village gate."},
	"village_park": {"num": 9, "name": "Village Garden & Park", "pos": Vector2(-38, -28), "size": Vector2(28, 24), "color": "#8FCB7A",
		"desc": "The social heart: elder's home, old tree, community board."},
	"treehouse": {"num": 10, "name": "Mnki & Swan's Treehouse", "pos": Vector2(-38, 0), "size": Vector2(24, 22), "color": "#8B6749",
		"desc": "Home. Rest, store, decorate."},
	"colony_one": {"num": 11, "name": "Tree People Colony 1", "pos": Vector2(-38, 30), "size": Vector2(24, 22), "color": "#E4B96B",
		"desc": "A cosy lane of lantern-lit tree homes."},
	"colony_two": {"num": 12, "name": "Tree People Colony 2", "pos": Vector2(-38, 60), "size": Vector2(24, 22), "color": "#B3A06A",
		"desc": "Tall tree architecture and rope bridges."},
	"market_square": {"num": 13, "name": "Market Square & Fruit Stall", "pos": Vector2(38, 0), "size": Vector2(28, 24), "color": "#E77F6E",
		"desc": "Mnki & Swan's fruit stall, the grocer and the decor vendor."},
}

## Path network (schematic from GDD §7).
const PATHS := [
	["sunshine_forest", "waterfall_ponds"],
	["sunshine_forest", "guardian_gate"],
	["waterfall_ponds", "berry_maze"],
	["guardian_gate", "village_park"],
	["berry_maze", "flower_garden"],
	["village_park", "flower_garden"],
	["village_park", "treehouse"],
	["flower_garden", "market_square"],
	["treehouse", "market_square"],
	["treehouse", "colony_one"],
	["market_square", "paddy_field"],
	["colony_one", "colony_two"],
	["paddy_field", "tropical_forest"],
	["tropical_forest", "animal_farm"],
	["colony_two", "animal_farm"],
]

# --- Stall upgrades (GDD §9.7: visible; unlock order capacity/products, no hidden multipliers) --
const STALL_UPGRADES := [
	{"level": 1, "name": "Extra Shelf & Order Board", "cost": 50, "desc": "A second shelf and an order board: take 2 market orders a day."},
	{"level": 2, "name": "Striped Awning & Flower Bucket", "cost": 120, "desc": "Shade for the fruit and a flower bucket: 3 orders a day, flowers & crops featured in orders."},
	{"level": 3, "name": "Fruit Display Tower & Sign", "cost": 220, "desc": "A tiered display and painted sign: 4 orders a day including rare-item requests."},
]

# --- Shops -------------------------------------------------------------------------------------
const GROCER_OFFERS := ["seed_rice", "seed_lettuce", "seed_carrot", "seed_tomato", "seed_sunflower"]
const DECOR_OFFERS := ["item_plank", "decor_rug", "decor_lamp", "decor_plant", "decor_stool", "decor_flowerpot", "decor_basket", "decor_teapot", "decor_picture"]

# --- Home decoration anchors (GDD §9.8 curated anchor points) ---------------------------------
const DECOR_ANCHORS := {
	"anchor_rug": {"item": "decor_rug", "floor": 0},
	"anchor_lamp": {"item": "decor_lamp", "floor": 0},
	"anchor_stool": {"item": "decor_stool", "floor": 0},
	"anchor_basket": {"item": "decor_basket", "floor": 0},
	"anchor_plant": {"item": "decor_plant", "floor": 1},
	"anchor_picture": {"item": "decor_picture", "floor": 1},
	"anchor_flowerpot": {"item": "decor_flowerpot", "floor": 1},
	"anchor_teapot": {"item": "decor_teapot", "floor": 1},
	"anchor_lantern": {"item": "decor_lantern", "floor": 0},
	"anchor_keepsake_1": {"item": "key_leaf_charm", "floor": 0},
	"anchor_keepsake_2": {"item": "key_guardian_token", "floor": 0},
}

# --- Order pool for the market order board -----------------------------------------------------
## [items, coin_reward, min_stall_level]
const ORDER_POOL := [
	[{"item_berry": 4}, 14, 0],
	[{"item_mango": 2}, 14, 0],
	[{"item_berry": 2, "item_mango": 1}, 13, 0],
	[{"item_egg": 2}, 10, 0],
	[{"fish_minnow": 1, "item_banana": 1}, 15, 0],
	[{"item_flower": 3}, 10, 1],
	[{"item_coconut": 1, "item_banana": 2}, 19, 1],
	[{"item_rice": 2}, 12, 1],
	[{"item_tomato": 2, "item_lettuce": 1}, 20, 2],
	[{"item_sunflower": 2}, 15, 2],
	[{"item_carrot": 2, "item_egg": 1}, 16, 2],
	[{"fish_trout": 1, "item_coconut": 1}, 22, 2],
	[{"item_starberry": 1, "item_mango": 2}, 26, 3],
	[{"fish_koi": 1}, 25, 3],
	[{"item_moonbell": 1, "item_flower": 2}, 18, 3],
]

static func region_world_pos(id: String) -> Vector3:
	var r: Dictionary = REGIONS.get(id, {})
	var p: Vector2 = r.get("pos", Vector2.ZERO)
	return Vector3(p.x, 0.0, p.y)


static func roll_fish(table_id: String, rng: RandomNumberGenerator) -> String:
	var table: Array = FISH_TABLES.get(table_id, FISH_TABLES["pond"])
	var total := 0
	for e in table:
		total += int(e[1])
	var roll := rng.randi_range(1, total)
	for e in table:
		roll -= int(e[1])
		if roll <= 0:
			return String(e[0])
	return String(table[0][0])
