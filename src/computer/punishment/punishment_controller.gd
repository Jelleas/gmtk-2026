extends Node

@onready var spreadsheet: Spreadsheet = %Spreadsheet

var punishment_task: PunishmentTask

func _ready() -> void:
	EventBus.punish.connect(_on_punish)

func _on_punish(_weight: float) -> void:
	if punishment_task:
		return

	punishment_task = PunishmentTask.new(FillCellsTask.new(spreadsheet))
	punishment_task.changed.connect(_on_punishment_task_changed)
	punishment_task.start_task()
	spreadsheet.set_status_message("Enter the values in the highlighted cells")

func _on_punishment_task_changed() -> void:
	if not punishment_task:
		return

	if not punishment_task.wrapped_task.check_completed():
		spreadsheet.set_status_message("Enter the values in the highlighted cells")
	elif punishment_task.has_active_activities():
		spreadsheet.set_status_message("Stop all distractions before continuing")
	else:
		_complete_task()

func _complete_task() -> void:
	spreadsheet.set_status_message("Task complete")
	punishment_task = null
	EventBus.punishment_ended.emit()
