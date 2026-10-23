extends RegionBase
## 03 Cherry Berry Maze — waist-high hedges, short readable branches, berries and two secrets.

const HEDGE := Color("4f8f45")

## Hedge segments [from, to] in local XZ. Entrances on north and south (x in -1.6..1.6).
const SEGMENTS := [
	[Vector2(-10, -10), Vector2(-1.8, -10)], [Vector2(1.8, -10), Vector2(10, -10)],
	[Vector2(-10, 10), Vector2(-1.8, 10)], [Vector2(1.8, 10), Vector2(10, 10)],
	[Vector2(-10, -10), Vector2(-10, 10)], [Vector2(10, -10), Vector2(10, 10)],
	[Vector2(-10, -5), Vector2(-3, -5)], [Vector2(2.5, -5), Vector2(6, -5)],
	[Vector2(6, -10), Vector2(6, -1.5)],
	[Vector2(-6, 0), Vector2(3.5, 0)],
	[Vector2(-6, 0), Vector2(-6, 6)],
	[Vector2(1, 5), Vector2(10, 5)],
	[Vector2(-3, 3), Vector2(-3, 10)],
]


func build() -> void:
	for seg in SEGMENTS:
		_hedge(seg[0], seg[1])
	# Berry bushes along the corridors (clear colour contrast vs hedges)
	var bushes := [Vector3(-7.5, 0, -7.5), Vector3(-0.5, 0, -7.5), Vector3(3.5, 0, -2.5), Vector3(-8, 0, 2.5), Vector3(5.0, 0, 7.5), Vector3(0.0, 0, 2.5), Vector3(8, 0, 1.0)]
	for i in bushes.size():
		add_gather("bm_berry_%d" % i, "berry_bush", bushes[i])
	# Secrets reward curiosity, not punishment
	add_gather("bm_starberry", "starberry_bush", Vector3(8.2, 0, -8.0))
	add_gather("bm_moonbell", "moonbell", Vector3(-8.2, 0, 8.2))
	EnvKit.sign_post(self, Vector3(3, 0, 12), "Cherry Berry Maze\n(short paths, promise!)", 180)
	# Arch over the north entrance as a landmark
	for x in [-1.9, 1.9]:
		CharParts.add(self, CharParts.cyl_mesh(0.12, 0.14, 2.6, 8), CharParts.mat(EnvKit.WOOD_LIGHT, 0.01), Vector3(x, 1.3, -10))
	CharParts.add(self, CharParts.torus_mesh(1.75, 2.0, 8, 24), CharParts.mat(HEDGE, 0.012), Vector3(0, 2.6, -10), Vector3(90, 0, 0), Vector3(1, 1, 1))
	for i in 7:
		var a := PI * i / 6.0
		CharParts.sphere(self, 0.11, Color("d8344a"), Vector3(cos(a) * 1.9, 2.6 + sin(a) * 1.9, -10.15), Vector3.ONE, 0.006)


func _hedge(a: Vector2, b: Vector2) -> void:
	var d := b - a
	var length := d.length()
	var mid := (a + b) * 0.5
	var sb := EnvKit.body(self, Vector3(mid.x, 0, mid.y))
	sb.rotation.y = atan2(d.x, d.y)
	CharParts.add(sb, CharParts.box_mesh(Vector3(0.9, 1.15, length + 0.9)), CharParts.mat(HEDGE, 0.012), Vector3(0, 0.575, 0))
	# rounded top lumps
	var n := int(length / 0.9) + 1
	for i in n:
		var z := -length * 0.5 + length * float(i) / float(max(n - 1, 1))
		CharParts.sphere(sb, 0.42, HEDGE.lightened(0.08 if i % 2 else 0.0), Vector3(0, 1.15, z), Vector3(1.1, 0.5, 1.1), 0.0)
	EnvKit.add_box_shape(sb, Vector3(0.9, 1.4, length + 0.9), Vector3(0, 0.7, 0))
