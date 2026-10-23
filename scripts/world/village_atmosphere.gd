class_name VillageAtmosphere
extends Node3D
## Batched drifting pollen by day and warm fireflies at dusk. No per-particle nodes.
var material: ShaderMaterial
var patches: Array[MultiMeshInstance3D] = []
const SHADER := """
shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform float evening = 0.0;
uniform float motion = 1.0;
varying float seed;
void vertex() {
    seed = INSTANCE_CUSTOM.x * 30.0;
    float t = TIME * motion;
    VERTEX += vec3(sin(t * 0.38 + seed) * 0.65, sin(t * 0.7 + seed) * 0.25, cos(t * 0.3 + seed) * 0.6);
}
void fragment() {
    ALBEDO = mix(vec3(0.95, 0.85, 0.52), vec3(1.0, 0.83, 0.35), evening);
    float pulse = 0.75 + 0.25 * sin(TIME * motion * 1.8 + seed);
    EMISSION = ALBEDO * evening * pulse;
}
"""

func _ready() -> void:
	var shader := Shader.new()
	shader.code = SHADER
	material = ShaderMaterial.new()
	material.shader = shader
	var rng := RandomNumberGenerator.new()
	rng.seed = 713
	for region in VillageLifeData.PLACES:
		var patch := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = CharParts.sphere_mesh(0.025, 6)
		mm.instance_count = 20
		var center := GameData.region_world_pos(region) + Vector3(VillageLifeData.PLACES[region][0])
		for i in mm.instance_count:
			var pos := Vector3(rng.randf_range(-3.6, 3.6), rng.randf_range(0.7, 2.8), rng.randf_range(-2, 3))
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pos))
			mm.set_instance_custom_data(i, Color(rng.randf(), 0, 0, 1))
		patch.multimesh = mm
		patch.material_override = material
		patch.position = center
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		patch.visibility_range_end = 32
		add_child(patch)
		patches.append(patch)
	Settings.settings_changed.connect(_update)
	TimeManager.hour_changed.connect(func(_h): _update())
	_update()

func _update() -> void:
	var h := TimeManager.hour()
	material.set_shader_parameter("evening", 1.0 if h >= 18 or h < 6 else 0.0)
	material.set_shader_parameter("motion", 0.0 if bool(Settings.get_value("reduced_motion")) else 1.0)
