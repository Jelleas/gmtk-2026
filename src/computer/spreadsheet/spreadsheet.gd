extends Control

class_name Spreadsheet

signal cell_text_changed(row: int, col: int, text: String)

const COLS := 8
const ROWS := 12
const ROW_HEADER_WIDTH := 32.0
const HEADER_HEIGHT := 20.0
const CELL_FONT_SIZE := 10
const MIN_CELL_FONT_SIZE := 6
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
var cell_font_size := CELL_FONT_SIZE

func _ready() -> void:
	_build_top_bar()
	_build_headers()

	cell_edits.resize(ROWS)

	for row in range(ROWS):
		cell_edits[row] = []
		cell_edits[row].resize(COLS)

		for col in range(COLS):
			var edit := LineEdit.new()
			edit.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
			edit.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.45, 0.45, 1))
			_style_cell(edit, Color(1, 1, 1, 1), Color(0.7, 0.85, 1, 1))
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
	top_bar_label.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
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
	label.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	label.add_theme_stylebox_override("normal", _make_header_stylebox())
	return label

func _make_header_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEADER_COLOR
	style.set_border_width_all(1)
	style.border_color = HEADER_BORDER_COLOR
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _layout_content() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var cell_size := Vector2(
		floorf((size.x - ROW_HEADER_WIDTH) / COLS),
		floorf((size.y - 2.0 * HEADER_HEIGHT) / ROWS),
	)
	var grid_size := Vector2(cell_size.x * COLS + ROW_HEADER_WIDTH, cell_size.y * ROWS + 2.0 * HEADER_HEIGHT)
	var grid_offset := (size - grid_size) / 2.0
	var top_bar_height := HEADER_HEIGHT
	var col_header_height := HEADER_HEIGHT
	var col_header_y := grid_offset.y + top_bar_height
	var cells_y := col_header_y + col_header_height
	var cells_x := grid_offset.x + ROW_HEADER_WIDTH

	# A LineEdit refuses to be sized below its font height plus stylebox margins, so
	# without this the cells would be silently clamped taller than their row and the
	# text would overlap the border of the row below.
	var fitted_font_size := _fit_font_size(cell_size.y + 1.0)
	if fitted_font_size != cell_font_size:
		_apply_font_size(fitted_font_size)
		# Minimum sizes only refresh after the theme change is processed, so lay out
		# once more next frame with the cells finally able to fit their row.
		call_deferred(&"_layout_content")

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

# A LineEdit's minimum height is its font height plus the tallest of its normal,
# focus and read_only styleboxes, so all three have to be overridden - leaving the
# themed read_only box in place would keep padding the cell taller than its row.
func _style_cell(edit: LineEdit, normal_color: Color, focus_color: Color) -> void:
	edit.add_theme_stylebox_override(&"normal", _make_stylebox(normal_color))
	edit.add_theme_stylebox_override(&"focus", _make_stylebox(focus_color))
	edit.add_theme_stylebox_override(&"read_only", _make_stylebox(normal_color))

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(1)
	style.border_color = Color(0.6, 0.6, 0.6, 1)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

# Largest size up to CELL_FONT_SIZE whose line height still fits inside a cell.
func _fit_font_size(available_height: float) -> int:
	var edit: LineEdit = cell_edits[0][0]
	var font := edit.get_theme_font(&"font")
	if font == null:
		return CELL_FONT_SIZE

	var font_size := CELL_FONT_SIZE
	while font_size > MIN_CELL_FONT_SIZE and font.get_height(font_size) > available_height:
		font_size -= 1
	return font_size

func _apply_font_size(font_size: int) -> void:
	cell_font_size = font_size

	for row in range(ROWS):
		for col in range(COLS):
			cell_edits[row][col].add_theme_font_size_override(&"font_size", font_size)

	for label in col_header_labels + row_header_labels:
		label.add_theme_font_size_override(&"font_size", font_size)

	corner_box.add_theme_font_size_override(&"font_size", font_size)
	top_bar_label.add_theme_font_size_override(&"font_size", font_size)

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
	_style_cell(edit, normal_color, focus_color)

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
