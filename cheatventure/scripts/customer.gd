extends Node2D
class_name Customer

signal coins_earned(amount: int)

enum State { WALKING, WAITING, LEAVING }

var _state: State = State.WALKING
var _speed: float = 180.0
var _target: Vector2
var _slot: int = -1
var _queue_index: int = 0
var _order_station: FoodStation = null

func _ready():
	_slot = GameState.join_counter(self)
	if _slot < 0:
		_begin_leaving()
		return
	_queue_index = GameState.counter_queues[_slot].size() - 1
	_target = GameState.get_queue_position(_slot, _queue_index)

func _process(delta: float):
	match _state:
		State.WALKING:
			_move_toward(_target, delta)
			if position.distance_to(_target) < 4.0:
				_state = State.WAITING
				if _queue_index == 0:
					_order_station = _pick_unlocked_station()
					if _order_station == null:
						_begin_leaving()
					else:
						GameState.add_pending_order(self)
		State.LEAVING:
			_move_toward(_target, delta)
			if position.distance_to(_target) < 8.0:
				queue_free()

func _move_toward(pos: Vector2, delta: float):
	var diff = pos - position
	if diff.length() > 2.0:
		position += diff.normalized() * _speed * delta

func _pick_unlocked_station() -> FoodStation:
	var stations = get_tree().get_nodes_in_group("stations")
	var available: Array = []
	for s in stations:
		if s is FoodStation and s.is_unlocked:
			available.append(s)
	if available.is_empty():
		return null
	return available[randi() % available.size()]

func get_order_station() -> FoodStation:
	return _order_station

func is_waiting() -> bool:
	return _state == State.WAITING and _queue_index == 0

func get_counter_position() -> Vector2:
	return GameState.get_queue_position(_slot, 0)

func update_queue_position(slot: int, new_index: int) -> void:
	_slot = slot
	_queue_index = new_index
	_target = GameState.get_queue_position(slot, new_index)
	_state = State.WALKING

func receive_food(amount: int) -> void:
	coins_earned.emit(amount)
	GameState.leave_counter(_slot, self)
	_slot = -1
	_begin_leaving()

func _begin_leaving():
	_state = State.LEAVING
	_target = Vector2(position.x, -120.0)
