extends Node2D

const WAITING_POS = Vector2(20, 280)
const EXIT_POS = Vector2(-100, 280)

var remaining: int = 0
var _target: Vector2
var _speed: float = 150.0
var _exiting: bool = false
var _count_label: Label

func _ready():
	add_to_group("delivery_workers")
	_target = WAITING_POS

	var body = ColorRect.new()
	body.color = Color(0.25, 0.45, 0.85)
	body.size = Vector2(36, 50)
	body.position = Vector2(-18, -40)
	add_child(body)

	_count_label = Label.new()
	_count_label.position = Vector2(-18, -58)
	_count_label.size = Vector2(36, 18)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 12)
	add_child(_count_label)

	_update_label()

func _process(delta: float):
	var diff = _target - position
	if diff.length() > 3.0:
		position += diff.normalized() * _speed * delta
	elif _exiting:
		queue_free()

func receive_food(_amount: int):
	remaining -= 1
	if remaining <= 0:
		GameState.active_delivery = {}
		GameState.save()
		_exiting = true
		_target = EXIT_POS
	else:
		GameState.active_delivery["remaining"] = remaining
		GameState.save()
	_update_label()

func _update_label():
	if is_instance_valid(_count_label):
		_count_label.text = str(remaining)
