class_name TouchIcons
extends RefCounted
## Tiny vector icon set drawn with CanvasItem primitives (no image assets, crisp at any size).
## Every icon fits a circle of radius `r` around `c`.


static func draw(ci: CanvasItem, icon: String, c: Vector2, r: float, col: Color) -> void:
	var w := maxf(r * 0.16, 2.0)
	match icon:
		"act":  # sparkle / hand-of-help: four-point star with a dot
			var pts := PackedVector2Array()
			for i in 8:
				var a := i * TAU / 8.0 - PI / 2.0
				var rr := r * (0.95 if i % 2 == 0 else 0.32)
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(pts, col)
		"jump", "rise":
			_chevron(ci, c + Vector2(0, r * 0.18), r * 0.62, -1, col, w * 1.15)
			_chevron(ci, c - Vector2(0, r * 0.32), r * 0.62, -1, col, w * 1.15)
		"down":
			_chevron(ci, c - Vector2(0, r * 0.18), r * 0.62, 1, col, w * 1.15)
			_chevron(ci, c + Vector2(0, r * 0.32), r * 0.62, 1, col, w * 1.15)
		"wings":
			for side in [-1.0, 1.0]:
				for i in 3:
					var ang := deg_to_rad(-20.0 - i * 28.0)
					var dir := Vector2(cos(ang) * side, sin(ang))
					var length := r * (0.95 - i * 0.12)
					var mid := c + Vector2(side * r * 0.08, r * 0.2) + dir * length * 0.5
					ci.draw_colored_polygon(_ellipse_rot(mid, Vector2(length * 0.5, r * 0.15), dir.angle()), col)
			ci.draw_circle(c + Vector2(0, r * 0.22), r * 0.16, col)
		"swap":
			ci.draw_arc(c, r * 0.62, deg_to_rad(200), deg_to_rad(340), 18, col, w, true)
			ci.draw_arc(c, r * 0.62, deg_to_rad(20), deg_to_rad(160), 18, col, w, true)
			_head(ci, c + Vector2(cos(deg_to_rad(340)), sin(deg_to_rad(340))) * r * 0.62, deg_to_rad(340) + PI / 2, r * 0.3, col)
			_head(ci, c + Vector2(cos(deg_to_rad(160)), sin(deg_to_rad(160))) * r * 0.62, deg_to_rad(160) + PI / 2, r * 0.3, col)
		"seed":
			ci.draw_colored_polygon(_leaf(c + Vector2(-r * 0.05, -r * 0.1), r * 0.75, -0.6), col)
			ci.draw_line(c + Vector2(0, r * 0.1), c + Vector2(r * 0.05, r * 0.8), col, w, true)
		"bag":
			var body := Rect2(c + Vector2(-r * 0.62, -r * 0.25), Vector2(r * 1.24, r * 0.95))
			ci.draw_rect(body, col)
			ci.draw_arc(c + Vector2(0, -r * 0.25), r * 0.36, PI, TAU, 14, col, w, true)
			ci.draw_line(body.position + Vector2(r * 0.2, r * 0.32), body.position + Vector2(r * 1.04, r * 0.32), Color(0, 0, 0, 0.25), w * 0.6)
		"book":
			for s in [-1.0, 1.0]:
				var pts := PackedVector2Array([c + Vector2(0, -r * 0.45), c + Vector2(s * r * 0.85, -r * 0.6), c + Vector2(s * r * 0.85, r * 0.55), c + Vector2(0, r * 0.7)])
				ci.draw_colored_polygon(pts, col)
			ci.draw_line(c + Vector2(0, -r * 0.45), c + Vector2(0, r * 0.7), Color(0, 0, 0, 0.3), w * 0.6)
		"map":
			var xs := [-0.85, -0.3, 0.3, 0.85]
			for i in 3:
				var dy := -0.12 if i % 2 == 0 else 0.12
				var pts := PackedVector2Array([c + Vector2(xs[i] * r, (-0.6 + dy) * r), c + Vector2(xs[i + 1] * r, (-0.6 - dy) * r), c + Vector2(xs[i + 1] * r, (0.6 - dy) * r), c + Vector2(xs[i] * r, (0.6 + dy) * r)])
				ci.draw_colored_polygon(pts, col if i != 1 else col.darkened(0.15))
		"heart":
			ci.draw_circle(c + Vector2(-r * 0.32, -r * 0.18), r * 0.38, col)
			ci.draw_circle(c + Vector2(r * 0.32, -r * 0.18), r * 0.38, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.68, -r * 0.05), c + Vector2(r * 0.68, -r * 0.05), c + Vector2(0, r * 0.72)]), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.55), Vector2(r * 0.3, r * 1.1)), col)
			ci.draw_rect(Rect2(c + Vector2(r * 0.15, -r * 0.55), Vector2(r * 0.3, r * 1.1)), col)
		"fish":
			ci.draw_colored_polygon(_ellipse(c + Vector2(-r * 0.1, 0), Vector2(r * 0.6, r * 0.36)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.4, 0), c + Vector2(r * 0.9, -r * 0.38), c + Vector2(r * 0.9, r * 0.38)]), col)
		"run":
			_chevron(ci, c + Vector2(-r * 0.2, 0), r * 0.55, 0, col, w)
			_chevron(ci, c + Vector2(r * 0.2, 0), r * 0.55, 0, col, w)
		_:
			ci.draw_circle(c, r * 0.3, col)


## dir: -1 up, 1 down, 0 right
static func _chevron(ci: CanvasItem, c: Vector2, s: float, dir: int, col: Color, w: float) -> void:
	var pts: PackedVector2Array
	if dir == 0:
		pts = PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.55), c + Vector2(s * 0.3, 0), c + Vector2(-s * 0.3, s * 0.55)])
	else:
		pts = PackedVector2Array([c + Vector2(-s * 0.6, -dir * s * 0.3), c + Vector2(0, dir * s * 0.3), c + Vector2(s * 0.6, -dir * s * 0.3)])
	ci.draw_polyline(pts, col, w, true)


static func _head(ci: CanvasItem, tip: Vector2, ang: float, s: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	ci.draw_colored_polygon(PackedVector2Array([tip + d * s * 0.6, tip - d * s * 0.4 + n * s * 0.55, tip - d * s * 0.4 - n * s * 0.55]), col)


static func _leaf(c: Vector2, s: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var t := i / 15.0 * TAU
		var p := Vector2(sin(t) * 0.38, -cos(t) * 0.62) * s
		p.x *= absf(cos(t * 0.5)) * 0.6 + 0.6
		pts.append(c + p.rotated(rot))
	return pts


static func _ellipse(c: Vector2, rad: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := i / 20.0 * TAU
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	return pts


static func circle_poly(c: Vector2, r: float, n: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := i / float(n) * TAU
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _ellipse_rot(c: Vector2, rad: Vector2, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i / 16.0 * TAU
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y).rotated(rot))
	return pts
