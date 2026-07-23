class_name EmptySpreadsheetTask
extends SpreadsheetTask

const MIN_FILLED_CELLS := 5
const MAX_FILLED_CELLS := 15

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Empty",
		"Empty the spreadsheet",
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	spreadsheet.clear_cells()

	var filled_cells: Dictionary[Vector2i, bool] = {}
	var cell_count := randi_range(MIN_FILLED_CELLS, MAX_FILLED_CELLS)

	while filled_cells.size() < cell_count:
		var cell := Vector2i(randi_range(0, spreadsheet.ROWS - 1), randi_range(0, spreadsheet.COLS - 1))
		if filled_cells.has(cell):
			continue

		filled_cells[cell] = true
		spreadsheet.set_cell_text(cell.x, cell.y, str(randi_range(1, 99)))

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if not spreadsheet.get_cell_text(row, col).is_empty():
				return false
	return true
