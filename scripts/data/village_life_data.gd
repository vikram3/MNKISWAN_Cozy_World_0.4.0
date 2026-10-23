class_name VillageLifeData
extends RefCounted
## Authored gathering places: position, palette, host, three activities.
## Activity: prop type, invitation, completion, thought for the shared journal.
const PLACES := {
	"sunshine_forest": [Vector3(-6, 0, 6), "edb66b", "Fern", "Bird keeper", "straw", [
		["feeder", "Fill the woodland bird feeder", "Seeds are ready for the woodland birds.", "Gentleness is a language every creature understands."],
		["tea", "Share a forest picnic", "Two warm cups, and nowhere to hurry.", "Time spent together is never wasted."],
		["chime", "Play the woodland wind chimes", "A little melody drifts between the trees.", "Leave room in your day for something that cannot be measured."]]],
	"waterfall_ponds": [Vector3(6.5, 0, 8), "87cdd1", "Nori", "Pond caretaker", "bucket", [
		["water", "Refresh the water garden", "Fresh water sparkles around the lilies.", "A still moment can change the rest of a day."],
		["flower", "Tend the riverside blossoms", "The riverside flowers stand a little taller.", "Growth is often quiet."],
		["chime", "Play a melody for the falls", "The water keeps its own rhythm beneath your tune.", "Listening is a kind of love."]]],
	"berry_maze": [Vector3(13, 0, 0), "ce7b9b", "Bram", "Jam maker", "bandana", [
		["basket", "Arrange berries for the neighbours", "A bright basket is ready to share.", "The sweetest harvest is the one you share."],
		["tea", "Taste Bram's berry tea", "Warm berry tea turns your cheeks pink.", "Even a wrong turn can lead to a lovely afternoon."],
		["chime", "Ring the maze welcome bell", "A friendly bell guides wanderers toward the tea table.", "Being lost is easier with someone beside you."]]],
	"flower_garden": [Vector3(-7, 0, 9), "eaa6bb", "Dahlia", "Florist", "sunhat", [
		["flower", "Water the friendship planter", "Fresh blossoms unfurl in the friendship planter.", "Love grows through ordinary acts of care."],
		["basket", "Arrange a gift bouquet", "A bouquet is waiting for someone who needs a smile.", "You do not need a special occasion to be kind."],
		["tea", "Share rose-petal tea", "The garden smells of roses and warm tea.", "Beauty becomes a memory when it is shared."]]],
	"paddy_field": [Vector3(-8, 0, 4), "b7cb77", "Reed", "Irrigation helper", "conical", [
		["water", "Turn the demonstration waterwheel", "The wheel carries fresh water into its basin.", "Patient effort moves more than hurried worry."],
		["basket", "Bundle rice for the community", "Neat bundles wait for the community kitchen.", "Many small hands can feed a village."],
		["flower", "Tend the pollinator planter", "The little flowers welcome the field's smallest helpers.", "No useful kindness is too small."]]],
	"tropical_forest": [Vector3(0, 0, -5.5), "f0b66b", "Kavi", "Orchard cook", "bandana", [
		["basket", "Arrange the orchard tasting basket", "Mangoes and bananas make a cheerful display.", "Abundance feels better when everyone has a place at the table."],
		["tea", "Make a mango cooler for two", "Two golden drinks cool a warm afternoon.", "Rest is part of the journey."],
		["feeder", "Refill the orchard bird feeder", "The orchard's feathered neighbours have a feast.", "Care for the place that cares for you."]]],
	"animal_farm": [Vector3(-9, 0, 6), "d4b489", "Clover", "Animal helper", "straw", [
		["water", "Fill the little drinking trough", "Clean water is ready for thirsty visitors.", "Trust begins with showing up."],
		["basket", "Prepare a basket of soft hay", "Soft hay is ready for the evening beds.", "A home is made of a thousand small comforts."],
		["feeder", "Top up the songbird feeder", "A few seeds make the farm a friendlier place.", "Give without keeping score."]]],
	"guardian_gate": [Vector3(-6, 0, -7), "bca8ce", "Sage", "Story keeper", "scarf", [
		["lantern", "Light a lantern of gratitude", "A warm lantern glows for someone you appreciate.", "Gratitude notices what hurry forgets."],
		["flower", "Tend the guardian's flowers", "Fresh flowers soften the old stones.", "Strength and gentleness can live in the same heart."],
		["chime", "Play the three notes of welcome", "Three gentle notes welcome the next traveller.", "Wisdom leaves the door open."]]],
	"village_park": [Vector3(-10, 0, 0), "a6cba5", "Juniper", "Village musician", "beret", [
		["chime", "Play the park's melody", "A cheerful melody floats through the park.", "Joy grows when it has somewhere to gather."],
		["tea", "Share a quiet park picnic", "You make a little room for a peaceful afternoon.", "You are allowed to enjoy a day without earning it."],
		["flower", "Water the welcome flowers", "The welcome flowers brighten the park path.", "Make the world softer where you can."]]],
	"treehouse": [Vector3(7, 0, 0), "e9b4a1", "Hazel", "Neighbourhood baker", "bandana", [
		["tea", "Brew tea for Mnki and Swan", "Two cups wait outside your home.", "Home is also the person who saves you a seat."],
		["lantern", "Light the homecoming lantern", "A warm light will welcome you home.", "Let the people you love know they are welcome."],
		["flower", "Water your doorstep flowers", "The doorstep looks a little more like home.", "Love lives in the things we remember to do."]]],
	"colony_one": [Vector3(9, 0, -9), "e3bd73", "Wren", "Lantern maker", "beret", [
		["lantern", "Light the neighbour's lantern", "Another warm light joins Lantern Lane.", "One light can make a dark walk feel less lonely."],
		["basket", "Leave a neighbourly gift basket", "A small gift waits for a neighbour.", "Community begins with a simple hello."],
		["chime", "Try Wren's handmade chimes", "The new chimes answer the breeze.", "Things made with care carry a little of their maker."]]],
	"colony_two": [Vector3(7, 0, 5), "9fb9d6", "Aster", "Night-sky storyteller", "scarf", [
		["lantern", "Light the stargazer's lantern", "A soft lantern marks a quiet place to watch the sky.", "You can be small and still belong to something wonderful."],
		["tea", "Share a stargazer's tea", "You leave two cups beneath the open sky.", "There is room for dreams that take their time."],
		["chime", "Play a lullaby for the treetops", "A slow melody climbs toward the treetops.", "Tomorrow can wait until tomorrow."]]],
	"market_square": [Vector3(0, 0, 8.5), "e99c85", "Marigold", "Community host", "sunhat", [
		["basket", "Arrange the sharing table", "A colourful basket welcomes the next visitor.", "Enough for everyone begins with a little generosity."],
		["tea", "Share the market's daily tea", "Two cups and a friendly pause between errands.", "A busy day still has room for tenderness."],
		["flower", "Freshen the market flowers", "The market has a fresh splash of colour.", "Ordinary places deserve beautiful moments."]]],
}

static func host_id(region: String) -> String:
	return "life_" + region

static func host_def(id: String) -> Dictionary:
	for region in PLACES:
		if id == host_id(region):
			var p: Array = PLACES[region]
			var index := PLACES.keys().find(region)
			return {"name": p[2], "role": p[3], "hat": p[4], "top": p[1], "accent": "f5dfad",
				"skin": ["d9a27c", "efc7a8", "b9825e"][index % 3], "hair": ["53372d", "b97443", "303d38"][index % 3],
				"bottom": "5d7161", "idle": ["Come try our little gathering place. Everything here is for sharing.",
				String(p[5][index % 3][3]), "Each little activity earns two thank-you coins once a day. You can enjoy it again any time."]}
	return {}
