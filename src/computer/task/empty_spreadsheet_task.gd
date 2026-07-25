class_name EmptySpreadsheetTask
extends SpreadsheetTask

const MIN_FILLED_CELLS := 5
const MAX_FILLED_CELLS := 10

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Empty",
		"Empty the spreadsheet",
		spreadsheet,
	)
	
	#spreadsheet.cell_text_changed.connect(_on_cell_text_changed)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()

	spreadsheet.clear_focus()

	var coords := spreadsheet.get_filled_coords()
	coords.shuffle()

	while coords.size() < MIN_FILLED_CELLS:
		var cell := Vector2i(randi_range(0, spreadsheet.ROWS - 1), randi_range(0, spreadsheet.COLS - 1))
		
		if not coords.has(cell):
			coords.push_back(cell)
			spreadsheet.set_cell_text(cell.x, cell.y, str(randi_range(1, 99)))
	
	while coords.size() >= MAX_FILLED_CELLS:
		var cell = coords.pop_front()		
		spreadsheet.clear_cell(cell.x, cell.y)
	
	for cell in coords:
		spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if not spreadsheet.get_cell_text(row, col).is_empty():
				return false
				
	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true
	
func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	if text == "":
		get_spreadsheet().set_cell_highlighted(row, col, false)
	else:
		get_spreadsheet().set_cell_highlighted(row, col, true)
	super._on_cell_text_changed(row, col, text)
