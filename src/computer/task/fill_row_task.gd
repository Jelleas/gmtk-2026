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
	
	spreadsheet.clear_focus()
	
	for col in range(spreadsheet.COLS):
		spreadsheet.clear_cell(row_number, col)
		spreadsheet.set_cell_placeholder(row_number, col, "0")
		spreadsheet.set_cell_highlighted(row_number, col, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for col in range(spreadsheet.COLS):
		if not spreadsheet.get_cell_text(row_number, col).is_valid_float():
			return false

	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(_row: int, _col: int, _text: String) -> void:
	if _row != row_number:
		return
	
	get_spreadsheet().set_cell_highlighted(
		_row, 
		_col, 
		not _text.is_valid_float()
	)
	
	super._on_cell_text_changed(_row, _col, _text)
