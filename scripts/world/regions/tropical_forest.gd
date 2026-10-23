extends RegionBase
## 06 Tropical Fruit Forest — mango canopy, bananas, coconut palms, warm sun shafts.


func build() -> void:
	add_gather("tf_mango_1", "mango_tree", Vector3(-6, 0, -5))
	add_gather("tf_mango_2", "mango_tree", Vector3(5, 0, -6))
	add_gather("tf_mango_3", "mango_tree", Vector3(-2, 0, 6.5))
	add_gather("tf_banana_1", "banana_plant", Vector3(8, 0, 2))
	add_gather("tf_banana_2", "banana_plant", Vector3(-9, 0, 2.5))
	add_gather("tf_banana_3", "banana_plant", Vector3(6, 0, 8))
	add_gather("tf_coconut_1", "coconut_palm", Vector3(10, 0, -3))
	add_gather("tf_coconut_2", "coconut_palm", Vector3(-10, 0, -8))
	# Pip's lost wind chime (only appears while the request is active)
	add_gather("tf_windchime", "keepsake", Vector3(9.4, 0, 5.2))
	for p in [Vector3(-12, 0, 9), Vector3(12, 0, 10), Vector3(0, 0, -10), Vector3(-12, 0, -2)]:
		EnvKit.tree(self, p, 1.1, Color("4f9e45"), "palm")
	for p in [Vector3(2, 0, 10), Vector3(-6, 0, 10), Vector3(12, 0, -9)]:
		EnvKit.tree(self, p, 1.0, Color("6dbb4f"), "banana")
	for p in [Vector3(-2, 0, -3), Vector3(3, 0, 3)]:
		var shaft := CharParts.add(self, CharParts.cyl_mesh(0.5, 1.8, 9.0, 16), CharParts.unshaded(Color(1.0, 0.86, 0.55, 0.035)), p + Vector3(0, 4.5, 0), Vector3(6, 0, -8))
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EnvKit.flowers(self, Vector3(0, 0, 0), 50, 9.0, [Color("f06b4f"), Color("f4a12a"), Color("f2d84b")], 61)
	EnvKit.sign_post(self, Vector3(-3, 0, -10.5), "Tropical Fruit Forest\nFruit regrows - take what you need", 0)
