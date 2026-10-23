class_name VillageBackdrop
extends Node3D
## Distant landscape supplies depth from the air without extending the playable boundary.
var clouds: Array[Node3D] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7132
	for ring in 2:
		for i in 18:
			var a := TAU * float(i) / 18.0 + ring * 0.15
			var p := Vector3(sin(a) * (128 + ring * 65), -7, cos(a) * (168 + ring * 65))
			var size := Vector3(rng.randf_range(30, 48), rng.randf_range(18, 36) + ring * 10, rng.randf_range(34, 48))
			var color := Color("668f7d") if ring == 0 else Color("8cabb0")
			var hill := CharParts.add(self, CharParts.sphere_mesh(1, 36), CharParts.mat(color), p, Vector3.ZERO, size)
			hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 12:
		var cloud := Node3D.new()
		cloud.position = Vector3(rng.randf_range(-140, 140), rng.randf_range(42, 65), rng.randf_range(-165, 165))
		add_child(cloud)
		clouds.append(cloud)
		for j in 5:
			var puff := CharParts.add(cloud, CharParts.sphere_mesh(1, 20), CharParts.mat(Color("eef3ec")), Vector3(j * 3 - 6, sin(j * 1.3) * 0.8, cos(j) * 1.4), Vector3.ZERO, Vector3(4, 1.7 + sin(j) * 0.6, 2.8))
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if GameState.is_ui_blocking() or Settings.get_value("reduced_motion"):
		return
	for cloud in clouds:
		cloud.position.x += delta * 0.18
		if cloud.position.x > 180:
			cloud.position.x = -180
