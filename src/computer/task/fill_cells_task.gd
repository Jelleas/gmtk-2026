class_name FillCellsTask
extends SpreadsheetTask

const DEFAULT_CELL_COUNT := 3
const MIN_VALUE := 10
const MAX_VALUE := 99

var cell_count: int
var required_cells: Dictionary[Vector2i, String] = {}

func _init(spreadsheet: Spreadsheet, _cell_count: int = DEFAULT_CELL_COUNT) -> void:
	cell_count = _cell_count
	super._init(
		"Fill the highlighted cells",
		"Enter the values in the highlighted cells",
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	spreadsheet.clear_cells()
	required_cells.clear()

	while required_cells.size() < cell_count:
		var cell := Vector2i(randi_range(0, spreadsheet.ROWS - 1), randi_range(0, spreadsheet.COLS - 1))
		if required_cells.has(cell):
			continue

		var required_value := str(randi_range(MIN_VALUE, MAX_VALUE))
		required_cells[cell] = required_value
		spreadsheet.set_cell_placeholder(cell.x, cell.y, required_value)
		spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

func check_completed() -> bool:
	if required_cells.is_empty():
		return false

	var spreadsheet := get_spreadsheet()
	for cell in required_cells:
		var cell_position: Vector2i = cell
		if spreadsheet.get_cell_text(cell_position.x, cell_position.y) != required_cells[cell_position]:
			return false

	return true
