extends Node

signal coins_changed(amount: int)

const SAVE_PATH = "user://save.json"
const AUTO_SAVE_INTERVAL = 60.0

var coins: int = 0
var upgrade_counts: Dictionary = {}
var active_delivery: Dictionary = {}
var _auto_save_timer: float = 0.0

# 5 counter slots — each is a queue of customers
const SLOT_X = [54.0, 162.0, 270.0, 378.0, 486.0]
const COUNTER_FRONT_Y = 325.0
const QUEUE_SPACING = 55.0
const MAX_QUEUE_DEPTH = 4

var counter_queues: Array = [[], [], [], [], []]
var pending_orders: Array = []
var cooking_queue: Array = []
var ready_orders: Array = []

# ── Auto-save timer ────────────────────────────────────
func _process(delta: float) -> void:
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		save()

# Save when app is backgrounded on mobile
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save()

# ── Coins ──────────────────────────────────────────────
func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

# ── Counter queue management ───────────────────────────
func join_counter(customer) -> int:
	var best_slot = _find_best_slot()
	if best_slot < 0:
		return -1
	var index = counter_queues[best_slot].size()
	counter_queues[best_slot].append(customer)
	return best_slot

func leave_counter(slot: int, customer) -> void:
	if slot < 0 or slot >= counter_queues.size():
		return
	var queue = counter_queues[slot]
	var idx = queue.find(customer)
	if idx < 0:
		return
	queue.remove_at(idx)
	for i in queue.size():
		queue[i].update_queue_position(slot, i)
	if queue.size() > 0 and queue[0].is_waiting():
		add_pending_order(queue[0])

func get_queue_position(slot: int, index: int) -> Vector2:
	return Vector2(SLOT_X[slot], COUNTER_FRONT_Y - index * QUEUE_SPACING)

func _find_best_slot() -> int:
	var best = -1
	var min_size = MAX_QUEUE_DEPTH
	for i in counter_queues.size():
		if counter_queues[i].size() < min_size:
			min_size = counter_queues[i].size()
			best = i
	return best

# ── Pending orders (waiter → customer) ────────────────
func add_pending_order(customer) -> void:
	if not pending_orders.has(customer):
		pending_orders.append(customer)

func take_pending_order():
	while pending_orders.size() > 0:
		var c = pending_orders.pop_front()
		if is_instance_valid(c):
			return c
	return null

# ── Cooking queue (chef pulls from here) ───────────────
func add_cooking_task(customer, station) -> void:
	cooking_queue.append({customer = customer, station = station})

func take_cooking_task() -> Dictionary:
	while cooking_queue.size() > 0:
		var task = cooking_queue.pop_front()
		if is_instance_valid(task.customer) and is_instance_valid(task.station):
			return task
	return {}

# ── Ready orders (waiter picks up and delivers) ────────
func mark_order_ready(order: Dictionary) -> void:
	ready_orders.append(order)

func take_ready_order() -> Dictionary:
	while ready_orders.size() > 0:
		var order = ready_orders.pop_front()
		if is_instance_valid(order.get("customer")) and is_instance_valid(order.get("station")):
			return order
		var food = order.get("food_visual")
		if is_instance_valid(food):
			food.queue_free()
	return {}

# ── Save / Load ────────────────────────────────────────
func save() -> void:
	var stations = get_tree().get_nodes_in_group("stations")
	if stations.is_empty():
		return  # Stations not loaded yet — don't overwrite existing save
	var stations_data = []
	for s in stations:
		if s is FoodStation:
			stations_data.append({
				"name": s.station_name,
				"level": s.level,
				"unlocked": s.is_unlocked,
			})
	var data = {
		"coins": coins,
		"upgrades": upgrade_counts,
		"active_delivery": active_delivery,
		"stations": stations_data,
		"last_save_timestamp": int(Time.get_unix_time_from_system()),
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {}
	return parsed
