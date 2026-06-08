extends Node2D
class_name FoodItem

static func create_for_station(station: FoodStation) -> Node2D:
	var item = Node2D.new()
	var poly = Polygon2D.new()
	poly.polygon = _get_verts(station.station_name)
	poly.color = _get_color(station.station_name)
	item.add_child(poly)
	return item

static func _get_verts(name: String) -> PackedVector2Array:
	match name:
		"Cutting Chai":
			# Cup / trapezoid — wider at bottom
			return PackedVector2Array([
				Vector2(-5, -11), Vector2(5, -11),
				Vector2(9, 11), Vector2(-9, 11)
			])
		"Vada Pav":
			# Circle (hexagon)
			return _ngon(6, 11)
		"Pav Bhaji":
			# Wide blob (8-point oval)
			return _ngon_ellipse(8, 13, 9)
		"Filter Coffee":
			# Diamond
			return PackedVector2Array([
				Vector2(0, -12), Vector2(10, 0),
				Vector2(0, 11), Vector2(-10, 0)
			])
		"Momos":
			# Dumpling — upper half circle with flat bottom
			return _upper_semicircle(11)
		"Dosa":
			# Long thin plank
			return PackedVector2Array([
				Vector2(-15, -5), Vector2(15, -5),
				Vector2(15, 5), Vector2(-15, 5)
			])
		"Chhole Bhature":
			# Pentagon
			return _ngon(5, 11)
		"Biryani":
			# Triangle
			return PackedVector2Array([
				Vector2(0, -13), Vector2(12, 11), Vector2(-12, 11)
			])
		_:
			return _ngon(4, 10)

static func _get_color(name: String) -> Color:
	match name:
		"Cutting Chai":    return Color(0.65, 0.38, 0.12)
		"Vada Pav":        return Color(0.95, 0.78, 0.25)
		"Pav Bhaji":       return Color(0.90, 0.40, 0.12)
		"Filter Coffee":   return Color(0.35, 0.18, 0.06)
		"Momos":           return Color(0.95, 0.92, 0.85)
		"Dosa":            return Color(0.96, 0.88, 0.35)
		"Chhole Bhature":  return Color(0.92, 0.68, 0.22)
		"Biryani":         return Color(0.96, 0.68, 0.12)
		_:                 return Color(0.8, 0.8, 0.8)

static func _ngon(n: int, r: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = (float(i) / n) * TAU - PI / 2.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts

static func _ngon_ellipse(n: int, rx: float, ry: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in n:
		var a = (float(i) / n) * TAU - PI / 2.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func _upper_semicircle(r: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var steps = 8
	for i in range(steps + 1):
		# PI → 2*PI traces the upper arc (y goes negative = upward on screen)
		var a = PI + (float(i) / steps) * PI
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts
