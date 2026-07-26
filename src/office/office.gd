extends Node2D

const TARGET_TASK_COUNT := 2

@export var task_refill_delay := 2.0
## The first day walks the player through the game. Turn this off to drop
## straight into a regular workday.
@export var run_tutorial := true

var task_store: TaskStore
var refill_timer: Timer
var computer: Computer
var spreadsheet: Spreadsheet
var boss: Boss
var is_punished := false
var has_started := false
var has_ended := false
## While the tutorial is walking the player around, the regular task rotation
## stays out of the way.
var is_scripted := false

func _ready():
	# The tracker outlives the scene, so a fresh run clears it here rather than
	# on day_started: the tutorial's first spin comes before the day does.
	StatTracker.reset()

	computer = $Screen/Computer
	spreadsheet = computer.spreadsheet
	boss = $Boss
	task_store = TaskStore.new(spreadsheet)
	$Punishment.setup(task_store, spreadsheet, $PostItStack)
	EventBus.task_completed.connect(_on_task_completed)
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	EventBus.day_ended.connect(_on_day_ended)
	$FidgetSpinner.started.connect($OfficeView.play_fidget_spin)
	$FidgetSpinner.stopped.connect($OfficeView.stop_fidget_spin)
	# The spinner and the cup keep their rules to themselves and own no sprite, so
	# their refusals are handed to the props in the office view.
	$FidgetSpinner.denied.connect($OfficeView.deny_fidget)
	$CoffeeBuff.denied.connect($OfficeView.deny_cup)
	$CoffeeBuff.visual_state_changed.connect($OfficeView.set_coffee_state)
	$CoffeeBuff.refresh_visual_state()
	$FidgetSpinner.set_interaction_enabled(false)
	$CoffeeBuff.set_interaction_enabled(false)
	$OfficeView.drawer.can_open = false
	computer.login_authenticated.connect(start_day)

	refill_timer = Timer.new()
	refill_timer.one_shot = true
	refill_timer.timeout.connect(_refill_tasks)
	add_child(refill_timer)


func start_day() -> void:
	if has_started:
		return
	has_started = true
	$FidgetSpinner.set_interaction_enabled(true)
	$CoffeeBuff.set_interaction_enabled(true)
	$OfficeView.drawer.can_open = true

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

## Home time. The desk is put down before the shift report comes up on the
## monitor: work that arrived now would never be done, and a boss peek would
## start a punishment behind the report.
func _on_day_ended(_realtime: float) -> void:
	has_ended = true
	refill_timer.stop()
	boss.deactivate()
	$FidgetSpinner.stop(true)
	$FidgetSpinner.set_interaction_enabled(false)
	$CoffeeBuff.reset()
	$CoffeeBuff.set_interaction_enabled(false)
	# Closing the drawer takes the phone with it, through the signals the phone
	# is already listening to.
	$OfficeView.drawer.set_open(false)
	$OfficeView.drawer.can_open = false
	# Back to the spreadsheet, which stops the video runner.
	computer.show_tab(0)

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
	if is_punished or is_scripted or has_ended:
		return

	while task_store.active_tasks.size() < TARGET_TASK_COUNT:
		if task_store.assign_new_task() == null:
			break
