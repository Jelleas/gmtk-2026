class_name TaskStore

# How often a task type should come up relative to the others. The row and
# column variants are near duplicates of each other, so each is worth half a
# turn, while the two that actually ask something of the player are worth two.
const DEFAULT_WEIGHT := 1.0
const SIMILAR_WEIGHT := 0.5
const INTERESTING_WEIGHT := 2.0

var BASE_WEIGHTS: Dictionary[Script, float] = {
	FillRowTask: SIMILAR_WEIGHT,
	FillColumnTask: SIMILAR_WEIGHT,
	CopyRowTask: SIMILAR_WEIGHT,
	CopyColumnTask: SIMILAR_WEIGHT,
	EmptySpreadsheetTask: DEFAULT_WEIGHT,
	HighNumberTask: DEFAULT_WEIGHT,
	WhackAMoleTask: INTERESTING_WEIGHT,
	TrailTask: INTERESTING_WEIGHT,
}

var TASK_TYPES: Array[Script] = BASE_WEIGHTS.keys()

# On top of that, each type carries a multiplier. Being picked cuts it, every
# other type gains a little, so a type that keeps missing out becomes ever more
# likely and the same task does not come up twice in a row for long.
const START_MULTIPLIER := 1.0
const MIN_MULTIPLIER := 0.25
const MAX_MULTIPLIER := 1.5
const PICKED_MULTIPLIER := 0.4
const UNPICKED_INCREASE := 0.25

var spreadsheet: Spreadsheet
var active_tasks: Array[Task] = []
var weight_multipliers: Dictionary[Script, float] = {}

func _init(p_spreadsheet: Spreadsheet) -> void:
	spreadsheet = p_spreadsheet

	for task_type in TASK_TYPES:
		weight_multipliers[task_type] = START_MULTIPLIER

	EventBus.task_completed.connect(on_task_completed)

func assign_new_task() -> Task:
	var available_types := TASK_TYPES.filter(func(task_type: Script) -> bool:
		if _has_active_task_of_type(task_type):
			return false
		if _is_spreadsheet_task_type(task_type) and _has_active_spreadsheet_task():
			return false
		return true
	)
	if available_types.is_empty():
		return null

	var task_type := _pick_weighted_type(available_types)
	_update_weights(task_type)

	var task: Task = task_type.new(spreadsheet)
	task.changed.connect(_on_task_changed.bind(task))
	task.start_task()
	active_tasks.append(task)

	EventBus.task_added.emit(task)
	return task

func get_weight(task_type: Script) -> float:
	return BASE_WEIGHTS[task_type] * weight_multipliers[task_type]

func _pick_weighted_type(types: Array) -> Script:
	var total := 0.0
	for task_type in types:
		total += get_weight(task_type)

	var roll := randf() * total
	for task_type in types:
		roll -= get_weight(task_type)
		if roll <= 0.0:
			return task_type

	return types.back()

func _update_weights(picked_type: Script) -> void:
	for task_type in TASK_TYPES:
		if task_type == picked_type:
			weight_multipliers[task_type] = maxf(MIN_MULTIPLIER, weight_multipliers[task_type] * PICKED_MULTIPLIER)
		else:
			weight_multipliers[task_type] = minf(MAX_MULTIPLIER, weight_multipliers[task_type] + UNPICKED_INCREASE)

func _on_task_changed(task: Task) -> void:
	if task.check_completed():
		EventBus.task_completed.emit(task)

func _has_active_task_of_type(task_type: Script) -> bool:
	for task in active_tasks:
		if task.get_script() == task_type:
			return true
	return false

func _has_active_spreadsheet_task() -> bool:
	for task in active_tasks:
		if task is SpreadsheetTask:
			return true
	return false

func _is_spreadsheet_task_type(task_type: Script) -> bool:
	var current: Script = task_type
	while current:
		if current == SpreadsheetTask:
			return true
		current = current.get_base_script()
	return false

func on_task_completed(task: Task) -> void:
	active_tasks.erase(task)
