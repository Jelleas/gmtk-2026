extends Control

signal cell_text_changed(row: int, col: int, text: String)

const COLS := 8
const ROWS := 12

var cell_edits: Array = []
var top_bar_label: Label
var top_bar_background: ColorRect
var status_message := ""

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
			edit.add_theme_font_size_override("font_size", 14)
			edit.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			edit.add_theme_stylebox_override("normal", _make_stylebox(Color(1, 1, 1, 1)))
			edit.add_theme_stylebox_override("focus", _make_stylebox(Color(0.7, 0.85, 1, 1)))
			edit.focus_entered.connect(_on_cell_focus_entered.bind(row, col))
			edit.text_changed.connect(_on_cell_text_changed.bind(row, col))
			add_child(edit)

			cell_edits[row][col] = edit

	resized.connect(_layout_content)
	_layout_content()
	call_deferred(&"_layout_content")
	cell_edits[current_row][current_col].grab_focus()
	_update_top_bar()

func _build_top_bar() -> void:
	top_bar_background = ColorRect.new()
	top_bar_background.color = Color(0.9, 0.9, 0.9, 1)
	add_child(top_bar_background)

	top_bar_label = Label.new()
	top_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar_label.add_theme_font_size_override("font_size", 14)
	top_bar_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	add_child(top_bar_label)

func _layout_content() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var cell_size := Vector2(
		floorf(size.x / COLS),
		floorf(size.y / (ROWS + 1.0)),
	)
	var grid_size := Vector2(cell_size.x * COLS, cell_size.y * (ROWS + 1))
	var grid_offset := (size - grid_size) / 2.0
	var top_bar_height := cell_size.y
	top_bar_background.position = grid_offset
	top_bar_background.size = Vector2(grid_size.x, top_bar_height)
	top_bar_label.position = grid_offset + Vector2(4.0, 0.0)
	top_bar_label.size = Vector2(grid_size.x - 8.0, top_bar_height)

	for row in range(ROWS):
		for col in range(COLS):
			var edit: LineEdit = cell_edits[row][col]
			edit.position = grid_offset + Vector2(col * cell_size.x, top_bar_height + row * cell_size.y)
			edit.size = cell_size + Vector2.ONE

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

func set_cell_text(row: int, col: int, text: String) -> void:
	cell_edits[row][col].text = text

func get_cell_text(row: int, col: int) -> String:
	return cell_edits[row][col].text

func set_cell_placeholder(row: int, col: int, text: String) -> void:
	cell_edits[row][col].placeholder_text = text

func set_cell_highlighted(row: int, col: int, highlighted: bool) -> void:
	var edit: LineEdit = cell_edits[row][col]
	var normal_color := Color(1.0, 0.85, 0.55, 1.0) if highlighted else Color(1, 1, 1, 1)
	var focus_color := Color(1.0, 0.75, 0.35, 1.0) if highlighted else Color(0.7, 0.85, 1, 1)
	edit.add_theme_stylebox_override("normal", _make_stylebox(normal_color))
	edit.add_theme_stylebox_override("focus", _make_stylebox(focus_color))

func clear_cells() -> void:
	for row in range(ROWS):
		for col in range(COLS):
			set_cell_text(row, col, "")
			set_cell_placeholder(row, col, "")
			set_cell_highlighted(row, col, false)

func set_status_message(message: String) -> void:
	status_message = message
	_update_top_bar()

func _on_cell_focus_entered(row: int, col: int) -> void:
	current_row = row
	current_col = col
	_update_top_bar()

func _on_cell_text_changed(_new_text: String, row: int, col: int) -> void:
	if row == current_row and col == current_col:
		_update_top_bar()
	cell_text_changed.emit(row, col, _new_text)

func _update_top_bar() -> void:
	top_bar_label.text = status_message if not status_message.is_empty() else cell_edits[current_row][current_col].text

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return

	# Only intercept plain (unmodified) arrow keys to move the selected cell.
	# Everything else - typing, backspace, and shortcuts like Ctrl/Cmd+C/V/A/Z -
	# is left to fall through to the focused LineEdit's own native GUI input.
	if event.is_command_or_control_pressed() or event.shift_pressed or event.alt_pressed:
		return

	if event.keycode == KEY_LEFT:
		_move(0, -1)
	elif event.keycode == KEY_RIGHT:
		_move(0, 1)
	elif event.keycode == KEY_UP:
		_move(-1, 0)
	elif event.keycode == KEY_DOWN:
		_move(1, 0)
	else:
		return

	get_viewport().set_input_as_handled()

func _move(row_delta: int, col_delta: int) -> void:
	current_row = clampi(current_row + row_delta, 0, ROWS - 1)
	current_col = clampi(current_col + col_delta, 0, COLS - 1)
	# Deferred: grabbing focus synchronously from within the _input() call that
	# triggered it leaves the viewport's GUI key-focus dispatch in a broken
	# state (has_focus() reports true, but subsequent keystrokes silently
	# never reach the control). Deferring avoids this Godot quirk.
	cell_edits[current_row][current_col].grab_focus()
	cell_edits[current_row][current_col].edit()
