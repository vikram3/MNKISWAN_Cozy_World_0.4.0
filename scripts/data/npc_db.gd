class_name NpcDB
extends RefCounted
## Supporting cast (GDD §6). Names other than Thronn are working labels.
## Visuals are intentionally distinct from Mnki & Swan so the duo stays the visual focus.

const NPCS := {
	"swan": {"name": "Swan", "role": "Swan Princess", "portrait": "res://assets/characters/portraits/swan_happy.png"},
	"mnki": {"name": "Mnki", "role": "Monkey King", "portrait": "res://assets/characters/portraits/mnki_happy.png"},
	"thronn": {"name": "Thronn", "role": "Best friend · Animal farm", "skin": "#D9A27C", "hair": "#2F2A26", "top": "#6FA35A", "bottom": "#7A5A3A", "hat": "straw", "accent": "#E4B96B",
		"idle": ["The animals were asking about you two. Well — the chicken was.", "Hold your hand low and still. Animals trust slow hands.", "Whenever you have time, the sheep love a good brushing."]},
	"elder": {"name": "Elder Maple", "role": "Village Elder", "skin": "#C98E6B", "hair": "#E8E4DC", "top": "#8E6FB0", "bottom": "#5E4B7A", "hat": "none", "accent": "#E4B96B", "scale": 0.95,
		"idle": ["Small acts of care add up to a village.", "The Guardians never asked for much. Just attention.", "Sit a while. The benches were built for it."]},
	"rosa": {"name": "Rosa", "role": "Gardener", "skin": "#E8B996", "hair": "#B5532E", "top": "#E77F6E", "bottom": "#5B8C55", "hat": "sunhat", "accent": "#F7E9F0",
		"idle": ["Daisies are honest flowers. They grow where they're welcome.", "Watch the colours — balance matters in a bed."]},
	"ivo": {"name": "Ivo", "role": "Gardener", "skin": "#B9825E", "hair": "#1F1A17", "top": "#6F8FE8", "bottom": "#3D4E73", "hat": "beret", "accent": "#F2C230",
		"idle": ["What if a flower bed had no rules at all?", "I keep hearing about a blue bell that glows at dusk."]},
	"bao": {"name": "Bao", "role": "Rice farmer", "skin": "#D7A47E", "hair": "#2B2B2B", "top": "#C9D98A", "bottom": "#5C6B3A", "hat": "conical", "accent": "#8B6749",
		"idle": ["Plant, water, wait. The soil keeps its own calendar.", "A watered plot grows a stage each morning. Simple as that."]},
	"lumi": {"name": "Lumi", "role": "Fisher", "skin": "#EFC7A8", "hair": "#4C6A7A", "top": "#78C9D4", "bottom": "#2F4F5F", "hat": "bucket", "accent": "#F3D27A",
		"idle": ["...", "The pond is quiet today. Good.", "Watch the bobber, not the sky."]},
	"tamsin": {"name": "Tamsin", "role": "Market grocer", "skin": "#C88A64", "hair": "#6B3A2A", "top": "#F2D84B", "bottom": "#8B6749", "hat": "bandana", "accent": "#E77F6E",
		"idle": ["Fair prices, fresh produce. That's the whole secret.", "Seeds are on the left crate. Planting season is every season here!"]},
	"odo": {"name": "Odo", "role": "Decor vendor", "skin": "#A86E4C", "hair": "#C9C2B8", "top": "#B07F52", "bottom": "#4E3B2A", "hat": "none", "accent": "#78C9D4",
		"idle": ["Every home deserves one thing that makes you smile.", "Planks for repairs, lamps for evenings. I stock what matters."]},
	"pip": {"name": "Pip", "role": "Colony 1 resident", "skin": "#F0C9A8", "hair": "#E1A23B", "top": "#A7D7E0", "bottom": "#5F7A8A", "hat": "none", "accent": "#F7E9F0", "scale": 0.85,
		"idle": ["The lanterns here are lit every evening. I help!", "Thank you for finding my chime. Listen — it's singing."]},
	"mira": {"name": "Mira", "role": "Colony 2 resident", "skin": "#B5835F", "hair": "#3A2A22", "top": "#D9A25F", "bottom": "#6B4E36", "hat": "scarf", "accent": "#5FA36B",
		"idle": ["Up here the wind tells stories.", "Have you looked closely at the statues? The water one is smiling."]},
}

static func get_def(id: String) -> Dictionary:
	if DailyLifeData.RESIDENTS.has(id):
		return DailyLifeData.RESIDENTS[id]
	var host := VillageLifeData.host_def(id)
	if not host.is_empty():
		return host
	return NPCS.get(id, {"name": id, "role": "", "idle": ["Hello!"]})


static func display_name(id: String) -> String:
	return String(get_def(id).get("name", id))
