class_name EmptySpreadsheetTask
extends Task

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Empty the spreadsheet",
		"Delete the contents of every cell in the spreadsheet.",
		spreadsheet,
	)
	spreadsheet.cell_text_changed.connect(check_completed)

func check_completed() -> bool:
	var spreadsheet := target as Spreadsheet
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if not spreadsheet.get_cell_text(row, col).is_empty():
				return false
	return true
