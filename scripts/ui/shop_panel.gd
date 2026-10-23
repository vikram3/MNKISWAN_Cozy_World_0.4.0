class_name ShopPanel
extends ModalPanel
## Fruit stall / grocer / decor vendor UI (GDD §9.7, §11). Every sale shows item, quantity,
## unit price and total before confirming; quest items are protected unless explicitly allowed;
## the ShopSystem re-validates at confirm time so nothing duplicates or partially completes.

var mode := "stall"
var _basket: Dictionary = {}
var _tabs: TabContainer
var _sell_list: VBoxContainer
var _total_label: Label
var _confirm: Button
var _allow_quest: CheckBox
var _orders_list: VBoxContainer
var _upgrade_box: VBoxContainer
var _buy_list: VBoxContainer
var _basket_banner: HBoxContainer
var _status: Label


func _init() -> void:
	super._init()
	panel_id = "shop"
	title_text = "Mnki & Swan Fruit Stall"


func panel_size() -> Vector2:
	return Vector2(1400, 860)


func build_content() -> void:
	_basket_banner = HBoxContainer.new()
	_basket_banner.add_theme_constant_override("separation", 16)
	content.add_child(_basket_banner)
	_status = UITheme.label("", 22, UITheme.CORAL)
	content.add_child(_status)
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)
	# Sell tab
	var sell := VBoxContainer.new()
	sell.name = "Sell"
	_tabs.add_child(sell)
	_sell_list = scroll_box(sell, 470)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 20)
	sell.add_child(foot)
	_allow_quest = CheckBox.new()
	_allow_quest.text = "Allow selling items needed for requests"
	_allow_quest.toggled.connect(func(_on): _rebuild_sell())
	foot.add_child(_allow_quest)
	_total_label = UITheme.label("Total: 0 coins", 30, UITheme.FOREST, true)
	_total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_child(_total_label)
	_confirm = UITheme.button("Confirm sale", _do_sell, 240)
	foot.add_child(_confirm)
	# Orders tab
	var orders := VBoxContainer.new()
	orders.name = "Orders"
	_tabs.add_child(orders)
	_orders_list = scroll_box(orders, 540)
	# Upgrade tab
	_upgrade_box = VBoxContainer.new()
	_upgrade_box.name = "Upgrade"
	_upgrade_box.add_theme_constant_override("separation", 14)
	_tabs.add_child(_upgrade_box)
	# Buy tab
	var buy := VBoxContainer.new()
	buy.name = "Buy"
	_tabs.add_child(buy)
	_buy_list = scroll_box(buy, 560)


func open_mode(m: String) -> void:
	mode = m
	match m:
		"grocer": set_title("Tamsin's Seeds & Groceries")
		"decor": set_title("Odo's Decor & Planks")
		_: set_title("Mnki & Swan Fruit Stall")
	open()
	if GameState.player and GameState.player.has_method("play_action"):
		GameState.player.play_action("shop", 0.6)


func refresh() -> void:
	_basket.clear()
	_status.text = ""
	var stall := mode == "stall"
	_tabs.set_tab_hidden(0, not stall)
	_tabs.set_tab_hidden(1, not stall)
	_tabs.set_tab_hidden(2, not stall)
	_tabs.set_tab_hidden(3, stall)
	_tabs.current_tab = 0 if stall else 3
	GameState.shop.ensure_orders()
	_rebuild_banner()
	_rebuild_sell()
	_rebuild_orders()
	_rebuild_upgrade()
	_rebuild_buy()


# --- Basket for the village (quest delivery at the stall) ---------------------------------------

func _rebuild_banner() -> void:
	UITheme.clear(_basket_banner)
	if mode != "stall" or not GameState.quests.has_deliver_for("stall_basket"):
		return
	_basket_banner.add_child(UITheme.label("Request: prepare the village basket (3 Cherry Berries + 1 Mango). Only those items are used.", 22, UITheme.FOREST))
	_basket_banner.add_child(UITheme.button("Prepare basket", func():
		var res := GameState.quests.try_deliver("stall_basket")
		if res.ok:
			AudioManager.play_sfx("upgrade")
			_status.text = "Basket prepared! Take it to Elder Maple in the park."
			GameState.notify("Basket prepared!", "quest")
		else:
			AudioManager.play_sfx("error")
			_status.text = String(res.reason)
		refresh(), 240))


# --- Sell ---------------------------------------------------------------------------------------

func _rebuild_sell() -> void:
	UITheme.clear(_sell_list)
	var needed := InventoryPanel._quest_needed()
	var any := false
	for id in GameState.inventory.sorted_ids():
		if not ItemDB.can_sell(id):
			continue
		any = true
		var have := GameState.inventory.count(id)
		var protected_qty := 0 if _allow_quest.button_pressed else mini(int(needed.get(id, 0)), have)
		var max_q := have - protected_qty
		var q: int = clampi(int(_basket.get(id, 0)), 0, max_q)
		_basket[id] = q
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UITheme.item_icon(id, 40))
		var nm := UITheme.label("%s  (have %d)" % [ItemDB.display_name(id), have], 23)
		nm.custom_minimum_size.x = 380
		row.add_child(nm)
		var price := UITheme.label("%d each" % ItemDB.sell_value(id), 21, UITheme.MUTED)
		price.custom_minimum_size.x = 110
		row.add_child(price)
		var minus := UITheme.button("-", func(): _set_q(id, int(_basket.get(id, 0)) - 1, max_q), 52)
		row.add_child(minus)
		var ql := UITheme.label(str(q), 26, UITheme.FOREST, true)
		ql.custom_minimum_size.x = 50
		ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(ql)
		row.add_child(UITheme.button("+", func(): _set_q(id, int(_basket.get(id, 0)) + 1, max_q), 52))
		row.add_child(UITheme.button("All", func(): _set_q(id, max_q, max_q), 70))
		var line := UITheme.label("= %d" % (q * ItemDB.sell_value(id)), 23, UITheme.FOREST)
		line.custom_minimum_size.x = 90
		row.add_child(line)
		if protected_qty > 0:
			row.add_child(UITheme.label("%d kept for a request" % protected_qty, 18, UITheme.CORAL))
		_sell_list.add_child(row)
	if not any:
		_sell_list.add_child(UITheme.label("Nothing to sell yet — gather fruit, flowers, fish, eggs or crops.", 24, UITheme.MUTED))
	_update_total()


func _set_q(id: String, q: int, max_q: int) -> void:
	_basket[id] = clampi(q, 0, max_q)
	_rebuild_sell()


func _update_total() -> void:
	var p := GameState.shop.preview(_basket)
	_total_label.text = "Total: %d coins" % (int(p.total) if p.ok else 0)
	_confirm.disabled = not p.ok


func _do_sell() -> void:
	var res := GameState.shop.sell(_basket)
	if res.ok:
		AudioManager.play_sfx("sale")
		_status.text = "Sold for %d coins! The display looks fuller." % int(res.total)
		GameState.notify("Sale complete: +%d coins" % int(res.total), "item")
	else:
		AudioManager.play_sfx("error")
		_status.text = String(res.reason)
	_basket.clear()
	_rebuild_sell()
	_rebuild_orders()


# --- Orders -------------------------------------------------------------------------------------

func _rebuild_orders() -> void:
	UITheme.clear(_orders_list)
	var shop := GameState.shop
	if shop.level == 0:
		_orders_list.add_child(UITheme.label("The order board unlocks with the first stall upgrade (Upgrade tab).", 24, UITheme.MUTED))
		return
	_orders_list.add_child(UITheme.label("Today's market orders (new orders every morning):", 22, UITheme.MUTED))
	for i in shop.orders.size():
		var o: Dictionary = shop.orders[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var parts: Array = []
		for item in o["items"]:
			parts.append("%d %s (have %d)" % [int(o["items"][item]), ItemDB.display_name(String(item)), GameState.inventory.count(String(item))])
		var l := UITheme.label(", ".join(parts), 23)
		l.custom_minimum_size.x = 760
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(l)
		row.add_child(UITheme.label("%d coins" % int(o.reward), 24, UITheme.FOREST, true))
		var idx := i
		var b := UITheme.button("Delivered" if o.done else "Deliver", func():
			var res := GameState.shop.fulfil_order(idx)
			if res.ok:
				AudioManager.play_sfx("sale")
				_status.text = "Order delivered! +%d coins, +1 reputation." % int(o.reward)
			else:
				AudioManager.play_sfx("error")
				_status.text = String(res.reason)
			_rebuild_orders()
			_rebuild_sell(), 170)
		b.disabled = o.done or not GameState.inventory.has_all(o["items"])
		row.add_child(b)
		_orders_list.add_child(row)
	_orders_list.add_child(UITheme.label("Reputation: %d · Total earned at the stall: %d coins" % [shop.reputation, shop.total_sold], 20, UITheme.MUTED))


# --- Upgrade ------------------------------------------------------------------------------------

func _rebuild_upgrade() -> void:
	UITheme.clear(_upgrade_box)
	var shop := GameState.shop
	_upgrade_box.add_child(UITheme.label("Stall level %d of %d" % [shop.level, GameData.STALL_UPGRADES.size()], 30, UITheme.FOREST, true))
	for u in GameData.STALL_UPGRADES:
		var owned := shop.level >= int(u.level)
		var l := UITheme.label("%s  Level %d — %s (%d coins): %s" % ["[x]" if owned else "[ ]", int(u.level), String(u.name), int(u.cost), String(u.desc)], 22, UITheme.FOREST if owned else UITheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 1200
		_upgrade_box.add_child(l)
	var nxt := shop.next_upgrade()
	if nxt.is_empty():
		_upgrade_box.add_child(UITheme.label("Fully upgraded — the stall is the pride of the market!", 26, UITheme.CORAL, true))
		return
	var b := UITheme.button("Upgrade to: %s (%d coins)" % [String(nxt.name), int(nxt.cost)], func():
		var res := GameState.shop.upgrade()
		if res.ok:
			AudioManager.play_sfx("upgrade")
			_status.text = "Upgraded! Look at the stall."
			SaveManager.autosave("stall_upgrade")
		else:
			AudioManager.play_sfx("error")
			_status.text = String(res.reason)
		_rebuild_upgrade()
		_rebuild_orders(), 520)
	b.disabled = not GameState.economy.can_afford(int(nxt.cost))
	_upgrade_box.add_child(b)
	if b.disabled:
		_upgrade_box.add_child(UITheme.label("Need %d more coins." % (int(nxt.cost) - GameState.economy.coins), 22, UITheme.CORAL))


# --- Buy ----------------------------------------------------------------------------------------

func _rebuild_buy() -> void:
	UITheme.clear(_buy_list)
	var offers: Array = GameData.GROCER_OFFERS if mode == "grocer" else GameData.DECOR_OFFERS
	if mode == "stall":
		return
	_buy_list.add_child(UITheme.label("You have %d coins." % GameState.economy.coins, 24, UITheme.FOREST, true))
	for id in offers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(UITheme.item_icon(id, 40))
		var nm := UITheme.label(ItemDB.display_name(id), 24)
		nm.custom_minimum_size.x = 300
		row.add_child(nm)
		var desc := UITheme.label(String(ItemDB.get_def(id).desc), 18, UITheme.MUTED)
		desc.custom_minimum_size.x = 460
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		row.add_child(UITheme.label("%d coins" % ItemDB.buy_value(id), 22, UITheme.FOREST, true))
		var unique := ItemDB.stack_limit(id) == 1
		var owned := unique and (GameState.inventory.count(id) > 0 or GameState.world.is_item_placed(id))
		var qty := 1 if unique else 1
		var b := UITheme.button("Owned" if owned else "Buy", func(): _buy(id, qty), 120)
		b.disabled = owned or not GameState.economy.can_afford(ItemDB.buy_value(id))
		row.add_child(b)
		if not unique:
			var b5 := UITheme.button("Buy 5", func(): _buy(id, 5), 120)
			b5.disabled = not GameState.economy.can_afford(ItemDB.buy_value(id) * 5)
			row.add_child(b5)
		_buy_list.add_child(row)


func _buy(id: String, qty: int) -> void:
	var res := GameState.shop.buy(id, qty)
	if res.ok:
		AudioManager.play_sfx("coin")
		_status.text = "Bought %d %s." % [qty, ItemDB.display_name(id)]
		if ItemDB.category(id) == "decor":
			_status.text += " Place it at home on its glowing spot."
	else:
		AudioManager.play_sfx("error")
		_status.text = String(res.reason)
	_rebuild_buy()
