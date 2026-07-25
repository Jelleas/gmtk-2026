class_name TutorialController
extends Node

## The player's first day, written out on its own post-it and worked through one
## beat at a time. The order teaches the game's argument rather than its
## controls: slacking off is what moves the clock (beat 1), the boss is what
## makes that dangerous (beat 2), and the better a distraction pays the more it
## exposes you (beats 3-5). The last beat hands the day over to the regular task
## rotation and asks the player to waste it.
##
## Every beat is a Task, so the whole thing runs on the same
## changed / check_completed contract as the boss's work - see
## [PunishmentController].

## Fires when the last beat starts: the regular workday can take over from here.
signal finished

## The boss watches for longer on its first rise, so the player gets time to read
## the filling watch instead of being punished by a mechanic they have not met.
const FIRST_WATCH_DELAY := 8.0

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

func setup(p_post_it_stack: PostItStack, p_spreadsheet: Spreadsheet, p_computer: Computer,
		p_boss: Boss, p_drawer: OfficeDrawer, p_dating_app: DatingApp) -> void:
	post_it_stack = p_post_it_stack
	spreadsheet = p_spreadsheet
	computer = p_computer
	boss = p_boss
	drawer = p_drawer
	dating_app = p_dating_app
	default_watch_delay = boss.activity_check_delay

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
		"Stop everything before the boss's watch runs out",
	)
	# 3. Where the good stuff is, and what it costs to reach.
	_add_beat(
		OpenDrawerTask.new(drawer),
		"Drag the drawer open",
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
	# 6. Hand-over: the rest of the day, played for real. It gets a note of its
	# own, because it is the whole game rather than a step of the tutorial.
	_add_beat(
		SurviveDayTask.new(),
		"The last hour always drags",
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

		post_it_stack.advance_tutorial(current_index)
		current_index += 1

	_finish()

## The side effects a beat needs before the player can work on it.
func _on_beat_started() -> void:
	var task := beats[current_index]

	if task is LookBusyTask:
		# The boss has been kept away until now, so beat 1 could be enjoyed.
		boss.activity_check_delay = FIRST_WATCH_DELAY
		boss.activate()
	else:
		boss.activity_check_delay = default_watch_delay

	# The last beat is the rest of the day: regular work starts flowing again.
	if current_index == beats.size() - 1:
		finished.emit()

func _on_beat_changed() -> void:
	var task := beats[current_index]

	if task.has_method("progress_description"):
		post_it_stack.set_tutorial_item_text(current_index, task.progress_description())

	if not task.check_completed():
		return

	task.changed.disconnect(_on_beat_changed)
	post_it_stack.advance_tutorial(current_index)
	current_index += 1
	_enter_beat()

## The last beat ends the day, which ends the game - so there is nothing to hand
## over to and nothing to tidy up. The final note stays where it is, checked off.
func _finish() -> void:
	running = false
	beats.clear()
