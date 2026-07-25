extends Node2D

const TARGET_TASK_COUNT := 2

@export var task_refill_delay := 2.0
## The first day walks the player through the game. Turn this off to drop
## straight into a regular workday.
@export var run_tutorial := true

var task_store: TaskStore
var refill_timer: Timer
var is_punished := false
## While the tutorial is walking the player around, the regular task rotation
## stays out of the way.
var is_scripted := false

func _ready():
	# The tracker outlives the scene, so a fresh run clears it here rather than
	# on day_started: the tutorial's first spin comes before the day does.
	StatTracker.reset()

	var computer: Computer = $Screen/Computer
	var spreadsheet: Spreadsheet = computer.spreadsheet
	var boss: Boss = $Boss
	task_store = TaskStore.new(spreadsheet)
	$Punishment.setup(task_store, spreadsheet, $PostItStack)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	$FidgetSpinner.started.connect($OfficeView.play_fidget_spin)
	$FidgetSpinner.stopped.connect($OfficeView.stop_fidget_spin)

	refill_timer = Timer.new()
	refill_timer.one_shot = true
	refill_timer.timeout.connect(_refill_tasks)
	add_child(refill_timer)

	if run_tutorial:
		is_scripted = true
		$Tutorial.setup(
			$PostItStack,
			spreadsheet,
			computer,
			boss,
			$OfficeView.drawer,
			$Phone.dating_app,
		)
		$Tutorial.finished.connect(_on_tutorial_finished)
		$Tutorial.start()
	else:
		# The tutorial normally brings the boss in on its second beat and starts
		# the clock once the player has taken their first distraction.
		boss.activate()
		EventBus.day_started.emit()
		_refill_tasks()

## The tutorial's last beat is the rest of the day, so real work starts flowing
## while the player is still holding the note.
func _on_tutorial_finished() -> void:
	is_scripted = false

func _on_task_completed(_task: Task) -> void:
	refill_timer.start(task_refill_delay)

func _on_punishment_started(_activity_count: int) -> void:
	is_punished = true

func _on_punishment_ended() -> void:
	is_punished = false
	# The punishment took over the spreadsheet, so hand the regular work back.
	for task in task_store.active_tasks:
		if task is SpreadsheetTask:
			task.get_spreadsheet().set_status_message("")
			task.start_task()
			break
	refill_timer.start(task_refill_delay)

func _refill_tasks() -> void:
	# Handing out regular work mid-punishment would start another spreadsheet
	# task and wipe the sheet the punishment is running on. The tutorial holds it
	# off for the same reason.
	if is_punished or is_scripted:
		return

	while task_store.active_tasks.size() < TARGET_TASK_COUNT:
		if task_store.assign_new_task() == null:
			break
