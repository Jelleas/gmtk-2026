class_name CopyRowTask
extends SpreadsheetTask

const MIN_VALUE := 0
const MAX_VALUE := 9

var source_row: int
var target_row: int

func _init(spreadsheet: Spreadsheet) -> void:
	source_row = _pick_source_row(spreadsheet)
	target_row = (source_row + 1 + randi() % (spreadsheet.ROWS - 1)) % spreadsheet.ROWS

	super._init(
		"Copy row %s" % [source_row + 1],
		"Copy row %s into row %s" % [source_row + 1, target_row + 1],
		spreadsheet,
	)

# Prefer a row that already holds something, so the player copies existing data
# instead of numbers the spreadsheet just made up for them.
func _pick_source_row(spreadsheet: Spreadsheet) -> int:
	var filled_rows: Array[int] = []
	for coords in spreadsheet.get_filled_coords():
		if not filled_rows.has(coords.x):
			filled_rows.push_back(coords.x)

	if filled_rows.is_empty():
		return randi() % spreadsheet.ROWS
	return filled_rows[randi() % filled_rows.size()]

func start_task() -> void:
	var spreadsheet := get_spreadsheet()

	spreadsheet.clear_focus()

	for col in range(spreadsheet.COLS):
		if spreadsheet.get_cell_text(source_row, col).is_empty():
			spreadsheet.set_cell_text(source_row, col, str(randi_range(MIN_VALUE, MAX_VALUE)))

		# The source is locked so the values cannot be edited away while copying.
		spreadsheet.set_cell_editable(source_row, col, false)

		spreadsheet.clear_cell(target_row, col)
		spreadsheet.set_cell_placeholder(target_row, col, spreadsheet.get_cell_text(source_row, col))
		spreadsheet.set_cell_highlighted(target_row, col, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for col in range(spreadsheet.COLS):
		if spreadsheet.get_cell_text(target_row, col) != spreadsheet.get_cell_text(source_row, col):
			return false

	for col in range(spreadsheet.COLS):
		spreadsheet.set_cell_editable(source_row, col, true)

	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	if row != target_row:
		return

	get_spreadsheet().set_cell_highlighted(
		row,
		col,
		text != get_spreadsheet().get_cell_text(source_row, col)
	)

	super._on_cell_text_changed(row, col, text)
