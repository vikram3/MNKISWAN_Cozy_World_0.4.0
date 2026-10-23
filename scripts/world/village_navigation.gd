class_name VillageNavigation
extends Node
## Ground-level routes sampled from actual static collisions; never cuts diagonal corners.
var grid := AStarGrid2D.new()
var ready_for_routes := false
const ORIGIN := Vector3(-61, 0, -103)
const SIZE := Vector2i(123, 213)
var probe := CapsuleShape3D.new()

func rebuild(world: World3D) -> void:
	ready_for_routes = false
	grid.region = Rect2i(Vector2i.ZERO, SIZE)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	probe.radius = 0.34
	probe.height = 1.3
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collision_mask = 1 | 16
	for z in SIZE.y:
		for x in SIZE.x:
			var id := Vector2i(x, z)
			query.transform.origin = point(id) + Vector3(0, 0.77, 0)
			grid.set_point_solid(id, not world.direct_space_state.intersect_shape(query, 1).is_empty())
	ready_for_routes = true

func point(id: Vector2i) -> Vector3:
	return ORIGIN + Vector3(id.x, 0, id.y)

func nearest(p: Vector3) -> Vector2i:
	var base := Vector2i(roundi(p.x - ORIGIN.x), roundi(p.z - ORIGIN.z))
	base = base.clamp(Vector2i.ZERO, SIZE - Vector2i.ONE)
	for radius in 10:
		var best := Vector2i(-1, -1)
		var distance := INF
		for z in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var id := base + Vector2i(x, z)
				if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
					var d := point(id).distance_squared_to(p)
					if d < distance:
						distance = d
						best = id
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)

func route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not ready_for_routes:
		return result
	var a := nearest(from)
	var b := nearest(to)
	if a.x < 0 or b.x < 0:
		return result
	for id in grid.get_id_path(a, b):
		result.append(point(id))
	return result

func route_avoiding(from: Vector3, to: Vector3, occupied: Array[Vector3]) -> PackedVector3Array:
	var changed: Array[Vector2i] = []
	var start := nearest(from)
	var end := nearest(to)
	for position in occupied:
		var id := nearest(position)
		if id.x >= 0 and id != start and id != end and not grid.is_point_solid(id):
			grid.set_point_solid(id, true)
			changed.append(id)
	var result := route(from, to)
	for id in changed: grid.set_point_solid(id, false)
	return result
