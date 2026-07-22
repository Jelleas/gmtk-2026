extends Node2D

const COLS := 8
const ROWS := 12
const CELL_WIDTH := 90
const CELL_HEIGHT := 24
const TOP_BAR_HEIGHT := 24

var cell_edits: Array = []
var top_bar_label: Label

var current_row := 0
var current_col := 0

func _ready() -> void:
	_build_top_bar()

	cell_edits.resize(ROWS)

	for row in range(ROWS):
		cell_edits[row] = []
		cell_edits[row].resize(COLS)

		for col in range(COLS):
			var edit := LineEdit.new()
			edit.position = Vector2(col * CELL_WIDTH, TOP_BAR_HEIGHT + row * CELL_HEIGHT)
			edit.size = Vector2(CELL_WIDTH - 1, CELL_HEIGHT - 1)
			edit.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			edit.add_theme_stylebox_override("normal", _make_stylebox(Color(1, 1, 1, 1)))
			edit.add_theme_stylebox_override("focus", _make_stylebox(Color(0.7, 0.85, 1, 1)))
			edit.focus_entered.connect(_on_cell_focus_entered.bind(row, col))
			add_child(edit)

			cell_edits[row][col] = edit

	cell_edits[current_row][current_col].grab_focus()
	_update_top_bar()

func _build_top_bar() -> void:
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(0, 0)
	bar_bg.size = Vector2(COLS * CELL_WIDTH, TOP_BAR_HEIGHT)
	bar_bg.color = Color(0.9, 0.9, 0.9, 1)
	add_child(bar_bg)

	top_bar_label = Label.new()
	top_bar_label.position = Vector2(4, 0)
	top_bar_label.size = Vector2(COLS * CELL_WIDTH - 8, TOP_BAR_HEIGHT)
	top_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	add_child(top_bar_label)

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(1)
	style.border_color = Color(0.6, 0.6, 0.6, 1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func _on_cell_focus_entered(row: int, col: int) -> void:
	current_row = row
	current_col = col
	_update_top_bar()

func _update_top_bar() -> void:
	top_bar_label.text = cell_edits[current_row][current_col].text

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return

	var current_edit: LineEdit = cell_edits[current_row][current_col]

	if event.keycode == KEY_LEFT:
		_move(0, -1)
	elif event.keycode == KEY_RIGHT:
		_move(0, 1)
	elif event.keycode == KEY_UP:
		_move(-1, 0)
	elif event.keycode == KEY_DOWN:
		_move(1, 0)
	elif event.keycode == KEY_BACKSPACE:
		var text := current_edit.text
		if text.length() > 0:
			current_edit.text = text.substr(0, text.length() - 1)
			current_edit.caret_column = current_edit.text.length()
			_update_top_bar()
	elif event.unicode >= 32:
		current_edit.text += char(event.unicode)
		current_edit.caret_column = current_edit.text.length()
		_update_top_bar()
	else:
		return

	get_viewport().set_input_as_handled()

func _move(row_delta: int, col_delta: int) -> void:
	cell_edits[current_row][current_col].release_focus()
	current_row = clampi(current_row + row_delta, 0, ROWS - 1)
	current_col = clampi(current_col + col_delta, 0, COLS - 1)
	cell_edits[current_row][current_col].grab_focus()
