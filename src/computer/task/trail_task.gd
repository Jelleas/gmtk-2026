class_name TrailTask
extends SpreadsheetTask

const REQUIRED_CELLS := 10
const NEIGHBOUR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
]

var entered := 0
var current_cell: Vector2i
var trail: Array[Vector2i] = []

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Follow the trail",
		"Follow the trail, keep entering numbers" % [REQUIRED_CELLS],
		spreadsheet,
	)

func start_task() -> void:
	var spreadsheet := get_spreadsheet()

	spreadsheet.clear_focus()
	entered = 0
	trail.clear()

	var empty_cells := _get_empty_cells()
	current_cell = empty_cells[randi() % empty_cells.size()] if not empty_cells.is_empty() else Vector2i.ZERO
	_move_to(current_cell)

func _get_empty_cells() -> Array[Vector2i]:
	var spreadsheet := get_spreadsheet()
	var cells: Array[Vector2i] = []
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if spreadsheet.get_cell_text(row, col).is_empty() and not trail.has(Vector2i(row, col)):
				cells.push_back(Vector2i(row, col))
	return cells

func _move_to(cell: Vector2i) -> void:
	var spreadsheet := get_spreadsheet()
	current_cell = cell
	spreadsheet.set_cell_placeholder(cell.x, cell.y, "0")
	spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

# An empty cell next to the one just filled in. Once the trail has boxed itself
# in, any neighbour will do and the player writes over whatever is in it.
func _pick_next_cell() -> Vector2i:
	var spreadsheet := get_spreadsheet()
	var neighbours: Array[Vector2i] = []
	var free_neighbours: Array[Vector2i] = []

	for offset in NEIGHBOUR_OFFSETS:
		var neighbour := current_cell + offset
		if neighbour.x < 0 or neighbour.x >= spreadsheet.ROWS:
			continue
		if neighbour.y < 0 or neighbour.y >= spreadsheet.COLS:
			continue

		neighbours.push_back(neighbour)
		if not trail.has(neighbour) and spreadsheet.get_cell_text(neighbour.x, neighbour.y).is_empty():
			free_neighbours.push_back(neighbour)

	var candidates := free_neighbours if not free_neighbours.is_empty() else neighbours
	return candidates[randi() % candidates.size()]

func check_completed() -> bool:
	if entered < REQUIRED_CELLS:
		return false

	get_spreadsheet().cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	if Vector2i(row, col) != current_cell or not text.is_valid_float():
		return

	var spreadsheet := get_spreadsheet()
	spreadsheet.set_cell_placeholder(row, col, "")
	spreadsheet.set_cell_highlighted(row, col, false)
	trail.push_back(current_cell)
	entered += 1

	if entered < REQUIRED_CELLS:
		_move_to(_pick_next_cell())

	super._on_cell_text_changed(row, col, text)
