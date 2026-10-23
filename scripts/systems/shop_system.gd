class_name ShopSystem
extends Node
## Fruit stall: validated sell transactions, buying, market orders and visible upgrades (GDD §9.7).
## UI only issues commands; this node is the source of truth.

signal shop_transaction_completed(total: int, items: Dictionary)
signal stall_upgraded(level: int)
signal orders_changed
signal display_changed(display_count: int)

var level: int = 0
var reputation: int = 0
var total_sold: int = 0
var display_count: int = 0      # how full the stall display looks
var orders_day: int = -1
var orders: Array = []          # [{items, reward, done}]
var sales_count: int = 0
var _busy := false              # guards against double-submission from repeated input


func reset() -> void:
	level = 0
	reputation = 0
	total_sold = 0
	display_count = 0
	orders_day = -1
	orders.clear()
	sales_count = 0


## Returns {ok, total, reason}. Quantities are re-validated at confirm time.
func preview(basket: Dictionary) -> Dictionary:
	var total := 0
	for id in basket:
		var q := int(basket[id])
		if q <= 0:
			continue
		if not ItemDB.can_sell(id):
			return {"ok": false, "total": 0, "reason": "%s can't be sold." % ItemDB.display_name(id)}
		if GameState.inventory.count(id) < q:
			return {"ok": false, "total": 0, "reason": "Not enough %s." % ItemDB.display_name(id)}
		total += ItemDB.sell_value(id) * q
	if total <= 0:
		return {"ok": false, "total": 0, "reason": "Choose something to sell."}
	return {"ok": true, "total": total, "reason": ""}


func sell(basket: Dictionary) -> Dictionary:
	if _busy:
		return {"ok": false, "total": 0, "reason": "Busy"}
	_busy = true
	var clean: Dictionary = {}
	for id in basket:
		if int(basket[id]) > 0:
			clean[id] = int(basket[id])
	var p := preview(clean)
	if not p.ok:
		_busy = false
		return p
	if not GameState.inventory.remove_all(clean):
		_busy = false
		return {"ok": false, "total": 0, "reason": "Your bag changed — please check again."}
	var total: int = p.total
	GameState.economy.add(total, "stall_sale")
	total_sold += total
	sales_count += 1
	var n := 0
	for id in clean:
		n += int(clean[id])
	display_count = min(display_count + n, 40)
	display_changed.emit(display_count)
	shop_transaction_completed.emit(total, clean)
	_busy = false
	return {"ok": true, "total": total, "reason": ""}


func buy(id: String, qty: int) -> Dictionary:
	var cost := ItemDB.buy_value(id) * qty
	if qty <= 0 or cost <= 0:
		return {"ok": false, "reason": "Not for sale."}
	if ItemDB.stack_limit(id) == 1 and (GameState.inventory.count(id) > 0 or GameState.world.is_item_placed(id)):
		return {"ok": false, "reason": "You already own this."}
	if not GameState.economy.can_afford(cost):
		return {"ok": false, "reason": "Need %d coins." % cost}
	if not GameState.inventory.can_add(id, qty):
		return {"ok": false, "reason": "Your bag is full."}
	GameState.economy.spend(cost, "buy_" + id)
	GameState.inventory.add(id, qty)
	return {"ok": true, "reason": ""}


func next_upgrade() -> Dictionary:
	for u in GameData.STALL_UPGRADES:
		if int(u.level) == level + 1:
			return u
	return {}


func upgrade() -> Dictionary:
	var u := next_upgrade()
	if u.is_empty():
		return {"ok": false, "reason": "The stall is fully upgraded."}
	if not GameState.economy.spend(int(u.cost), "stall_upgrade"):
		return {"ok": false, "reason": "Need %d coins." % int(u.cost)}
	level = int(u.level)
	reputation += 1
	stall_upgraded.emit(level)
	orders_day = -1  # regenerate with new capacity
	ensure_orders()
	return {"ok": true, "reason": ""}


# --- Orders -------------------------------------------------------------------------------------

func order_capacity() -> int:
	return 0 if level == 0 else level + 1


func ensure_orders() -> void:
	if orders_day == TimeManager.day:
		return
	orders_day = TimeManager.day
	orders.clear()
	var cap := order_capacity()
	if cap <= 0:
		orders_changed.emit()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("orders_%d_%d" % [TimeManager.day, level])
	var pool: Array = []
	for o in GameData.ORDER_POOL:
		if int(o[2]) <= level:
			pool.append(o)
	for i in cap:
		if pool.is_empty():
			break
		var pick: Array = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		orders.append({"items": (pick[0] as Dictionary).duplicate(), "reward": int(pick[1]), "done": false})
	orders_changed.emit()


func fulfil_order(index: int) -> Dictionary:
	ensure_orders()
	if index < 0 or index >= orders.size():
		return {"ok": false, "reason": "No such order."}
	var o: Dictionary = orders[index]
	if o.done:
		return {"ok": false, "reason": "Already delivered."}
	if not GameState.inventory.remove_all(o["items"]):
		return {"ok": false, "reason": "Missing items for this order."}
	o.done = true
	GameState.economy.add(int(o.reward), "order")
	reputation += 1
	total_sold += int(o.reward)
	display_count = min(display_count + 3, 40)
	display_changed.emit(display_count)
	orders_changed.emit()
	shop_transaction_completed.emit(int(o.reward), o["items"])
	return {"ok": true, "reason": ""}


func to_save() -> Dictionary:
	return {"level": level, "reputation": reputation, "total_sold": total_sold, "display": display_count,
		"orders_day": orders_day, "orders": orders.duplicate(true), "sales": sales_count}


func from_save(d: Dictionary) -> void:
	reset()
	level = clampi(int(d.get("level", 0)), 0, GameData.STALL_UPGRADES.size())
	reputation = int(d.get("reputation", 0))
	total_sold = int(d.get("total_sold", 0))
	display_count = int(d.get("display", 0))
	orders_day = int(d.get("orders_day", -1))
	sales_count = int(d.get("sales", 0))
	for o in d.get("orders", []):
		if o is Dictionary and o.has("items"):
			orders.append(o)
