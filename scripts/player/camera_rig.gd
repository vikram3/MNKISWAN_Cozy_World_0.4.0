class_name CameraRig
extends Node3D
## Third-person camera behind and slightly above Mnki (GDD §8). SpringArm collision shortens the
## distance smoothly instead of letting walls cover the character. Mouse look only while gameplay
## owns input. The camera never writes the character's velocity.

var target: Node3D
var yaw: Node3D
var pitch: Node3D
var arm: SpringArm3D
var camera: Camera3D
var distance := 4.4
const MIN_DIST := 2.4
const MAX_DIST := 11.0
var _pitch_deg := -18.0


func _ready() -> void:
	top_level = true
	yaw = Node3D.new(); add_child(yaw)
	pitch = Node3D.new(); yaw.add_child(pitch)
	pitch.rotation_degrees.x = _pitch_deg
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.collision_mask = 1
	arm.margin = 0.25
	var sph := SphereShape3D.new()
	sph.radius = 0.25
	arm.shape = sph
	pitch.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.near = 0.08
	camera.far = 400.0
	arm.add_child(camera)
	camera.current = true


func attach(t: Node3D) -> void:
	target = t
	if t is CollisionObject3D:
		arm.add_excluded_object((t as CollisionObject3D).get_rid())
	global_position = t.global_position + Vector3(0, 1.25, 0)


func set_yaw_deg(d: float) -> void:
	yaw.rotation_degrees.y = d


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_ui_blocking():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := float(Settings.get_value("mouse_sensitivity"))
		var inv := -1.0 if Settings.get_value("invert_y") else 1.0
		yaw.rotation_degrees.y -= event.relative.x * sens
		_pitch_deg = clampf(_pitch_deg - event.relative.y * sens * inv, -65.0, 25.0)
		pitch.rotation_degrees.x = _pitch_deg
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - 0.4, MIN_DIST, MAX_DIST)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + 0.4, MIN_DIST, MAX_DIST)
		elif event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and GameState.in_world:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if target == null:
		return
	if GameState.is_ui_blocking():
		return
	if Input.is_action_pressed("zoom_in"):
		distance = clampf(distance - 3.0 * delta, MIN_DIST, MAX_DIST)
	if Input.is_action_pressed("zoom_out"):
		distance = clampf(distance + 3.0 * delta, MIN_DIST, MAX_DIST)
	var airborne := target is MnkiController and (target as MnkiController).flight_mode != "grounded"
	var reduced: bool = Settings.get_value("reduced_motion")
	arm.spring_length = lerpf(arm.spring_length, distance + (1.4 if airborne else 0.0), 1.0 - exp(-7.0 * delta))
	camera.fov = lerpf(camera.fov, 65.0 if airborne and not reduced else 60.0, 1.0 - exp(-3.0 * delta))
	var goal := target.global_position + Vector3(0, 1.25, 0)
	var k := 1.0 if Settings.get_value("reduced_motion") else clampf(delta * 10.0, 0.0, 1.0)
	global_position = global_position.lerp(goal, k)


## Horizontal camera basis used for camera-relative movement.
func flat_basis() -> Basis:
	return Basis(Vector3.UP, yaw.rotation.y)
