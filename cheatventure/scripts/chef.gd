extends Node2D

enum State { IDLE, GOING_TO_STATION, COOKING }

var _state: State = State.IDLE
var _speed: float = 130.0
var _idle_pos: Vector2
var _current_order: Dictionary = {}
var _cook_timer: float = 0.0
var _food_visual: Node2D = null

func _ready():
	add_to_group("chefs")
	_idle_pos = position
	_speed *= pow(1.2, GameState.upgrade_counts.get("chef_speed", 0))

func _process(delta: float):
	match _state:
		State.IDLE:
			_move_toward(_idle_pos, delta)
			var task = GameState.take_cooking_task()
			if not task.is_empty():
				_current_order = task
				_state = State.GOING_TO_STATION

		State.GOING_TO_STATION:
			var station = _current_order.get("station")
			if not is_instance_valid(station):
				_current_order = {}
				_state = State.IDLE
				return
			_move_toward(station.global_position, delta)
			if position.distance_to(station.global_position) < 12.0:
				_cook_timer = station.production_time
				_food_visual = FoodItem.create_for_station(station)
				_food_visual.position = Vector2(0, -38)
				add_child(_food_visual)
				_state = State.COOKING

		State.COOKING:
			_cook_timer -= delta
			if _cook_timer <= 0.0:
				# Detach food visual and pass it along with the order
				if is_instance_valid(_food_visual):
					remove_child(_food_visual)
					_current_order["food_visual"] = _food_visual
					_food_visual = null
				GameState.mark_order_ready(_current_order)
				_current_order = {}
				_state = State.IDLE

func _move_toward(pos: Vector2, delta: float):
	var diff = pos - position
	if diff.length() > 2.0:
		position += diff.normalized() * _speed * delta
