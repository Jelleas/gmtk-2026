class_name FillRowTask
extends SpreadsheetTask

const ROW_NUMBERS: Array[String] = [
	"first",
	"second",
	"third",
	"fourth",
	"fifth",
	"sixth",
	"seventh",
	"eight"
]

var row_number: int

func _init(spreadsheet: Spreadsheet, _row_number: int=-1) -> void:
	if _row_number > ROW_NUMBERS.size():
		push_error("row_number must be < %i" % [ROW_NUMBERS.size()])

	if _row_number < 0:
		row_number = randi() % ROW_NUMBERS.size()
	else:
		row_number = _row_number

	super._init(
		"Fill row %s" % [row_number],
		"Fill row %s with numbers" % [row_number],
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
