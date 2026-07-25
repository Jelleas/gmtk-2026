class_name WhackAMoleTask
extends SpreadsheetTask

const REQUIRED_HITS := 5
const MOLE_COUNT := 5
const WAVE_SECONDS := 3.0
const MIN_VALUE := 0
const MAX_VALUE := 9

var hits := 0
var active_moles: Array[Vector2i] = []

func _init(spreadsheet: Spreadsheet) -> void:
	super._init(
		"Clear stray digits",
		"Clear highlighted cells before they move",
		spreadsheet,
	)

func start_task() -> void:
	get_spreadsheet().clear_focus()
	hits = 0
	_start_wave()

# Each wave puts a digit in a few empty cells and gives the player until the
# timeout to clear them. Every cell cleared in time counts as a hit, and shrinks
# every wave after it, so the task winds down as the player keeps up.
func _start_wave() -> void:
	var spreadsheet := get_spreadsheet()
	active_moles.clear()

	var empty_cells := _get_empty_cells()
	empty_cells.shuffle()

	for cell in empty_cells.slice(0, MOLE_COUNT - hits):
		active_moles.push_back(cell)
		spreadsheet.set_cell_text(cell.x, cell.y, str(randi_range(MIN_VALUE, MAX_VALUE)))
		spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

	spreadsheet.get_tree().create_timer(WAVE_SECONDS).timeout.connect(_on_wave_timeout)

func _get_empty_cells() -> Array[Vector2i]:
	var spreadsheet := get_spreadsheet()
	var cells: Array[Vector2i] = []
	for row in range(spreadsheet.ROWS):
		for col in range(spreadsheet.COLS):
			if spreadsheet.get_cell_text(row, col).is_empty():
				cells.push_back(Vector2i(row, col))
	return cells

func _clear_moles() -> void:
	var spreadsheet := get_spreadsheet()
	for cell in active_moles:
		spreadsheet.clear_cell(cell.x, cell.y)
	active_moles.clear()

func _on_wave_timeout() -> void:
	# The last wave's timer still fires once after the task is finished.
	if hits >= REQUIRED_HITS:
		return

	_clear_moles()
	_start_wave()

func check_completed() -> bool:
	if hits < REQUIRED_HITS:
		return false

	# Completion is tracked by the hit counter, so this can be asked more than
	# once (a PunishmentTask keeps checking while an activity is running).
	if get_spreadsheet().cell_text_changed.is_connected(_on_cell_text_changed):
		get_spreadsheet().cell_text_changed.disconnect(_on_cell_text_changed)
	return true

func _on_cell_text_changed(row: int, col: int, text: String) -> void:
	var cell := Vector2i(row, col)
	if not active_moles.has(cell) or not text.is_empty():
		return

	active_moles.erase(cell)
	hits += 1
	get_spreadsheet().set_cell_highlighted(row, col, false)

	if hits >= REQUIRED_HITS:
		_clear_moles()

	super._on_cell_text_changed(row, col, text)
