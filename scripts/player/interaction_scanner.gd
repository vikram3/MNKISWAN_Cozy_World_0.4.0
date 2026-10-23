class_name InteractionScanner
extends Node
## GDD §23 scanner algorithm: collect candidates → discard invalid/too far → view-cone →
## rank by alignment, distance and explicit priority → one prompt → revalidate on press → call once.

signal focus_changed(target: Interactable, prompt: String, enabled: bool)

var actor: Node3D
var current: Interactable = null
var _last_prompt := ""
var _last_enabled := true
var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if actor == null:
		return
	if actor is MnkiController and ((actor as MnkiController).flight_mode != "grounded" or (actor as MnkiController).state == "locked"):
		if current:
			clear()
		return
	var best: Interactable = null
	var best_score := -INF
	var fwd: Vector3 = actor.facing_direction() if actor.has_method("facing_direction") else -actor.global_basis.z
	var origin := actor.global_position
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not is_instance_valid(it) or not it.is_visible_in_tree():
			continue
		var p := it.interaction_point()
		var to := p - origin
		if absf(to.y) > 1.7:
			continue  # different floor (e.g. treehouse upper storey)
		to.y = 0.0
		var dist := to.length()
		if dist > it.interaction_range:
			continue
		var align := 1.0 if dist < 0.6 else fwd.dot(to / dist)
		if align < -0.35 and dist > 1.0:
			continue
		var score := float(it.priority) * 0.6 + align * 2.0 - dist * 1.2
		if score > best_score:
			best_score = score
			best = it
	var prompt := ""
	var enabled := true
	if best:
		prompt = best.get_interaction_prompt(actor)
		enabled = best.can_interact(actor)
		if not enabled:
			var reason := best.get_disabled_reason(actor)
			if reason != "":
				prompt = reason
	if best != current or prompt != _last_prompt or enabled != _last_enabled:
		if current and is_instance_valid(current):
			current.set_focused(false)
		current = best
		if current:
			current.set_focused(true)
		_last_prompt = prompt
		_last_enabled = enabled
		focus_changed.emit(current, prompt, enabled)


func try_interact() -> bool:
	if _cooldown > 0.0 or current == null or not is_instance_valid(current):
		return false
	# Revalidate state and range at press time.
	var to := current.interaction_point() - actor.global_position
	if absf(to.y) > 1.7:
		return false
	to.y = 0
	if to.length() > current.interaction_range + 0.3:
		return false
	if not current.can_interact(actor):
		AudioManager.play_sfx("error")
		return false
	_cooldown = 0.35   # one input = one action
	current.interact(actor)
	return true


func clear() -> void:
	if current and is_instance_valid(current):
		current.set_focused(false)
	current = null
	_last_prompt = ""
	focus_changed.emit(null, "", true)
