extends Node2D

const KEY_SIZE := Vector2(32.0, 30.0)
const KEY_GAP := 4.0
const KEY_PRESS_OFFSET := 3.0
const FONT_SIZE := 6
const KEY_CAP_DEPTH := 5.0
const PERSPECTIVE_TOP_SCALE := 0.8
const PERSPECTIVE_DEPTH_SCALE := 0.7
const FRONT_LIP_DEPTH := 20.0

const BODY_COLOR := Color("b8b4a3")
const BODY_HIGHLIGHT_COLOR := Color("ebe5d2")
const BODY_SHADOW_COLOR := Color("5e5b53")
const KEY_COLOR := Color("e7e2d1")
const MODIFIER_KEY_COLOR := Color("bcb9ad")
const KEY_HIGHLIGHT_COLOR := Color("fffbea")
const KEY_SHADOW_COLOR := Color("706d65")
const KEY_TEXT_COLOR := Color("292923")
const PRESSED_KEY_COLOR := Color("697078")
const PRESSED_KEY_HIGHLIGHT_COLOR := Color("9aa1a7")
const PRESSED_KEY_SHADOW_COLOR := Color("3e4348")
const PRESSED_KEY_TEXT_COLOR := Color("ffffff")

var keys: Array[Dictionary] = []
var pressed_keys: Dictionary = {}
var keyboard_size := Vector2.ZERO


func _ready() -> void:
	_build_layout()
	queue_redraw()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null:
		return

	var key_id := _key_id_for_event(key_event)
	if key_id.is_empty():
		return

	pressed_keys[key_id] = event.pressed
	queue_redraw()


func _draw() -> void:
	if keys.is_empty():
		return

	var body_rect := Rect2(Vector2(-16.0, -18.0), keyboard_size + Vector2(32.0, 32.0))
	var body_quad := _project_rect(body_rect)
	body_quad[0].x += 9.0 # Top-left inward.
	body_quad[1].x -= 9.0 # Top-right inward.
	var front_lip := PackedVector2Array([
		body_quad[3],
		body_quad[2],
		body_quad[2] + Vector2(4.0, FRONT_LIP_DEPTH),
		body_quad[3] + Vector2(-4.0, FRONT_LIP_DEPTH),
	])
	draw_colored_polygon(front_lip, BODY_SHADOW_COLOR)
	draw_colored_polygon(body_quad, BODY_COLOR)
	draw_line(body_quad[0], body_quad[1], BODY_HIGHLIGHT_COLOR, 3.0)
	draw_line(body_quad[0], body_quad[3], BODY_HIGHLIGHT_COLOR, 3.0)
	draw_line(body_quad[3], body_quad[2], BODY_SHADOW_COLOR, 4.0)
	draw_line(body_quad[2], body_quad[1], BODY_SHADOW_COLOR, 4.0)

	var font := ThemeDB.fallback_font
	for key in keys:
		var is_pressed: bool = pressed_keys.get(key.id, false)
		var rect: Rect2 = key.rect
		if is_pressed:
			rect.position.y += KEY_PRESS_OFFSET

		var key_color: Color = PRESSED_KEY_COLOR if is_pressed else (MODIFIER_KEY_COLOR if _is_modifier(key.id) else KEY_COLOR)
		var highlight_color: Color = PRESSED_KEY_HIGHLIGHT_COLOR if is_pressed else KEY_HIGHLIGHT_COLOR
		var shadow_color: Color = PRESSED_KEY_SHADOW_COLOR if is_pressed else KEY_SHADOW_COLOR
		var cap_rect := Rect2(rect.position, Vector2(rect.size.x, rect.size.y - KEY_CAP_DEPTH))
		var key_quad := _project_rect(rect)
		var cap_quad := _project_rect(cap_rect)
		draw_colored_polygon(key_quad, shadow_color)
		draw_colored_polygon(cap_quad, key_color)
		draw_line(cap_quad[0], cap_quad[1], highlight_color, 2.0)
		draw_line(cap_quad[0], cap_quad[3], highlight_color, 2.0)
		draw_line(cap_quad[3], cap_quad[2], shadow_color, 2.0)
		draw_line(cap_quad[2], cap_quad[1], shadow_color, 2.0)

		var base_font_size := 12 if key.label.length() > 2 else FONT_SIZE
		var font_size := maxi(10, roundi(base_font_size * _perspective_scale(rect.get_center().y)))
		var projected_height := cap_quad[3].y - cap_quad[0].y
		var text_y := cap_quad[0].y + (projected_height + font_size) * 0.5 - 2.0
		draw_string(font, Vector2(cap_quad[0].x, text_y), key.label, HORIZONTAL_ALIGNMENT_CENTER, cap_quad[1].x - cap_quad[0].x, font_size, PRESSED_KEY_TEXT_COLOR if is_pressed else KEY_TEXT_COLOR)


func _project_rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		_project_point(rect.position),
		_project_point(Vector2(rect.end.x, rect.position.y)),
		_project_point(rect.end),
		_project_point(Vector2(rect.position.x, rect.end.y)),
	])


func _project_point(point: Vector2) -> Vector2:
	var perspective_scale := _perspective_scale(point.y)
	var center_x := keyboard_size.x * 0.5
	return Vector2(center_x + (point.x - center_x) * perspective_scale, point.y * PERSPECTIVE_DEPTH_SCALE)


func _perspective_scale(y: float) -> float:
	var depth := clampf(y / keyboard_size.y, 0.0, 1.0)
	return lerpf(PERSPECTIVE_TOP_SCALE, 1.0, depth)


func _build_layout() -> void:
	keys.clear()
	keyboard_size = Vector2.ZERO
	_add_row(["GRAVE", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "MINUS", "EQUAL", "BACKSPACE"], 0.0, 0.0, [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0])
	_add_row(["TAB", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "LEFT_BRACKET", "RIGHT_BRACKET", "BACKSLASH"], 0.0, 1.0, [1.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.5])
	_add_row(["CAPS_LOCK", "A", "S", "D", "F", "G", "H", "J", "K", "L", "SEMICOLON", "APOSTROPHE", "ENTER"], 0.0, 2.0, [1.75, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.25])
	_add_row(["SHIFT", "Z", "X", "C", "V", "B", "N", "M", "COMMA", "PERIOD", "SLASH", "SHIFT"], 0.0, 3.0, [2.25, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.75])
	_add_row(["CONTROL", "ALT", "SPACE", "ALT", "CONTROL"], 0.0, 4.0, [1.5, 1.5, 6.0, 1.5, 1.5])
	_add_key("UP", 16.0, 3.0)
	_add_key("LEFT", 15.0, 4.0)
	_add_key("DOWN", 16.0, 4.0)
	_add_key("RIGHT", 17.0, 4.0)

	for key in keys:
		keyboard_size.x = maxf(keyboard_size.x, key.rect.end.x)
		keyboard_size.y = maxf(keyboard_size.y, key.rect.end.y)


func _add_row(labels: Array[String], start_x: float, row: float, widths: Array[float] = []) -> void:
	var x := start_x
	for index in labels.size():
		var width := widths[index] if not widths.is_empty() else 1.0
		_add_key(labels[index], x, row, width)
		x += width


func _add_key(key_id: String, x_units: float, y_units: float, width_units := 1.0) -> void:
	var width := KEY_SIZE.x * width_units + KEY_GAP * (width_units - 1.0)
	var key_position := Vector2(x_units * (KEY_SIZE.x + KEY_GAP), y_units * (KEY_SIZE.y + KEY_GAP))
	keys.append({
		"id": key_id,
		"label": _label_for_key(key_id),
		"rect": Rect2(key_position, Vector2(width, KEY_SIZE.y)),
	})


func _key_id_for_event(event: InputEventKey) -> String:
	var keycode := event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	match keycode:
		KEY_QUOTELEFT: return "GRAVE"
		KEY_0: return "0"
		KEY_1: return "1"
		KEY_2: return "2"
		KEY_3: return "3"
		KEY_4: return "4"
		KEY_5: return "5"
		KEY_6: return "6"
		KEY_7: return "7"
		KEY_8: return "8"
		KEY_9: return "9"
		KEY_MINUS: return "MINUS"
		KEY_EQUAL: return "EQUAL"
		KEY_BACKSPACE: return "BACKSPACE"
		KEY_TAB: return "TAB"
		KEY_A: return "A"
		KEY_B: return "B"
		KEY_C: return "C"
		KEY_D: return "D"
		KEY_E: return "E"
		KEY_F: return "F"
		KEY_G: return "G"
		KEY_H: return "H"
		KEY_I: return "I"
		KEY_J: return "J"
		KEY_K: return "K"
		KEY_L: return "L"
		KEY_M: return "M"
		KEY_N: return "N"
		KEY_O: return "O"
		KEY_P: return "P"
		KEY_Q: return "Q"
		KEY_R: return "R"
		KEY_S: return "S"
		KEY_T: return "T"
		KEY_U: return "U"
		KEY_V: return "V"
		KEY_W: return "W"
		KEY_X: return "X"
		KEY_Y: return "Y"
		KEY_Z: return "Z"
		KEY_BRACKETLEFT: return "LEFT_BRACKET"
		KEY_BRACKETRIGHT: return "RIGHT_BRACKET"
		KEY_BACKSLASH: return "BACKSLASH"
		KEY_CAPSLOCK: return "CAPS_LOCK"
		KEY_SEMICOLON: return "SEMICOLON"
		KEY_APOSTROPHE: return "APOSTROPHE"
		KEY_ENTER: return "ENTER"
		KEY_COMMA: return "COMMA"
		KEY_PERIOD: return "PERIOD"
		KEY_SLASH: return "SLASH"
		KEY_SHIFT: return "SHIFT"
		KEY_ALT: return "ALT"
		KEY_CTRL: return "CONTROL"
		KEY_SPACE: return "SPACE"
		KEY_UP: return "UP"
		KEY_DOWN: return "DOWN"
		KEY_LEFT: return "LEFT"
		KEY_RIGHT: return "RIGHT"
	return ""


func _label_for_key(key_id: String) -> String:
	match key_id:
		"GRAVE": return "`"
		"MINUS": return "-"
		"EQUAL": return "="
		"BACKSPACE": return "Backspace"
		"TAB": return "Tab"
		"LEFT_BRACKET": return "["
		"RIGHT_BRACKET": return "]"
		"BACKSLASH": return "\\"
		"CAPS_LOCK": return "Caps Lock"
		"SEMICOLON": return ";"
		"APOSTROPHE": return "'"
		"ENTER": return "Enter"
		"COMMA": return ","
		"PERIOD": return "."
		"SLASH": return "/"
		"SHIFT": return "Shift"
		"ALT": return "Alt"
		"CONTROL": return "Ctrl"
		"SPACE": return ""
		"UP": return "^"
		"DOWN": return "v"
		"LEFT": return "<"
		"RIGHT": return ">"
	return key_id


func _is_modifier(key_id: String) -> bool:
	return key_id in ["TAB", "CAPS_LOCK", "SHIFT", "CONTROL", "ALT", "BACKSPACE", "ENTER"]
