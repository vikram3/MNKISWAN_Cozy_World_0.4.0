class_name DailyLifeData
extends RefCounted
const RESIDENTS := {
	"poppy": {"name": "Poppy", "role": "Child · playground explorer", "age": "child", "scale": 0.73, "skin": "e8b996", "hair": "70422f", "top": "f0b262", "bottom": "698e9c", "hat": "sunhat", "accent": "f4dfae", "idle": ["Finn says the clouds are sheep. I think they're sleepy dragons!", "Would you two play catch with us?"]},
	"finn": {"name": "Finn", "role": "Child · ball-game champion", "age": "child", "scale": 0.76, "skin": "b9825e", "hair": "302c28", "top": "78bdc9", "bottom": "5b6a8a", "hat": "none", "accent": "efc879", "idle": ["The rule is: everyone gets a turn!", "Poppy is better at catching. I'm better at cheering."]},
	"pearl": {"name": "Pearl", "role": "Retired gardener", "age": "elder", "skin": "d7a47e", "hair": "e6e2d8", "top": "aa8db8", "bottom": "6f697e", "hat": "sunhat", "accent": "d6b2c7", "idle": ["We used to hurry everywhere. These days we let the afternoon come to us.", "Love gets quieter with the years, but it needn't grow smaller."]},
	"rowan": {"name": "Rowan", "role": "Retired carpenter", "age": "elder", "skin": "b9825e", "hair": "c8c6be", "top": "8eaa84", "bottom": "70614f", "hat": "none", "accent": "dfbf84", "idle": ["I made this bench. Pearl made it my favourite place.", "A good life leaves room for other people's stories."]},
	"nila": {"name": "Nila", "role": "Weaver · Arun's partner", "skin": "b9825e", "hair": "382a24", "top": "c58fa8", "bottom": "716783", "hat": "scarf", "accent": "e6bcc9", "idle": ["Arun leaves a flower on my workbench. Even on ordinary Tuesdays.", "We don't agree about everything. We do keep listening."]},
	"arun": {"name": "Arun", "role": "Potter · Nila's partner", "skin": "dfac86", "hair": "65432e", "top": "83aaa6", "bottom": "70604a", "hat": "beret", "accent": "e6c18b", "idle": ["Nila says my cups are crooked. Somehow hers is always the crookedest one.", "A walk together is a very good use of an evening."]},
	"sumi": {"name": "Sumi", "role": "Field worker", "skin": "d7a47e", "hair": "302b24", "top": "a4b879", "bottom": "6a7251", "hat": "conical", "accent": "d6b778", "idle": ["Bao minds the young plants; I look after the field edges.", "We finish before the evening cool. Rested hands work gently."]},
	"ren": {"name": "Ren", "role": "Orchard worker", "skin": "c88a64", "hair": "443227", "top": "e2ab69", "bottom": "6f7855", "hat": "straw", "accent": "e8cf8d", "idle": ["The orchard has enough for the birds and us.", "After work I like a warm meal at the lantern market."]},
}

static func market_open(hour: int) -> bool:
	return hour >= 18 and hour < 24

static func public_summary(hour: int) -> String:
	if hour < 6: return "The village is sleeping · Your time together is still yours"
	if hour < 8: return "A slow morning · Neighbours are waking up"
	if hour < 12: return "Fields at work · Children at play · Park benches in the sun"
	if hour < 14: return "Lunch and a little rest · No need to hurry"
	if hour < 18: return "Garden walks · Afternoon work · Time for each other"
	if hour < 21: return "Lantern market open until midnight · Supper and music"
	return "Lantern market open · Most neighbours are heading home"
