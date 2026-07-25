class_name CopyColumnTask
extends SpreadsheetTask

const COLUMN_LETTERS: String = "ABCDEFGH"
const MIN_VALUE := 0
const MAX_VALUE := 9

var source_col: int
var target_col: int

func _init(spreadsheet: Spreadsheet) -> void:
	source_col = _pick_source_col(spreadsheet)
	target_col = (source_col + 1 + randi() % (spreadsheet.COLS - 1)) % spreadsheet.COLS

	super._init(
		"Copy column %s" % [COLUMN_LETTERS[source_col]],
		"Copy column %s into column %s" % [COLUMN_LETTERS[source_col], COLUMN_LETTERS[target_col]],
		spreadsheet,
	)

# Prefer a column that already holds something, so the player copies existing
# data instead of numbers the spreadsheet just made up for them.
func _pick_source_col(spreadsheet: Spreadsheet) -> int:
	var filled_cols: Array[int] = []
	for coords in spreadsheet.get_filled_coords():
		if not filled_cols.has(coords.y):
			filled_cols.push_back(coords.y)

	if filled_cols.is_empty():
		return randi() % spreadsheet.COLS
	return filled_cols[randi() % filled_cols.size()]

func start_task() -> void:
	var spreadsheet := get_spreadsheet()

	spreadsheet.clear_focus()

	for row in range(spreadsheet.ROWS):
		if spreadsheet.get_cell_text(row, source_col).is_empty():
			spreadsheet.set_cell_text(row, source_col, str(randi_range(MIN_VALUE, MAX_VALUE)))

		# The source is locked so the values cannot be edited away while copying.
		spreadsheet.set_cell_editable(row, source_col, false)

		spreadsheet.clear_cell(row, target_col)
		spreadsheet.set_cell_placeholder(row, target_col, spreadsheet.get_cell_text(row, source_col))
		spreadsheet.set_cell_highlighted(row, target_col, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		if spreadsheet.get_cell_text(row, target_col) != spreadsheet.get_cell_text(row, source_col):
			return false

	for row in range(spreadsheet.ROWS):
		spreadsheet.set_cell_editable(row, source_col, true)

	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	if col != target_col:
		return

	get_spreadsheet().set_cell_highlighted(
		row,
		col,
		text != get_spreadsheet().get_cell_text(row, source_col)
	)

	super._on_cell_text_changed(row, col, text)
