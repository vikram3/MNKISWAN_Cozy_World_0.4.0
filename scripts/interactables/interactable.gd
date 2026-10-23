class_name Interactable
extends Node3D
## Shared interaction contract (GDD §9.2): can_interact / get_interaction_prompt / interact
## plus an explicit priority and reach. The player's InteractionScanner picks exactly one.

@export var interaction_range: float = 2.4
@export var priority: int = 0
@export var object_id: String = ""
## Height of the focus marker above the origin.
@export var marker_height: float = 1.6

var _marker: Node3D
var _focused := false
var _t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	_marker = Node3D.new()
	_marker.position = Vector3(0, marker_height, 0)
	_marker.visible = false
	add_child(_marker)
	var gem := CharParts.add(_marker, CharParts.cyl_mesh(0.0, 0.11, 0.18, 4), CharParts.mat(Color("e4b96b"), 0.008, 0.6), Vector3.ZERO, Vector3(180, 45, 0))
	gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func can_interact(_actor: Node) -> bool:
	return true


func get_interaction_prompt(_actor: Node) -> String:
	return "Interact"


## Optional disabled reason shown greyed in the HUD (never silently fails).
func get_disabled_reason(_actor: Node) -> String:
	return ""


func interact(_actor: Node) -> void:
	pass


func set_focused(on: bool) -> void:
	_focused = on
	if _marker:
		_marker.visible = on


func interaction_point() -> Vector3:
	return global_position


func _process(delta: float) -> void:
	if _focused and _marker:
		_t += delta
		_marker.position.y = marker_height + sin(_t * 4.0) * 0.06
		_marker.rotation.y += delta * 2.0
