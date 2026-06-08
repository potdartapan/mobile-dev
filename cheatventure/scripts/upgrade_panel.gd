extends CanvasLayer

signal hire_waiter_requested(hire_index: int)
signal hire_chef_requested(hire_index: int)

const GLOBAL_UPGRADES = [
	{id = "hire_waiter",  label = "Hire Waiter",           base_cost = 500,  cost_scale = 3.0, max_count = 4},
	{id = "hire_chef",    label = "Hire Chef",              base_cost = 800,  cost_scale = 3.0, max_count = 4},
	{id = "waiter_speed", label = "Waiter Speed +20%",      base_cost = 400,  cost_scale = 2.0, max_count = 5},
	{id = "chef_speed",   label = "Chef Speed +20%",        base_cost = 400,  cost_scale = 2.0, max_count = 5},
	{id = "advertise",    label = "Advertise (-20% spawn)", base_cost = 600,  cost_scale = 2.5, max_count = 5},
]

var _list: VBoxContainer

func _ready():
	add_to_group("upgrade_panel")
	_build_shell()
	visible = false

func _build_shell():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.size = Vector2(540, 960)
	add_child(overlay)

	var panel = Panel.new()
	panel.position = Vector2(0, 220)
	panel.size = Vector2(540, 740)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 52)
	vbox.add_child(header)

	var title = Label.new()
	title.text = "  Upgrades"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "  X  "
	close_btn.custom_minimum_size = Vector2(52, 52)
	close_btn.pressed.connect(hide_panel)
	header.add_child(close_btn)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)

func show_panel():
	visible = true
	_rebuild_list()

func hide_panel():
	visible = false

func _rebuild_list():
	for child in _list.get_children():
		child.queue_free()

	_add_section("Workers & Speed")
	for u in GLOBAL_UPGRADES:
		_add_global_row(u)

	var stations = get_tree().get_nodes_in_group("stations")
	var unlocked: Array = []
	for s in stations:
		if s is FoodStation and s.is_unlocked:
			unlocked.append(s)

	if unlocked.size() > 0:
		_add_section("Cook Speed  (-15% per purchase, up to 5×)")
		for station in unlocked:
			_add_station_row(station, "cook_speed")

		_add_section("2× Profit  (one-time per item)")
		for station in unlocked:
			_add_station_row(station, "double_profit")

func _add_section(text: String):
	var lbl = Label.new()
	lbl.text = "  " + text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.3))
	lbl.custom_minimum_size = Vector2(0, 36)
	_list.add_child(lbl)

func _add_global_row(u: Dictionary):
	var count = GameState.upgrade_counts.get(u.id, 0)
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	_list.add_child(row)

	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.add_theme_font_size_override("font_size", 13)

	if count >= u.max_count:
		lbl.text = "  " + u.label + "  (MAX)"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(lbl)
		return

	lbl.text = "  " + u.label + "  (%d/%d)" % [count, u.max_count]
	var cost = int(u.base_cost * pow(u.cost_scale, count))

	var btn = Button.new()
	btn.text = "%d c" % cost
	btn.custom_minimum_size = Vector2(110, 0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _buy_global(u, cost))

	row.add_child(lbl)
	row.add_child(btn)

func _buy_global(u: Dictionary, cost: int):
	if not GameState.spend_coins(cost):
		return
	var new_count = GameState.upgrade_counts.get(u.id, 0) + 1
	GameState.upgrade_counts[u.id] = new_count
	_apply_global_upgrade(u.id, new_count)
	GameState.save()
	_rebuild_list()

func _apply_global_upgrade(id: String, new_count: int):
	match id:
		"hire_waiter":
			hire_waiter_requested.emit(new_count)
		"hire_chef":
			hire_chef_requested.emit(new_count)
		"waiter_speed":
			for w in get_tree().get_nodes_in_group("waiters"):
				w._speed *= 1.2
		"chef_speed":
			for c in get_tree().get_nodes_in_group("chefs"):
				c._speed *= 1.2
		"advertise":
			for t in get_tree().get_nodes_in_group("spawn_timer"):
				t.wait_time = max(1.0, t.wait_time * 0.8)

func _add_station_row(station: FoodStation, upgrade_type: String):
	var uid = upgrade_type + "_" + station.station_name
	var count = GameState.upgrade_counts.get(uid, 0)
	var max_count = 1 if upgrade_type == "double_profit" else 5

	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	_list.add_child(row)

	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.add_theme_font_size_override("font_size", 13)

	if count >= max_count:
		lbl.text = "  " + station.station_name + "  (MAX)"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(lbl)
		return

	var base_cost: int
	if upgrade_type == "cook_speed":
		base_cost = station.base_upgrade_cost * 2
		lbl.text = "  " + station.station_name + "  (%d/%d)" % [count, max_count]
	else:
		base_cost = station.base_coin_reward * 20
		lbl.text = "  " + station.station_name

	var cost = int(base_cost * pow(2.0, count))

	var btn = Button.new()
	btn.text = "%d c" % cost
	btn.custom_minimum_size = Vector2(110, 0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _buy_station(uid, upgrade_type, station, cost))

	row.add_child(lbl)
	row.add_child(btn)

func _buy_station(uid: String, upgrade_type: String, station: FoodStation, cost: int):
	if not GameState.spend_coins(cost):
		return
	GameState.upgrade_counts[uid] = GameState.upgrade_counts.get(uid, 0) + 1
	if upgrade_type == "cook_speed":
		station.time_multiplier *= 0.85
	else:
		station.profit_multiplier *= 2.0
	station.refresh_stats()
	GameState.save()
	_rebuild_list()
