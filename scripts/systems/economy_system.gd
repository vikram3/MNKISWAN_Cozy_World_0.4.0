class_name EconomySystem
extends Node
## Owns the coin balance. Every source/sink is logged for balancing (GDD §11 safeguards).

signal coins_changed(old_value: int, new_value: int)

var coins: int = 0
var ledger: Array = []   # recent [day, delta, reason] entries, capped


func reset() -> void:
	coins = 0
	ledger.clear()


func add(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	var old := coins
	coins += amount
	_log(amount, reason)
	coins_changed.emit(old, coins)


func can_afford(amount: int) -> bool:
	return amount <= coins


func spend(amount: int, reason: String = "") -> bool:
	if amount < 0 or amount > coins:
		return false
	var old := coins
	coins -= amount
	_log(-amount, reason)
	coins_changed.emit(old, coins)
	return true


func _log(delta: int, reason: String) -> void:
	ledger.append([TimeManager.day, delta, reason])
	if ledger.size() > 200:
		ledger.pop_front()


func to_save() -> Dictionary:
	return {"coins": coins}


func from_save(d: Dictionary) -> void:
	coins = max(0, int(d.get("coins", 0)))
	coins_changed.emit(coins, coins)
