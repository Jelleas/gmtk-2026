class_name FillRowTask
extends SpreadsheetTask

var row_number: int

func _init(spreadsheet: Spreadsheet, _row_number: int=-1) -> void:
	if _row_number >= spreadsheet.ROWS:
		push_error("row_number must be < %i" % [spreadsheet.ROWS])

	if _row_number < 0:
		row_number = randi() % spreadsheet.ROWS
	else:
		row_number = _row_number

	super._init(
		"Fill row %s" % [row_number + 1],
		"Fill row %s with numbers" % [row_number + 1],
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	spreadsheet.clear_cells()
	for col in range(spreadsheet.COLS):
		spreadsheet.set_cell_placeholder(row_number, col, "0")
		spreadsheet.set_cell_highlighted(row_number, col, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for col in range(spreadsheet.COLS):
		if not spreadsheet.get_cell_text(row_number, col).is_valid_float():
			return false
	return true
