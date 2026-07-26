class_name TutorialController
extends Node

## The player's first day, written out on its own post-it and worked through one
## beat at a time. The order teaches the game's argument rather than its
## controls: slacking off is what moves the clock (beat 1), the boss is what
## makes that dangerous (beat 2), the better a distraction pays the more it
## exposes you (beats 3-5), and the coffee multiplies whatever is already running
## (beat 6). The last beat hands the day over to the regular task rotation and
## asks the player to waste it.
##
## Every beat is a Task, so the whole thing runs on the same
## changed / check_completed contract as the boss's work - see
## [PunishmentController].

## Fires when the last beat starts: the regular workday can take over from here.
signal finished

## The boss's first appearance is staged: the spinner starting is what brings it
## up, on a fixed delay rather than the random one. Turning up in answer to
## something the player just did reads as a consequence rather than as the boss
## popping in and out at random, and it puts a deadline the player can feel on
## the beat that follows - this plus the watch itself is the time they have to
## put the spinner away.
const FIRST_RISE_SECONDS := 3.0

## How long that first look lasts when the player beats the boss to it. Just long
## enough to register: the desk is clean, so there is nothing to find.
const FIRST_LOOK_SECONDS := 2.0

## Once the boss has been introduced it backs off for the remaining lessons: at
## its normal pace it is up again every few seconds, which leaves no room to sit
## in a distraction long enough to see what it does. Restored to the scene's own
## pacing when the tutorial hands the day over.
const TEACHING_MOVE_INTERVAL := Vector2(12.0, 18.0)

## Handed over by office.gd, which owns the scene.
var post_it_stack: PostItStack
var spreadsheet: Spreadsheet
var computer: Computer
var boss: Boss
var drawer: OfficeDrawer
var dating_app: DatingApp

var beats: Array[Task] = []
## What the spreadsheet's top bar says during each beat, by beat index.
var hints: Array[String] = []
## How many beats share a post-it, in order. Only three fit on a note, and the
## last beat gets one to itself.
var page_sizes := PackedInt32Array()
var current_index := 0
var running := false
var default_watch_delay := 0.0
var default_move_interval := Vector2.ZERO

func setup(p_post_it_stack: PostItStack, p_spreadsheet: Spreadsheet, p_computer: Computer,
		p_boss: Boss, p_drawer: OfficeDrawer, p_dating_app: DatingApp) -> void:
	post_it_stack = p_post_it_stack
	spreadsheet = p_spreadsheet
	computer = p_computer
	boss = p_boss
	drawer = p_drawer
	dating_app = p_dating_app
	default_watch_delay = boss.activity_check_delay
	default_move_interval = Vector2(boss.min_move_interval, boss.max_move_interval)
	spreadsheet.cell_text_changed.connect(_on_cell_text_changed)

func start() -> void:
	if running:
		return
	running = true

	# The computer opens on the video tab, which would have the player breaking
	# the rules before they have been told there are any.
	computer.show_tab(0)

	_build_beats()

	var descriptions: Array[String] = []
	for beat in beats:
		descriptions.append(beat.description)
	post_it_stack.start_tutorial(descriptions, page_sizes)

	current_index = 0
	_enter_beat()

func is_running() -> bool:
	return running

func _build_beats() -> void:
	# 1. The thesis: goofing off is what makes the clock move.
	_add_beat(
		StartActivityTask.new(&"fidget_spinner", "Fidget", "Spin the fidget spinner"),
		"Left-click the fidget spinner to spin it, right-click to stop it",
	)
	# 2. The catch: the boss decides what that costs.
	_add_beat(
		LookBusyTask.new(),
		"Stop everything before the boss sees",
	)
	# 3. Where the good stuff is, and what it costs to reach.
	_add_beat(
		OpenDrawerTask.new(drawer),
		"Click the drawer to open it",
	)
	# 4. A distraction has an inside: it pays more the longer you commit.
	_add_beat(
		SwipeProfilesTask.new(dating_app),
		"Every swipe makes the day go faster",
		true,
	)
	# 5. The one that hides in plain sight, inside the work app itself.
	_add_beat(
		StartActivityTask.new(&"video_distraction", "Watch a video", "Open the second tab on the taskbar"),
		"There is a video tab next to the spreadsheet",
	)
	# 6. The one thing on the desk the boss cannot object to. It pays nothing on
	# its own, so it comes last of the lessons: by now there is a habit to
	# multiply, and the cup is the reward for having one.
	_add_beat(
		DrinkCoffeeTask.new(),
		"Coffee multiplies whatever you already have running",
	)
	# 7. Hand-over: the rest of the day, played for real. It gets a note of its
	# own, because it is the whole game rather than a step of the tutorial.
	_add_beat(
		SurviveDayTask.new(),
		"Only distractions move the clock",
		true,
	)

## `starts_page` puts the beat on a fresh post-it; otherwise it joins the last
## one, up to what fits on a note.
func _add_beat(task: Task, hint: String, starts_page := false) -> void:
	beats.append(task)
	hints.append(hint)

	var last := page_sizes.size() - 1
	if starts_page or page_sizes.is_empty() or page_sizes[last] >= PostItStack.TUTORIAL_MAX_PAGE_SIZE:
		page_sizes.append(1)
	else:
		page_sizes[last] += 1

## Walks forward over any beats that are already satisfied - a player who opened
## the drawer early does not have to close it and open it again.
func _enter_beat() -> void:
	while current_index < beats.size():
		var task := beats[current_index]
		spreadsheet.set_status_message(hints[current_index])
		_on_beat_started()

		if not task.check_completed():
			task.changed.connect(_on_beat_changed)
			return

		# Already satisfied, but it still counts as done - side effects and all.
		_on_beat_completed()
		post_it_stack.advance_tutorial(current_index)
		current_index += 1

	_finish()

## The side effects a beat needs before the player can work on it.
func _on_beat_started() -> void:
	var task := beats[current_index]
	var is_last := current_index == beats.size() - 1

	boss.activity_check_delay = default_watch_delay
	# The last beat hands off the pacing along with the day.
	_set_boss_move_interval(default_move_interval if is_last else TEACHING_MOVE_INTERVAL)

	# A beat that carries its own text writes it now, so it reads right even if
	# the thing it tracks moved on while an earlier beat was still running.
	if task.has_method("progress_description"):
		post_it_stack.set_tutorial_item_text(current_index, task.progress_description())

	# The last beat is the rest of the day: regular work starts flowing again.
	if is_last:
		finished.emit()

## Re-arms a rise that is already on its way, so a change of pace takes effect
## now instead of one appearance later. A rise scripted by rise_in() keeps its
## own delay - the boss protects that itself.
func _set_boss_move_interval(interval: Vector2) -> void:
	if is_equal_approx(boss.min_move_interval, interval.x) \
			and is_equal_approx(boss.max_move_interval, interval.y):
		return

	boss.min_move_interval = interval.x
	boss.max_move_interval = interval.y
	if boss.is_activated and boss.state == Boss.State.RISING and not boss.move_timer.is_stopped():
		boss.schedule_next_move()

## The top bar is the spreadsheet's own readout of the cell being edited, so the
## hint gives it back as soon as the player starts typing. Only ever clears the
## tutorial's own text - a punishment task's instructions stay put.
func _on_cell_text_changed(_row: int, _col: int, _text: String) -> void:
	if not running or current_index >= hints.size():
		return
	if spreadsheet.status_message == hints[current_index]:
		spreadsheet.set_status_message("")

func _on_beat_changed() -> void:
	var task := beats[current_index]

	if task.has_method("progress_description"):
		post_it_stack.set_tutorial_item_text(current_index, task.progress_description())

	if not task.check_completed():
		return

	task.changed.disconnect(_on_beat_changed)
	_on_beat_completed()
	post_it_stack.advance_tutorial(current_index)
	current_index += 1
	_enter_beat()

## The side effects of finishing a beat.
func _on_beat_completed() -> void:
	var task := beats[current_index]
	EventBus.tutorial_beat_completed.emit()

	if current_index == 0:
		# The clock has been held at the opening time until now: the day starts
		# with the player's first distraction, which is also the first thing that
		# moves it.
		EventBus.day_started.emit()
		# Starting the spinner puts the boss on a clock of its own, so the next
		# beat comes with a deadline. From here on the boss is watching for real:
		# a player who sits on the spinner through the rise is punished.
		boss.rise_in(FIRST_RISE_SECONDS)

	# The quick player clears the desk before that deadline, and would otherwise
	# never see what they avoided - so the boss comes up at once for a short look
	# and finds nothing. Once it is up (or on its way) this does nothing: the look
	# it is already taking is answer enough.
	if task is LookBusyTask:
		boss.appear_now(FIRST_LOOK_SECONDS)

## The last beat ends the day, which ends the game - so there is nothing to hand
## over to and nothing to tidy up. The final note stays where it is, checked off.
func _finish() -> void:
	running = false
	beats.clear()
