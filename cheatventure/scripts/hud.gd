extends CanvasLayer

@onready var _coin_label = $CoinLabel

func _ready():
	GameState.coins_changed.connect(_on_coins_changed)
	var upgrades_btn = Button.new()
	upgrades_btn.text = "Upgrades"
	upgrades_btn.position = Vector2(10, 910)
	upgrades_btn.size = Vector2(255, 44)
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	add_child(upgrades_btn)

	var delivery_btn = Button.new()
	delivery_btn.text = "Delivery"
	delivery_btn.position = Vector2(275, 910)
	delivery_btn.size = Vector2(255, 44)
	delivery_btn.pressed.connect(_on_delivery_pressed)
	add_child(delivery_btn)

func _on_upgrades_pressed():
	var panel = get_tree().get_first_node_in_group("upgrade_panel")
	if is_instance_valid(panel):
		panel.show_panel()

func _on_delivery_pressed():
	var panel = get_tree().get_first_node_in_group("delivery_panel")
	if is_instance_valid(panel):
		panel.show_panel()

func _on_coins_changed(amount: int):
	_coin_label.text = "Coins: " + str(amount)
