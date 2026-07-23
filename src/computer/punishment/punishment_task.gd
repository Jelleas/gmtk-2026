extends Node

const TASK_CELL_COUNT := 3
const SPREADSHEET_COLS := 8
const SPREADSHEET_ROWS := 12

@onready var spreadsheet: Variant = %Spreadsheet

var is_active := false
var required_cells: Dictionary[Vector2i, String] = {}
var activity_states: Dictionary[StringName, bool] = {}

func _ready() -> void:
	EventBus.punish.connect(_start_task)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)
	spreadsheet.cell_text_changed.connect(_on_cell_text_changed)

func _start_task(_weight: float) -> void:
	if is_active:
		return

	spreadsheet.clear_cells()
	is_active = true
	spreadsheet.set_status_message("Enter the values in the highlighted cells")

	while required_cells.size() < TASK_CELL_COUNT:
		var cell := Vector2i(randi_range(0, SPREADSHEET_ROWS - 1), randi_range(0, SPREADSHEET_COLS - 1))
		if required_cells.has(cell):
			continue

		var required_value := str(randi_range(10, 99))
		required_cells[cell] = required_value
		spreadsheet.set_cell_text(cell.x, cell.y, "")
		spreadsheet.set_cell_placeholder(cell.x, cell.y, required_value)
		spreadsheet.set_cell_highlighted(cell.x, cell.y, true)

func _on_cell_text_changed(_row: int, _col: int, _text: String) -> void:
	if not is_active:
		return

	_try_complete_task()

func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true
	if is_active:
		_try_complete_task()

func _on_activity_ended(source_id: StringName) -> void:
	activity_states[source_id] = false
	if is_active:
		_try_complete_task()

func _try_complete_task() -> void:
	if not _task_cells_are_correct():
		spreadsheet.set_status_message("Enter the values in the highlighted cells")
		return

	if _has_active_activities():
		spreadsheet.set_status_message("Stop all distractions before continuing")
		return

	_complete_task()

func _task_cells_are_correct() -> bool:
	if required_cells.is_empty():
		return false

	for cell in required_cells:
		var cell_position: Vector2i = cell
		if spreadsheet.get_cell_text(cell_position.x, cell_position.y) != required_cells[cell_position]:
			return false

	return true

func _has_active_activities() -> bool:
	for is_running in activity_states.values():
		if is_running:
			return true

	return false

func _complete_task() -> void:
	for cell in required_cells:
		var cell_position: Vector2i = cell
		spreadsheet.set_cell_placeholder(cell_position.x, cell_position.y, "")
		spreadsheet.set_cell_highlighted(cell_position.x, cell_position.y, false)

	required_cells.clear()
	is_active = false
	spreadsheet.set_status_message("Task complete")
	EventBus.punishment_ended.emit()
