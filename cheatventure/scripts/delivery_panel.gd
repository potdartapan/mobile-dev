extends CanvasLayer

signal delivery_accepted(station: FoodStation, quantity: int)

var _offers: Array = []
var _list: VBoxContainer

func _ready():
	add_to_group("delivery_panel")
	_build_shell()
	visible = false

func _build_shell():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.size = Vector2(540, 960)
	add_child(overlay)

	var panel = Panel.new()
	panel.position = Vector2(0, 250)
	panel.size = Vector2(540, 710)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 52)
	vbox.add_child(header)

	var title = Label.new()
	title.text = "  Delivery Orders"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "  X  "
	close_btn.custom_minimum_size = Vector2(52, 52)
	close_btn.pressed.connect(hide_panel)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

func show_panel():
	visible = true
	_rebuild_list()

func hide_panel():
	visible = false

func _rebuild_list():
	for child in _list.get_children():
		child.queue_free()

	if not GameState.active_delivery.is_empty():
		_show_active_status()
		return

	_generate_offers()

	if _offers.is_empty():
		var lbl = Label.new()
		lbl.text = "  Unlock more stations to receive delivery orders."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(lbl)
		return

	var hint = Label.new()
	hint.text = "  Choose one bulk order to accept. Coins paid immediately."
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(0, 48)
	_list.add_child(hint)

	for offer in _offers:
		_add_offer_card(offer)

func _show_active_status():
	var d = GameState.active_delivery
	var info = Label.new()
	info.text = "  Active delivery: %s\n  %d items still being prepared." % [
		d.get("station_name", "?"),
		d.get("remaining", 0)
	]
	info.add_theme_font_size_override("font_size", 15)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(0, 80)
	_list.add_child(info)

	var note = Label.new()
	note.text = "  Complete the current delivery before accepting a new one."
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(note)

func _generate_offers():
	var stations = get_tree().get_nodes_in_group("stations")
	var unlocked: Array = []
	for s in stations:
		if s is FoodStation and s.is_unlocked:
			unlocked.append(s)
	_offers = []
	if unlocked.is_empty():
		return
	for i in 3:
		var station = unlocked[randi() % unlocked.size()]
		var qty = randi_range(5, 15)
		var reward = int(qty * station.coin_reward * 1.5)
		_offers.append({station = station, quantity = qty, reward = reward})

func _add_offer_card(offer: Dictionary):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	_list.add_child(card)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)

	var name_lbl = Label.new()
	name_lbl.text = "  %d× %s" % [offer.quantity, offer.station.station_name]
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)

	var reward_lbl = Label.new()
	reward_lbl.text = "  Reward: %d coins (paid now)" % offer.reward
	reward_lbl.add_theme_font_size_override("font_size", 13)
	reward_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.3))
	info.add_child(reward_lbl)

	var btn = Button.new()
	btn.text = "Accept"
	btn.custom_minimum_size = Vector2(100, 0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _accept_offer(offer))
	row.add_child(btn)

func _accept_offer(offer: Dictionary):
	if not GameState.active_delivery.is_empty():
		return
	GameState.active_delivery = {
		station_name = offer.station.station_name,
		remaining = offer.quantity,
	}
	GameState.add_coins(offer.reward)
	GameState.save()
	delivery_accepted.emit(offer.station, offer.quantity)
	hide_panel()
