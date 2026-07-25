class_name HighNumberTask
extends SpreadsheetTask

const DEFAULT_CELL_COUNT := 6
const MIN_DIGITS := 4

var cell_count: int
var target_cells: Array[Vector2i] = []

func _init(spreadsheet: Spreadsheet, _cell_count: int = DEFAULT_CELL_COUNT) -> void:
	cell_count = _cell_count
	super._init(
		"Enter high numbers",
		"Enter a number with %s digits" % [MIN_DIGITS],
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()

	spreadsheet.clear_focus()
	target_cells.clear()

	while target_cells.size() < cell_count:
		var cell := Vector2i(randi_range(0, spreadsheet.ROWS - 1), randi_range(0, spreadsheet.COLS - 1))
		if target_cells.has(cell):
			continue

		target_cells.push_back(cell)
		spreadsheet.clear_cell(cell.x, cell.y)
		spreadsheet.set_cell_placeholder(cell.x, cell.y, "0".repeat(MIN_DIGITS))
		spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

# Any number will do as long as it is long enough - a minus sign would make it
# neither long nor high, so those are rejected.
func _is_high_number(text: String) -> bool:
	return text.is_valid_int() and not text.begins_with("-") and text.length() >= MIN_DIGITS

func check_completed() -> bool:
	if target_cells.is_empty():
		return false

	var spreadsheet := get_spreadsheet()
	for cell in target_cells:
		if not _is_high_number(spreadsheet.get_cell_text(cell.x, cell.y)):
			return false

	spreadsheet.cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	if not target_cells.has(Vector2i(row, col)):
		return

	get_spreadsheet().set_cell_highlighted(row, col, not _is_high_number(text))

	super._on_cell_text_changed(row, col, text)
