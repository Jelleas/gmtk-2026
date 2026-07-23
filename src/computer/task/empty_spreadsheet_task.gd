class_name EmptySpreadsheetTask
extends SpreadsheetTask

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Empty",
		"Empty the spreadsheet",
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	spreadsheet.clear_cells()
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			spreadsheet.set_cell_text(row, col, str(randi_range(1, 99)))

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if not spreadsheet.get_cell_text(row, col).is_empty():
				return false
	return true
