class_name FillColumnTask
extends SpreadsheetTask

const COLUMN_NUMBERS: Array[String] = [
	"first",
	"second",
	"third",
	"fourth",
	"fifth",
	"sixth",
	"seventh",
	"eight"
]

var col_number: int

func _init(spreadsheet: Spreadsheet, _col_number: int = -1) -> void:
	if _col_number > COLUMN_NUMBERS.size():
		push_error("col_number must be < %i" % [COLUMN_NUMBERS.size()])

	if _col_number < 0:
		col_number = randi() % COLUMN_NUMBERS.size()
	else:
		col_number = _col_number

	super._init(
		"Fill column %s" % [col_number],
		"Fill column %s with numbers" % [col_number],
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()
	spreadsheet.clear_cells()
	for row in range(spreadsheet.ROWS):
		spreadsheet.set_cell_placeholder(row, col_number, "0")
		spreadsheet.set_cell_highlighted(row, col_number, true)

func check_completed() -> bool:
	var spreadsheet := get_spreadsheet()
	for row in range(spreadsheet.ROWS):
		if not spreadsheet.get_cell_text(row, col_number).is_valid_float():
			return false
	return true
