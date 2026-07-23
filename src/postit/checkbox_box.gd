class_name CheckboxBox
extends Control

var BOX_POINTS := PackedVector2Array([
	Vector2(2, 3), Vector2(9, 1), Vector2(20, 2), Vector2(21, 10),
	Vector2(20, 20), Vector2(10, 21), Vector2(1, 19), Vector2(2, 10), Vector2(2, 3),
])
var CHECK_POINTS := PackedVector2Array([
	Vector2(4, 11), Vector2(9, 17), Vector2(19, 3),
])

@export var fill_color: Color = Color(1, 0.94, 0.42, 1)
@export var line_color: Color = Color(0.15, 0.12, 0.05, 1)
@export var line_width: float = 2.2

@export var checked: bool = false:
	set(value):
		checked = value
		queue_redraw()

func _draw() -> void:
	draw_colored_polygon(BOX_POINTS, fill_color)
	draw_polyline(BOX_POINTS, line_color, line_width, true)
	if checked:
		draw_polyline(CHECK_POINTS, line_color, line_width, true)
