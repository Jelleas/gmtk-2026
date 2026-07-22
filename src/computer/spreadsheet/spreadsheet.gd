extends Node2D

const COLS := 8
const ROWS := 12
const CELL_WIDTH := 90
const CELL_HEIGHT := 24

var cell_text: Array = []
var cell_bg: Array = []
var cell_label: Array = []

var current_row := 0
var current_col := 0

func _ready() -> void:
	cell_text.resize(ROWS)
	cell_bg.resize(ROWS)
	cell_label.resize(ROWS)

	for row in range(ROWS):
		cell_text[row] = []
		cell_bg[row] = []
		cell_label[row] = []
		cell_text[row].resize(COLS)
		cell_bg[row].resize(COLS)
		cell_label[row].resize(COLS)

		for col in range(COLS):
			var bg := ColorRect.new()
			bg.position = Vector2(col * CELL_WIDTH, row * CELL_HEIGHT)
			bg.size = Vector2(CELL_WIDTH - 1, CELL_HEIGHT - 1)
			bg.color = Color(1, 1, 1, 1)
			add_child(bg)

			var label := Label.new()
			label.position = Vector2(col * CELL_WIDTH + 4, row * CELL_HEIGHT)
			label.size = Vector2(CELL_WIDTH - 8, CELL_HEIGHT)
			label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			add_child(label)

			cell_text[row][col] = ""
			cell_bg[row][col] = bg
			cell_label[row][col] = label

	_update_selection_visuals()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return

	if event.keycode == KEY_LEFT:
		_move(0, -1)
	elif event.keycode == KEY_RIGHT:
		_move(0, 1)
	elif event.keycode == KEY_UP:
		_move(-1, 0)
	elif event.keycode == KEY_DOWN:
		_move(1, 0)
	elif event.keycode == KEY_BACKSPACE:
		var text: String = cell_text[current_row][current_col]
		if text.length() > 0:
			_set_current_text(text.substr(0, text.length() - 1))
	elif event.unicode >= 32:
		_set_current_text(cell_text[current_row][current_col] + char(event.unicode))
	else:
		return

	get_viewport().set_input_as_handled()

func _move(row_delta: int, col_delta: int) -> void:
	current_row = clampi(current_row + row_delta, 0, ROWS - 1)
	current_col = clampi(current_col + col_delta, 0, COLS - 1)
	_update_selection_visuals()

func _set_current_text(text: String) -> void:
	cell_text[current_row][current_col] = text
	cell_label[current_row][current_col].text = text

func _update_selection_visuals() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			cell_bg[row][col].color = Color(1, 1, 1, 1)
	cell_bg[current_row][current_col].color = Color(0.7, 0.85, 1, 1)
