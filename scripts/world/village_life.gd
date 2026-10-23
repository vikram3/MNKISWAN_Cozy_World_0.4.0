class_name VillageLife
extends Node3D
## Thirteen authored social pockets, 39 activities, and thirteen additional residents.
var places: Dictionary = {}

func _ready() -> void:
	name = "VillageLife"
	var world := get_parent()
	var index := 0
	for region_id in VillageLifeData.PLACES:
		var data: Array = VillageLifeData.PLACES[region_id]
		var region: RegionBase = world.regions[region_id]
		var place := Node3D.new()
		place.name = "Gathering_" + region_id
		place.position = data[0]
		region.add_child(place)
		places[region_id] = place
		var tint := Color(String(data[1]))
		VillageDecor.landscape(region, tint)
		VillageDecor.gathering_place(place, tint, index)
		for i in 3:
			var activity := CozyActivity.new().setup(region_id, i, data[5][i], tint)
			activity.position = Vector3(-1.65 + i * 1.65, 0.09, -0.55)
			place.add_child(activity)
		var p: Vector3 = data[0]
		var npc := region.add_npc(VillageLifeData.host_id(region_id), [[5, p + Vector3(-1.5, 0, 2.4)], [11, p + Vector3(0, 0, 2.5)], [17, p + Vector3(1.5, 0, 2.4)]])
		npc.add_to_group("village_host")
		npc.home_region = region_id
		index += 1
	add_child(VillageAtmosphere.new())
