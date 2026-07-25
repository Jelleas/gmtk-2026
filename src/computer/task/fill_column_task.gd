class_name FillColumnTask
extends SpreadsheetTask

const COLUMN_LETTERS: String = "ABCDEFGH"

var col_number: int

func _init(spreadsheet: Spreadsheet, _col_number: int = -1) -> void:
	if _col_number > COLUMN_LETTERS.length():
		push_error("col_number must be < %i" % [COLUMN_LETTERS.length()])

	if _col_number < 0:
		col_number = randi() % COLUMN_LETTERS.length()
	else:
		col_number = _col_number

	super._init(
		"Fill column %s" % [COLUMN_LETTERS[col_number]],
		"Fill column %s with numbers" % [COLUMN_LETTERS[col_number]],
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	
	spreadsheet.clear_focus()
	
	for row in range(spreadsheet.ROWS):
		spreadsheet.clear_cell(row, col_number)
		spreadsheet.set_cell_placeholder(row, col_number, "0")
		spreadsheet.set_cell_highlighted(row, col_number, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		if not spreadsheet.get_cell_text(row, col_number).is_valid_float():
			return false

	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(_row: int, _col: int, _text: String) -> void:
	if _col != col_number:
		return
	
	get_spreadsheet().set_cell_highlighted(
		_row, 
		_col, 
		not _text.is_valid_float()
	)
	
	super._on_cell_text_changed(_row, _col, _text)
