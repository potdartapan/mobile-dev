extends Node2D
class_name FoodStation

@export var station_name: String = "Cutting Chai"
@export var base_production_time: float = 3.0
@export var base_coin_reward: int = 5
@export var base_upgrade_cost: int = 30
@export var unlock_cost: int = 0
@export var station_color: Color = Color(0.96, 0.77, 0.26)
@export var is_unlocked: bool = false

var level: int = 0
var coin_reward: int
var production_time: float
var profit_multiplier: float = 1.0
var time_multiplier: float = 1.0

var _btn: Button
var _level_label: Label

@onready var _station_label = $StationLabel
@onready var _station_rect = $StationRect

func _ready():
	add_to_group("stations")
	refresh_stats()
	_station_label.text = station_name

	if is_unlocked:
		_station_rect.color = station_color
		_build_upgrade_ui()
	else:
		_station_rect.color = Color(0.35, 0.35, 0.35)
		_build_unlock_ui()

func refresh_stats():
	coin_reward = int(base_coin_reward * (level + 1) * profit_multiplier)
	production_time = max(0.5, (base_production_time - level * 0.15) * time_multiplier)

func _build_unlock_ui():
	_btn = Button.new()
	_btn.position = Vector2(-50, 50)
	_btn.size = Vector2(100, 30)
	_btn.text = "Unlock\n%d c" % unlock_cost
	_btn.pressed.connect(_on_unlock_pressed)
	add_child(_btn)

func _on_unlock_pressed():
	if not GameState.spend_coins(unlock_cost):
		return
	is_unlocked = true
	_station_rect.color = station_color
	_btn.queue_free()
	_btn = null
	_build_upgrade_ui()
	GameState.save()

func _build_upgrade_ui():
	_level_label = Label.new()
	_level_label.position = Vector2(-50, 50)
	_level_label.size = Vector2(100, 18)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.text = "Lv. 0"
	add_child(_level_label)

	_btn = Button.new()
	_btn.position = Vector2(-50, 68)
	_btn.size = Vector2(100, 28)
	_btn.text = _btn_text()
	_btn.pressed.connect(_on_upgrade_pressed)
	add_child(_btn)

func _on_upgrade_pressed():
	var cost = _upgrade_cost()
	if not GameState.spend_coins(cost):
		return
	level += 1
	refresh_stats()
	_level_label.text = "Lv. " + str(level)
	_btn.text = _btn_text()
	GameState.save()

func apply_save_data(data: Dictionary) -> void:
	var saved_unlocked: bool = data.get("unlocked", false)
	var saved_level: int = data.get("level", 0)

	# Unlock the station if save says it should be open
	if saved_unlocked and not is_unlocked:
		is_unlocked = true
		_station_rect.color = station_color
		if _btn != null:
			_btn.queue_free()
			_btn = null
		_build_upgrade_ui()

	if saved_level > 0:
		level = saved_level
		refresh_stats()
		if _level_label != null:
			_level_label.text = "Lv. " + str(level)
		if _btn != null:
			_btn.text = _btn_text()

func _upgrade_cost() -> int:
	return int(base_upgrade_cost * pow(1.35, level))

func _btn_text() -> String:
	return "Up %d c" % _upgrade_cost()
