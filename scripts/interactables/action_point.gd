class_name ActionPoint
extends Interactable
## Generic interactable driven by callables — used for feed bin, egg nest, gate, statues,
## bridge site, bed, storage, notice boards, keepsake inspection, etc. Keeps one-off logic in the
## region scripts while still going through the shared interaction contract.

var prompt_fn: Callable
var action_fn: Callable
var enabled_fn: Callable


func configure(id: String, prompt: Callable, action: Callable, enabled: Callable = Callable(), reach: float = 2.4, marker_h: float = 1.4, prio: int = 0) -> ActionPoint:
	object_id = id
	prompt_fn = prompt
	action_fn = action
	enabled_fn = enabled
	interaction_range = reach
	marker_height = marker_h
	priority = prio
	return self


func can_interact(_actor: Node) -> bool:
	return enabled_fn.call() if enabled_fn.is_valid() else true


func get_interaction_prompt(actor: Node) -> String:
	if prompt_fn.is_valid():
		return String(prompt_fn.call())
	return "Interact"


func interact(actor: Node) -> void:
	if action_fn.is_valid():
		action_fn.call(actor)
