class_name RegionBase
extends Node3D
## Base for the 13 region modules (GDD §7, §15 "regions/*.tscn"). Each region scene is placed at
## its schematic centre by the world and builds its own landmark, props and interactables.

@export var region_id: String = ""

var world: Node3D   # TreeVillageWorld


func setup_region(w: Node3D) -> void:
	world = w
	build()


## Override in each region.
func build() -> void:
	pass


func region_def() -> Dictionary:
	return GameData.REGIONS.get(region_id, {})


func wpos(local: Vector3) -> Vector3:
	return global_transform * local


func add_npc(id: String, sched_local: Array) -> NpcCharacter:
	var sched: Array = []
	for e in sched_local:
		sched.append([int(e[0]), wpos(e[1])])
	var npc := NpcCharacter.new().setup(id, sched)
	npc.name = "NPC_" + id
	world.npc_root.add_child(npc)
	return npc


func add_gather(id: String, kind: String, local: Vector3) -> GatherNode:
	var g := GatherNode.new().setup(id, kind)
	g.name = id
	g.position = local
	add_child(g)
	return g


func add_point(id: String, local: Vector3, prompt: Callable, action: Callable, enabled: Callable = Callable(), reach: float = 2.4, marker_h: float = 1.4, prio: int = 0) -> ActionPoint:
	var a := ActionPoint.new().configure(id, prompt, action, enabled, reach, marker_h, prio)
	a.name = id
	a.position = local
	add_child(a)
	return a


func add_fishing(id: String, table: String, local: Vector3, facing_offset: Vector3) -> FishingSpot:
	var f := FishingSpot.new().setup(id, table, facing_offset)
	f.name = id
	f.position = local
	add_child(f)
	return f


func ui() -> Node:
	return GameState.get("ui")


func region_label(text: String, local: Vector3, size: int = 90) -> Label3D:
	var l := EnvKit.label3d(self, text, local, size, Color("173b31"), true)
	l.modulate.a = 0.0
	l.add_to_group("region_label")
	return l
