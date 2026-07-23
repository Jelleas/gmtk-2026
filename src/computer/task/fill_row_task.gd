class_name FillRowTask
extends Task

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

	spreadsheet.cell_text_changed.connect(check_completed)
	
	super._init(
		"Fill the first row",
		"Enter a number in every cell of the spreadsheet's %s row." % [ROW_NUMBERS[row_number]],
		spreadsheet,
	)

func check_completed() -> bool:
	var spreadsheet := target as Spreadsheet
	for col in range(spreadsheet.COLS):
		if not spreadsheet.get_cell_text(0, col).is_valid_float():
			return false
	return true
