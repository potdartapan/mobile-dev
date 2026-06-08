extends Node2D

const WAITER_SPAWN_POSITIONS = [
	Vector2(270, 450), Vector2(180, 450), Vector2(360, 450),
	Vector2(130, 450), Vector2(410, 450),
]

const CHEF_SPAWN_POSITIONS = [
	Vector2(270, 630), Vector2(160, 630), Vector2(380, 630),
	Vector2(100, 630), Vector2(440, 630),
]

const STATION_DATA = [
	{name="Cutting Chai",   color=Color(0.96,0.77,0.26), prod_time=2.0, reward=5,   upgrade_cost=30,  unlock_cost=0},
	{name="Vada Pav",       color=Color(0.87,0.56,0.17), prod_time=2.5, reward=10,  upgrade_cost=60,  unlock_cost=150},
	{name="Pav Bhaji",      color=Color(0.85,0.33,0.15), prod_time=3.0, reward=18,  upgrade_cost=100, unlock_cost=400},
	{name="Filter Coffee",  color=Color(0.45,0.28,0.15), prod_time=3.0, reward=18,  upgrade_cost=100, unlock_cost=800},
	{name="Momos",          color=Color(0.85,0.85,0.85), prod_time=3.5, reward=30,  upgrade_cost=160, unlock_cost=2000},
	{name="Dosa",           color=Color(0.95,0.85,0.45), prod_time=4.0, reward=45,  upgrade_cost=220, unlock_cost=5000},
	{name="Chhole Bhature", color=Color(0.95,0.65,0.25), prod_time=5.0, reward=70,  upgrade_cost=300, unlock_cost=12000},
	{name="Biryani",        color=Color(0.75,0.45,0.15), prod_time=6.0, reward=120, upgrade_cost=450, unlock_cost=30000},
]

const STATION_POSITIONS = [
	Vector2(75, 530), Vector2(205, 530), Vector2(335, 530), Vector2(465, 530),
	Vector2(75, 710), Vector2(205, 710), Vector2(335, 710), Vector2(465, 710),
]

var _station_scene        = preload("res://scenes/station.tscn")
var _customer_scene       = preload("res://scenes/customer.tscn")
var _waiter_scene         = preload("res://scenes/waiter.tscn")
var _chef_scene           = preload("res://scenes/chef.tscn")
var _delivery_man_script  = preload("res://scripts/delivery_man.gd")

@onready var _stations_node  = $Stations
@onready var _characters     = $Characters
@onready var _customers_node = $Customers
@onready var _spawn_point    = $SpawnPoint

const BASE_SPAWN_TIME = 4.0

func _ready():
	$SpawnTimer.add_to_group("spawn_timer")
	$SpawnTimer.timeout.connect(_spawn_customer)
	_build_stations()
	_apply_save()
	_spawn_waiter(WAITER_SPAWN_POSITIONS[0])
	_spawn_chef(CHEF_SPAWN_POSITIONS[0])
	for i in GameState.upgrade_counts.get("hire_waiter", 0):
		_spawn_waiter(WAITER_SPAWN_POSITIONS[i + 1])
	for i in GameState.upgrade_counts.get("hire_chef", 0):
		_spawn_chef(CHEF_SPAWN_POSITIONS[i + 1])
	var adv_n = GameState.upgrade_counts.get("advertise", 0)
	if adv_n > 0:
		$SpawnTimer.wait_time = max(1.0, BASE_SPAWN_TIME * pow(0.8, adv_n))
	$UpgradePanel.hire_waiter_requested.connect(_on_hire_waiter)
	$UpgradePanel.hire_chef_requested.connect(_on_hire_chef)
	$DeliveryPanel.delivery_accepted.connect(_on_delivery_accepted)
	_restore_delivery()

func _build_stations():
	for i in STATION_DATA.size():
		var d = STATION_DATA[i]
		var station = _station_scene.instantiate()
		station.position = STATION_POSITIONS[i]
		station.station_name         = d.name
		station.station_color        = d.color
		station.base_production_time = d.prod_time
		station.base_coin_reward     = d.reward
		station.base_upgrade_cost    = d.upgrade_cost
		station.unlock_cost          = d.unlock_cost
		station.is_unlocked          = (i == 0)
		_stations_node.add_child(station)

func _apply_save():
	var data = GameState.load_save()
	if data.is_empty():
		return

	GameState.coins = data.get("coins", 0)
	GameState.coins_changed.emit(GameState.coins)
	GameState.upgrade_counts = data.get("upgrades", {})
	GameState.active_delivery = data.get("active_delivery", {})

	var stations = get_tree().get_nodes_in_group("stations")
	for saved in data.get("stations", []):
		for station in stations:
			if station is FoodStation and station.station_name == saved.get("name", ""):
				station.apply_save_data(saved)
				break

	# Re-apply panel upgrade effects on top of level-based stats
	for station in stations:
		if not station is FoodStation:
			continue
		var cook_n = GameState.upgrade_counts.get("cook_speed_" + station.station_name, 0)
		station.time_multiplier = pow(0.85, cook_n)
		if GameState.upgrade_counts.get("double_profit_" + station.station_name, 0) > 0:
			station.profit_multiplier = 2.0
		station.refresh_stats()

func _spawn_waiter(pos: Vector2):
	var w = _waiter_scene.instantiate()
	w.position = pos
	_characters.add_child(w)

func _spawn_chef(pos: Vector2):
	var c = _chef_scene.instantiate()
	c.position = pos
	_characters.add_child(c)

func _spawn_customer():
	var c = _customer_scene.instantiate()
	c.position = _spawn_point.position
	c.coins_earned.connect(_on_coins_earned)
	_customers_node.add_child(c)

func _on_hire_waiter(hire_index: int):
	if hire_index < WAITER_SPAWN_POSITIONS.size():
		_spawn_waiter(WAITER_SPAWN_POSITIONS[hire_index])

func _on_hire_chef(hire_index: int):
	if hire_index < CHEF_SPAWN_POSITIONS.size():
		_spawn_chef(CHEF_SPAWN_POSITIONS[hire_index])

func _on_delivery_accepted(station: FoodStation, quantity: int):
	var dm = _spawn_delivery_man(quantity)
	for i in quantity:
		GameState.cooking_queue.append({customer = dm, station = station})

func _spawn_delivery_man(qty: int) -> Node2D:
	var dm = Node2D.new()
	dm.set_script(_delivery_man_script)
	dm.remaining = qty
	dm.position = Vector2(-100, 280)
	_characters.add_child(dm)
	return dm

func _restore_delivery():
	var d = GameState.active_delivery
	if d.is_empty():
		return
	var station_name: String = d.get("station_name", "")
	var remaining: int = d.get("remaining", 0)
	if station_name.is_empty() or remaining <= 0:
		GameState.active_delivery = {}
		return
	var target_station: FoodStation = null
	for s in get_tree().get_nodes_in_group("stations"):
		if s is FoodStation and s.station_name == station_name:
			target_station = s
			break
	if target_station == null:
		GameState.active_delivery = {}
		return
	var dm = _spawn_delivery_man(remaining)
	for i in remaining:
		GameState.cooking_queue.append({customer = dm, station = target_station})

func _on_coins_earned(amount: int):
	GameState.add_coins(amount)
