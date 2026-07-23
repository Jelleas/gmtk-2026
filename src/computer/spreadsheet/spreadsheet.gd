extends Control

class_name Spreadsheet

signal cell_text_changed(row: int, col: int, text: String)

const COLS := 8
const ROWS := 12
const ROW_HEADER_WIDTH := 32.0
const HEADER_COLOR := Color(0.75, 0.75, 0.75, 1)
const HEADER_BORDER_COLOR := Color(0.4, 0.4, 0.4, 1)

var cell_edits: Array = []
var top_bar_label: Label
var top_bar_background: ColorRect
var status_message := ""
var col_header_labels: Array = []
var row_header_labels: Array = []
var corner_box: Label

var current_row := 0
var current_col := 0

func _ready() -> void:
	_build_top_bar()
	_build_headers()

	cell_edits.resize(ROWS)

	for row in range(ROWS):
		cell_edits[row] = []
		cell_edits[row].resize(COLS)

		for col in range(COLS):
			var edit := LineEdit.new()
			edit.add_theme_font_size_override("font_size", 14)
			edit.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.45, 1))
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

func _build_headers() -> void:
	corner_box = _make_header_label("")
	add_child(corner_box)

	col_header_labels.resize(COLS)
	for col in range(COLS):
		var label := _make_header_label(char(65 + col))
		add_child(label)
		col_header_labels[col] = label

	row_header_labels.resize(ROWS)
	for row in range(ROWS):
		var label := _make_header_label(str(row + 1))
		add_child(label)
		row_header_labels[row] = label

func _make_header_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	label.add_theme_stylebox_override("normal", _make_header_stylebox())
	return label

func _make_header_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEADER_COLOR
	style.set_border_width_all(1)
	style.border_color = HEADER_BORDER_COLOR
	return style

func _layout_content() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var cell_size := Vector2(
		floorf((size.x - ROW_HEADER_WIDTH) / COLS),
		floorf(size.y / (ROWS + 2.0)),
	)
	var grid_size := Vector2(cell_size.x * COLS + ROW_HEADER_WIDTH, cell_size.y * (ROWS + 2))
	var grid_offset := (size - grid_size) / 2.0
	var top_bar_height := cell_size.y
	var col_header_height := cell_size.y
	var col_header_y := grid_offset.y + top_bar_height
	var cells_y := col_header_y + col_header_height
	var cells_x := grid_offset.x + ROW_HEADER_WIDTH

	top_bar_background.position = grid_offset
	top_bar_background.size = Vector2(grid_size.x, top_bar_height)
	top_bar_label.position = grid_offset + Vector2(4.0, 0.0)
	top_bar_label.size = Vector2(grid_size.x - 8.0, top_bar_height)

	corner_box.position = Vector2(grid_offset.x, col_header_y)
	corner_box.size = Vector2(ROW_HEADER_WIDTH, col_header_height)

	for col in range(COLS):
		var label: Label = col_header_labels[col]
		label.position = Vector2(cells_x + col * cell_size.x, col_header_y)
		label.size = cell_size + Vector2.ONE

	for row in range(ROWS):
		var label: Label = row_header_labels[row]
		label.position = Vector2(grid_offset.x, cells_y + row * cell_size.y)
		label.size = Vector2(ROW_HEADER_WIDTH, cell_size.y) + Vector2.ONE

	for row in range(ROWS):
		for col in range(COLS):
			var edit: LineEdit = cell_edits[row][col]
			edit.position = Vector2(cells_x + col * cell_size.x, cells_y + row * cell_size.y)
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
	# select_all() puts the caret/selection over the whole existing value so the
	# next keystroke (typing or Backspace/Delete) immediately replaces it, matching
	# what a mouse click into the cell would do.
	cell_edits[current_row][current_col].grab_focus()
	cell_edits[current_row][current_col].edit()
	cell_edits[current_row][current_col].select_all()
