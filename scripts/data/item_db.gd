class_name ItemDB
extends RefCounted
## Stable, data-driven item definitions (GDD §11 / §16 ItemDefinition contract).
## Gameplay code always uses the id (e.g. "item_mango"), never the display name.
## Values are the GDD's initial tuning hypotheses.

const CATEGORIES := ["fruit", "flower", "fish", "crop", "animal", "seed", "material", "decor", "keepsake"]

const ITEMS := {
	# --- Forage -----------------------------------------------------------------------------
	"item_berry": {"name": "Cherry Berry", "cat": "fruit", "sell": 2, "buy": 0, "stack": 99, "color": "#D8344A",
		"desc": "A plump, sweet berry from the Berry Maze. A tutorial favourite.", "tags": ["food", "gift"]},
	"item_starberry": {"name": "Starberry", "cat": "fruit", "sell": 9, "buy": 0, "stack": 99, "color": "#F2C230",
		"desc": "A rare golden berry that only grows in a hidden corner of the maze.", "tags": ["food", "rare"]},
	"item_mango": {"name": "Mango", "cat": "fruit", "sell": 5, "buy": 0, "stack": 99, "color": "#F4A12A",
		"desc": "Sun-warm mango from the Tropical Fruit Forest. The tree regrows fruit.", "tags": ["food", "gift"]},
	"item_banana": {"name": "Banana", "cat": "fruit", "sell": 4, "buy": 0, "stack": 99, "color": "#F2D84B",
		"desc": "A soft, sweet banana bunch.", "tags": ["food"]},
	"item_coconut": {"name": "Coconut", "cat": "fruit", "sell": 6, "buy": 0, "stack": 99, "color": "#8B5E3C",
		"desc": "Heavy, hairy and full of cool coconut water.", "tags": ["food"]},
	"item_flower": {"name": "Garden Daisy", "cat": "flower", "sell": 2, "buy": 0, "stack": 99, "color": "#F7E9F0",
		"desc": "A cheerful daisy. Sellable, or keep it for a request.", "tags": ["gift", "decor"]},
	"item_moonbell": {"name": "Moonbell", "cat": "flower", "sell": 6, "buy": 0, "stack": 99, "color": "#6F8FE8",
		"desc": "A rare blue bell-flower that glows faintly at dusk.", "tags": ["rare", "gift"]},
	# --- Fish -------------------------------------------------------------------------------
	"fish_minnow": {"name": "Pebble Minnow", "cat": "fish", "sell": 6, "buy": 0, "stack": 99, "color": "#9FB8C4",
		"desc": "A small, quick fish that loves pebbly shallows.", "tags": ["fish"]},
	"fish_carp": {"name": "Sun Carp", "cat": "fish", "sell": 7, "buy": 0, "stack": 99, "color": "#E7A04B",
		"desc": "A golden carp that basks near lily pads.", "tags": ["fish"]},
	"fish_trout": {"name": "Falls Trout", "cat": "fish", "sell": 10, "buy": 0, "stack": 99, "color": "#7FA36A",
		"desc": "Lives in the cool water under the waterfall.", "tags": ["fish"]},
	"fish_koi": {"name": "Lantern Koi", "cat": "fish", "sell": 14, "buy": 0, "stack": 99, "color": "#F06B4F",
		"desc": "A rare koi with a glowing tail. Locals say it brings good harvests.", "tags": ["fish", "rare"]},
	# --- Animal -----------------------------------------------------------------------------
	"item_egg": {"name": "Fresh Egg", "cat": "animal", "sell": 3, "buy": 0, "stack": 99, "color": "#F6EBD7",
		"desc": "Laid by a happy, well-fed chicken.", "tags": ["food"]},
	"item_feed": {"name": "Hay & Grain", "cat": "material", "sell": 0, "buy": 0, "stack": 99, "color": "#D9B85C",
		"desc": "Animal feed from Thronn's feed bin. Cows and sheep enjoy hay; chickens peck the grain.",
		"tags": ["feed"], "no_sell": true},
	# --- Crops ------------------------------------------------------------------------------
	"item_rice": {"name": "Rice Bundle", "cat": "crop", "sell": 4, "buy": 0, "stack": 99, "color": "#E8D58A",
		"desc": "A neat bundle of paddy rice.", "tags": ["food"]},
	"item_lettuce": {"name": "Leafy Greens", "cat": "crop", "sell": 4, "buy": 0, "stack": 99, "color": "#7CC461",
		"desc": "Crisp leafy greens.", "tags": ["food"]},
	"item_tomato": {"name": "Tomato", "cat": "crop", "sell": 5, "buy": 0, "stack": 99, "color": "#E0473A",
		"desc": "Glossy and red.", "tags": ["food"]},
	"item_carrot": {"name": "Carrot", "cat": "crop", "sell": 4, "buy": 0, "stack": 99, "color": "#F08A2C",
		"desc": "A crunchy root crop.", "tags": ["food"]},
	"item_sunflower": {"name": "Sunflower", "cat": "crop", "sell": 5, "buy": 0, "stack": 99, "color": "#F5C531",
		"desc": "A tall flower crop. The market loves them.", "tags": ["decor", "gift"]},
	# --- Seeds ------------------------------------------------------------------------------
	"seed_rice": {"name": "Rice Seedlings", "cat": "seed", "sell": 1, "buy": 2, "stack": 99, "color": "#C9D98A",
		"desc": "Plant in a paddy plot. Matures in 2 watered days.", "tags": ["plantable"], "crop": "rice"},
	"seed_lettuce": {"name": "Greens Seeds", "cat": "seed", "sell": 1, "buy": 3, "stack": 99, "color": "#9BD27E",
		"desc": "Matures in 2 watered days.", "tags": ["plantable"], "crop": "lettuce"},
	"seed_tomato": {"name": "Tomato Seeds", "cat": "seed", "sell": 1, "buy": 4, "stack": 99, "color": "#EE8A7E",
		"desc": "Matures in 3 watered days, yields 2.", "tags": ["plantable"], "crop": "tomato"},
	"seed_carrot": {"name": "Carrot Seeds", "cat": "seed", "sell": 1, "buy": 3, "stack": 99, "color": "#F4B37A",
		"desc": "Matures in 2 watered days.", "tags": ["plantable"], "crop": "carrot"},
	"seed_sunflower": {"name": "Sunflower Seeds", "cat": "seed", "sell": 1, "buy": 4, "stack": 99, "color": "#F7DD7A",
		"desc": "Matures in 3 watered days.", "tags": ["plantable"], "crop": "sunflower"},
	# --- Materials --------------------------------------------------------------------------
	"item_plank": {"name": "Timber Plank", "cat": "material", "sell": 1, "buy": 4, "stack": 99, "color": "#B07F52",
		"desc": "Sturdy plank for community repairs.", "tags": ["repair"]},
	# --- Decor (unique) ---------------------------------------------------------------------
	"decor_rug": {"name": "Woven Leaf Rug", "cat": "decor", "sell": 0, "buy": 10, "stack": 1, "color": "#E77F6E",
		"desc": "A round woven rug for the living room.", "tags": ["decor"], "no_sell": true},
	"decor_lamp": {"name": "Acorn Lamp", "cat": "decor", "sell": 0, "buy": 12, "stack": 1, "color": "#E4B96B",
		"desc": "A warm glowing lamp shaped like an acorn.", "tags": ["decor"], "no_sell": true},
	"decor_plant": {"name": "Potted Fern", "cat": "decor", "sell": 0, "buy": 8, "stack": 1, "color": "#5FA36B",
		"desc": "A happy fern for the balcony.", "tags": ["decor"], "no_sell": true},
	"decor_picture": {"name": "Our Picture", "cat": "decor", "sell": 0, "buy": 15, "stack": 1, "color": "#F4A6B8",
		"desc": "A framed picture of Mnki and Swan on a day out.", "tags": ["decor"], "no_sell": true},
	"decor_stool": {"name": "Mushroom Stool", "cat": "decor", "sell": 0, "buy": 9, "stack": 1, "color": "#D9534F",
		"desc": "A cosy red mushroom stool.", "tags": ["decor"], "no_sell": true},
	"decor_flowerpot": {"name": "Window Flowerpot", "cat": "decor", "sell": 0, "buy": 8, "stack": 1, "color": "#F2A3C0",
		"desc": "Pink blossoms for the windowsill.", "tags": ["decor"], "no_sell": true},
	"decor_basket": {"name": "Fruit Basket", "cat": "decor", "sell": 0, "buy": 10, "stack": 1, "color": "#C79A5B",
		"desc": "A woven basket that keeps the kitchen corner cheerful.", "tags": ["decor"], "no_sell": true},
	"decor_teapot": {"name": "Blue Teapot", "cat": "decor", "sell": 0, "buy": 11, "stack": 1, "color": "#78C9D4",
		"desc": "A kitchen detail for slow mornings.", "tags": ["decor"], "no_sell": true},
	"decor_lantern": {"name": "Paper Lantern", "cat": "decor", "sell": 0, "buy": 0, "stack": 1, "color": "#F3D27A",
		"desc": "Ivo's handmade lantern. A thank-you gift.", "tags": ["decor"], "no_sell": true},
	# --- Keepsakes (unique, quest/story) ----------------------------------------------------
	"key_windchime": {"name": "Pip's Wind Chime", "cat": "keepsake", "sell": 0, "buy": 0, "stack": 1, "color": "#A7D7E0",
		"desc": "A little shell wind chime lost in the Tropical Fruit Forest.", "tags": ["quest_protected"], "no_sell": true},
	"key_leaf_charm": {"name": "Leaf Charm", "cat": "keepsake", "sell": 0, "buy": 0, "stack": 1, "color": "#7BBF6A",
		"desc": "Elder Maple's thank-you charm. Display it at home.", "tags": ["keepsake"], "no_sell": true},
	"key_guardian_token": {"name": "Guardian Token", "cat": "keepsake", "sell": 0, "buy": 0, "stack": 1, "color": "#B9C4CF",
		"desc": "Three tiny symbols: Land, Water, Forest. A reminder to care for all three.", "tags": ["keepsake"], "no_sell": true},
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


static func get_def(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "cat": "material", "sell": 0, "buy": 0, "stack": 99, "color": "#999999", "desc": "Unknown item", "tags": []})


static func display_name(id: String) -> String:
	return String(get_def(id).get("name", id))


static func color_of(id: String) -> Color:
	return Color(String(get_def(id).get("color", "#999999")))


static func sell_value(id: String) -> int:
	return int(get_def(id).get("sell", 0))


static func buy_value(id: String) -> int:
	return int(get_def(id).get("buy", 0))


static func can_sell(id: String) -> bool:
	var d := get_def(id)
	return not d.get("no_sell", false) and int(d.get("sell", 0)) > 0


static func stack_limit(id: String) -> int:
	return int(get_def(id).get("stack", 99))


static func category(id: String) -> String:
	return String(get_def(id).get("cat", "material"))


static func is_seed(id: String) -> bool:
	return category(id) == "seed"


static func seed_crop(id: String) -> String:
	return String(get_def(id).get("crop", ""))
