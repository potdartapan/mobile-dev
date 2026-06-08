extends Node2D

enum State { IDLE, GOING_TO_CUSTOMER, TAKING_ORDER, GOING_TO_PICKUP, DELIVERING }

var _state: State = State.IDLE
var _speed: float = 220.0
var _idle_pos: Vector2
var _current_customer = null
var _current_order: Dictionary = {}
var _take_timer: float = 0.0

func _ready():
	add_to_group("waiters")
	_idle_pos = position
	_speed *= pow(1.2, GameState.upgrade_counts.get("waiter_speed", 0))

func _process(delta: float):
	match _state:
		State.IDLE:
			_move_toward(_idle_pos, delta)
			# Priority 1: deliver ready food before taking new orders
			var ready = GameState.take_ready_order()
			if not ready.is_empty():
				_current_order = ready
				_state = State.GOING_TO_PICKUP
				return
			# Priority 2: take new orders from waiting customers
			var c = GameState.take_pending_order()
			if c != null:
				_current_customer = c
				_state = State.GOING_TO_CUSTOMER

		State.GOING_TO_CUSTOMER:
			if not is_instance_valid(_current_customer):
				_state = State.IDLE
				return
			_move_toward(_current_customer.position, delta)
			if position.distance_to(_current_customer.position) < 10.0:
				_take_timer = 1.0
				_state = State.TAKING_ORDER

		State.TAKING_ORDER:
			_take_timer -= delta
			if _take_timer <= 0.0:
				if is_instance_valid(_current_customer):
					var station = _current_customer.get_order_station()
					if station != null:
						GameState.add_cooking_task(_current_customer, station)
				_current_customer = null
				_state = State.IDLE

		State.GOING_TO_PICKUP:
			var station = _current_order.get("station")
			if not is_instance_valid(station):
				_free_food_visual()
				_current_order = {}
				_state = State.IDLE
				return
			_move_toward(station.global_position, delta)
			if position.distance_to(station.global_position) < 14.0:
				_attach_food_visual()
				if is_instance_valid(_current_order.get("customer")):
					_state = State.DELIVERING
				else:
					_free_food_visual()
					_current_order = {}
					_state = State.IDLE

		State.DELIVERING:
			var cust = _current_order.get("customer")
			if not is_instance_valid(cust):
				_free_food_visual()
				_current_order = {}
				_state = State.IDLE
				return
			_move_toward(cust.position, delta)
			if position.distance_to(cust.position) < 10.0:
				cust.receive_food(_current_order.station.coin_reward)
				_free_food_visual()
				_current_order = {}
				_state = State.IDLE

func _attach_food_visual():
	var food = _current_order.get("food_visual")
	if is_instance_valid(food):
		add_child(food)
		food.position = Vector2(0, -38)

func _free_food_visual():
	var food = _current_order.get("food_visual")
	if is_instance_valid(food):
		food.queue_free()

func _move_toward(pos: Vector2, delta: float):
	var diff = pos - position
	if diff.length() > 2.0:
		position += diff.normalized() * _speed * delta
