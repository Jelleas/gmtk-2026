class_name PostItStack
extends Node2D

## A layered stack of PostIt notes. Drop-in replacement for a single PostIt:
## it owns the active-task logic (EventBus subscriptions) and exposes the same
## public API. New tasks land on the top note; once a note reaches
## SEAL_AT_CHECKED checked-off tasks it is sealed and a fresh note flies in
## from the top, keeping any still-active tasks visible on the new top note.
##
## The work the boss hands out gets its own notes on top of the pile: they are
## never the active note (regular tasks keep landing on the note underneath),
## they keep their own colour, and they leave as a whole instead of being sealed.
## There are two of them: the punishment note, and the prep note above it that
## lists what the player has to sort out before starting the punishment work.
##
## The tutorial rides on the same machinery, in the regular colour and a page of
## TUTORIAL_PAGE_SIZE beats at a time.

const PostItScene := preload("res://src/postit/postit.tscn")

## A note is sealed (and a new one flies in) once it has this many checked items.
const SEAL_AT_CHECKED := 3

## Per-depth pose tuning for the layered look.
const DEPTH_OFFSET := Vector2(42.0, 46.0)
## Notes deeper in the pile are tinted slightly darker so layers read clearly.
const DEPTH_DARKEN := 0.10
const MAX_VISIBLE_DEPTH := 4
## Each note gets its own fixed slight tilt (degrees) so the whole pile,
## including the top note, looks hand-stacked. Adjacent notes lean opposite ways.
const MIN_TILT := 3.0
const MAX_TILT := 7.0
## PostIt is 240x240; rotate notes around their center so corners fan out.
const NOTE_CENTER := Vector2(120.0, 120.0)

## Fly-in / restack animation tuning.
const FLY_IN_HEIGHT := 320.0
const FLY_IN_DURATION := 0.35
const POSE_DURATION := 0.18

## The boss's notes stand out from the regular yellow ones.
const PUNISHMENT_COLOR := Color("d14b3e")

## Only so many items fit on a note, so the tutorial is handed out a page at a
## time: a finished page leaves and the next one flies in behind it. How the
## beats are split over the pages is the tutorial's call, not the stack's.
const TUTORIAL_MAX_PAGE_SIZE := 3
## How long a finished page stays up, so the last check can be read.
const TUTORIAL_PAGE_TURN_DELAY := 0.6

@export var note_color: Color = Color("edcb44"):
	set(value):
		note_color = value
		var special := _special_notes()
		for note in notes:
			if is_instance_valid(note) and not special.has(note):
				note.note_color = value

@onready var notes_root: Node2D = $Notes

## Notes in creation order (notes[0] is oldest, notes.back() is the top note).
## While the boss has work out its notes are kept last, so they stay on top.
var notes: Array[PostIt] = []
## The top / newest note where new items are added.
var active_note: PostIt
## The notes that are driven from outside (the boss's work, the tutorial),
## bottom to top. They are kept at the tail of `notes`, so regular notes always
## slot in underneath them.
var special_notes: Array[PostIt] = []
## Each special note's own colour, before the depth tint is applied.
var special_colors := {}
## The punishment note, while the boss has one out.
var punishment_note: PostIt
## The prep note listing what to sort out before the punishment work starts.
var prep_note: PostIt
## The tutorial page currently up, on the player's first day. Null for the beat
## of a second between a finished page leaving and the next one arriving.
var tutorial_note: PostIt
## Every tutorial beat's text, whether or not its page is up.
var tutorial_texts: Array[String] = []
## How many beats each page holds, in order.
var tutorial_page_sizes := PackedInt32Array()
## Which page is up, which beat it starts at, and how many beats are done.
## Together they decide what a page looks like, so a page can be redrawn at any
## time - which is what makes turning one safe.
var tutorial_page_index := 0
var tutorial_page := 0
var tutorial_completed := 0
var tutorial_running := false

func _ready() -> void:
	EventBus.task_added.connect(on_task_added)
	EventBus.task_completed.connect(on_task_completed)
	_spawn_note(false)

# --- Public API (mirrors PostIt) -------------------------------------------

func add_item(text: String, checked: bool = false) -> TodoItem:
	return active_note.add_item(text, checked)

func set_item_text(index: int, text: String) -> void:
	var loc := _resolve(index)
	if loc.is_empty():
		return
	(loc[0] as PostIt).set_item_text(loc[1], text)

func set_item_checked(index: int, checked: bool) -> void:
	var loc := _resolve(index)
	if loc.is_empty():
		return
	var note: PostIt = loc[0]
	note.set_item_checked(loc[1], checked)
	if checked and note == active_note and note.checked_count() >= SEAL_AT_CHECKED:
		_seal_active()

func clear_items() -> void:
	for note in notes:
		note.queue_free()
	notes.clear()
	active_note = null
	special_notes.clear()
	special_colors.clear()
	punishment_note = null
	prep_note = null
	tutorial_note = null
	tutorial_running = false
	tutorial_texts.clear()
	_spawn_note(false)

func on_task_added(task: Task) -> void:
	add_item(task.description)

func on_task_completed(task: Task) -> void:
	var special := _special_notes()
	for note in notes:
		if special.has(note):
			continue
		var i := 0
		for todo_item: TodoItem in note.todo_list.get_children():
			if todo_item.text == task.description and not todo_item.checked:
				note.set_item_checked(i, true)
				if note == active_note and note.checked_count() >= SEAL_AT_CHECKED:
					_seal_active()
				return
			i += 1

# --- Notes driven from outside ----------------------------------------------

## Flies in the boss's punishment note listing every task the player owes.
## Only the first one is the player's turn; the rest wait, greyed out.
func start_punishment(descriptions: Array[String]) -> void:
	punishment_note = _spawn_special_note(descriptions)
	_grey_out_from(punishment_note, 1)

## Checks off the punishment task at `index` and hands the player the next one.
func advance_punishment(index: int) -> void:
	_advance_special_note(punishment_note, index)

## Takes the punishment note away again: it leaves whole, it is never sealed.
func end_punishment() -> void:
	_remove_note(punishment_note)
	punishment_note = null

## Flies in the note listing what the player has to sort out before the
## punishment work can start. It sits on top of the punishment note, so taking
## it away reveals the work underneath. Both items are live at once - the player
## can tick them off in either order.
func start_prep_note(descriptions: Array[String]) -> void:
	prep_note = _spawn_special_note(descriptions)

## Ticks a prep item on or off; it mirrors live state, so it can go both ways.
func set_prep_item_checked(index: int, checked: bool) -> void:
	if not prep_note or index >= prep_note.item_count():
		return
	prep_note.set_item_checked(index, checked)

## Takes the prep note away again, revealing the punishment note below it.
func end_prep_note() -> void:
	_remove_note(prep_note)
	prep_note = null

## The player's first day, written out on notes of their own in the regular
## colour - it is the day's plan, not the boss's punishment. The day arrives a
## page at a time, `page_sizes` beats to a note. One beat at a time is live; the
## rest of the page waits, greyed out.
func start_tutorial(descriptions: Array[String], page_sizes: PackedInt32Array) -> void:
	tutorial_texts = descriptions.duplicate()
	tutorial_page_sizes = page_sizes.duplicate()
	tutorial_page_index = 0
	tutorial_page = 0
	tutorial_completed = 0
	tutorial_running = true
	_show_tutorial_page()

## Checks off the tutorial beat at `index` and hands the player the next one,
## turning the page when that was the last beat on it.
func advance_tutorial(index: int) -> void:
	tutorial_completed = maxi(tutorial_completed, index + 1)
	var local := index - tutorial_page
	if is_instance_valid(tutorial_note) and local >= 0 and local < tutorial_note.item_count():
		tutorial_note.set_item_checked(local, true)
		if local + 1 < tutorial_note.item_count():
			tutorial_note.set_item_pending(local + 1, false)
	_turn_tutorial_page_if_finished()

## Rewrites a tutorial beat, so a beat can carry its own progress.
func set_tutorial_item_text(index: int, text: String) -> void:
	if index >= tutorial_texts.size():
		return
	tutorial_texts[index] = text
	var local := index - tutorial_page
	if is_instance_valid(tutorial_note) and local >= 0 and local < tutorial_note.item_count():
		tutorial_note.set_item_text(local, text)

# --- Internals --------------------------------------------------------------

## Draws the current page from scratch: which beats are on it, and which of them
## are done, waiting, or the player's turn. Called for a fresh page, so a page
## that arrives already finished (beats can complete while it is on its way in)
## simply turns again.
func _show_tutorial_page() -> void:
	if not tutorial_running or tutorial_page_index >= tutorial_page_sizes.size():
		return

	var page: Array[String] = []
	var page_end := mini(tutorial_page + tutorial_page_sizes[tutorial_page_index], tutorial_texts.size())
	for i in range(tutorial_page, page_end):
		page.append(tutorial_texts[i])
	if page.is_empty():
		return

	tutorial_note = _spawn_special_note(page, note_color)
	for i in page.size():
		var beat := tutorial_page + i
		tutorial_note.set_item_checked(i, beat < tutorial_completed)
		tutorial_note.set_item_pending(i, beat > tutorial_completed)

	_turn_tutorial_page_if_finished()

## Every beat on the page is done and there are more to come: let the finished
## page be read for a moment, then send it off and bring in the next one.
func _turn_tutorial_page_if_finished() -> void:
	if not is_instance_valid(tutorial_note):
		return
	if tutorial_completed < tutorial_page + tutorial_note.item_count():
		return
	# The last page stays: its beat is the rest of the day, and checking it off
	# is the end of the game.
	if tutorial_page_index + 1 >= tutorial_page_sizes.size():
		return

	var leaving := tutorial_note
	tutorial_note = null
	tutorial_page += leaving.item_count()
	tutorial_page_index += 1

	var turn := create_tween()
	turn.tween_interval(TUTORIAL_PAGE_TURN_DELAY)
	turn.tween_callback(_remove_note.bind(leaving))
	turn.tween_callback(_show_tutorial_page)

## The externally driven notes, bottom to top, skipping any that have left.
func _special_notes() -> Array[PostIt]:
	var alive: Array[PostIt] = []
	for note in special_notes:
		if is_instance_valid(note):
			alive.append(note)
	return alive

## Flies in a note on top of the pile, listing `descriptions`.
func _spawn_special_note(descriptions: Array[String], color := PUNISHMENT_COLOR) -> PostIt:
	var note := _spawn_note(true, true, color)
	for description in descriptions:
		note.add_item(description)
	return note

## Greys out every item from `index` on: they are not the player's turn yet.
func _grey_out_from(note: PostIt, index: int) -> void:
	for i in range(index, note.item_count()):
		note.set_item_pending(i, true)

## Checks off item `index` and hands the player the one after it.
func _advance_special_note(note: PostIt, index: int) -> void:
	if not is_instance_valid(note) or index >= note.item_count():
		return
	note.set_item_checked(index, true)
	if index + 1 < note.item_count():
		note.set_item_pending(index + 1, false)

## Sends a note off the top of the pile for good, instead of sealing it.
func _remove_note(note: PostIt) -> void:
	if not is_instance_valid(note):
		return

	notes.erase(note)
	special_notes.erase(note)
	special_colors.erase(note)

	var leave := create_tween()
	leave.set_parallel(true)
	leave.tween_property(note, "position", note.position + Vector2(0.0, -FLY_IN_HEIGHT), FLY_IN_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	leave.tween_property(note, "modulate:a", 0.0, FLY_IN_DURATION)
	leave.chain().tween_callback(note.queue_free)

	_restack()

## Maps a global item index to [note, local_index]; empty array if out of range.
## The boss's notes are addressed separately and do not take up indices.
func _resolve(index: int) -> Array:
	var remaining := index
	var special := _special_notes()
	for note in notes:
		if special.has(note):
			continue
		var count := note.item_count()
		if remaining < count:
			return [note, remaining]
		remaining -= count
	return []

func _spawn_note(animate: bool, is_special := false, special_color := PUNISHMENT_COLOR) -> PostIt:
	var note: PostIt = PostItScene.instantiate()
	note.connect_events = false
	note.note_color = special_color if is_special else note_color
	notes_root.add_child(note)
	# Give each note a fixed slight tilt, alternating lean per note, kept for
	# the note's whole life so it stays visibly angled as it moves back.
	var lean := 1.0 if notes.size() % 2 == 0 else -1.0
	note.rotation = deg_to_rad(lean * randf_range(MIN_TILT, MAX_TILT))

	if is_special:
		special_notes.append(note)
		special_colors[note] = special_color
		notes.append(note)
	else:
		# The boss's notes stay on top, so regular notes slot in below them.
		notes.insert(notes.size() - _special_notes().size(), note)
		active_note = note

	_restack(note if animate else null)
	return note

## Seals the current top note and flies in a fresh one, carrying any still
## unchecked (active) items over so they stay visible on top.
func _seal_active() -> void:
	var sealed := active_note
	var new_note := _spawn_note(true)

	var unchecked: Array[TodoItem] = []
	for todo_item: TodoItem in sealed.todo_list.get_children():
		if not todo_item.checked:
			unchecked.append(todo_item)
	for todo_item in unchecked:
		todo_item.reparent(new_note.todo_list)
		todo_item.box_color = new_note.note_color

## Re-applies the layered pose to every note. depth 0 is the top/newest note;
## older notes step further back. Each note keeps its own fixed tilt (set in
## _spawn_note); only the depth-based position is (re)animated here.
## `fly_in_note`, when given, drops in from above instead of sliding into place.
func _restack(fly_in_note: PostIt = null) -> void:
	var count := notes.size()
	var special := _special_notes()
	for i in count:
		var note := notes[i]
		var depth := count - 1 - i
		var target_pos := _pose_position(depth, note.rotation)
		# Draw order comes from child order (the top note is the last child);
		# z_index is left at 0 so notes stay in front of the office background.
		notes_root.move_child(note, i)
		var base_color: Color = special_colors.get(note, note_color) if special.has(note) else note_color
		note.note_color = base_color.darkened(minf(depth, MAX_VISIBLE_DEPTH) * DEPTH_DARKEN)

		if note == fly_in_note:
			note.position = target_pos + Vector2(0.0, -FLY_IN_HEIGHT)
			var fly := create_tween()
			fly.tween_property(note, "position", target_pos, FLY_IN_DURATION) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif depth == 0 and count == 1:
			note.position = target_pos
		else:
			var tween := create_tween()
			tween.tween_property(note, "position", target_pos, POSE_DURATION) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Node2D rotates around its origin (the note's top-left corner). To keep a
## tilted note visually centered on its depth's target point, place its origin
## so the rotated center lands there.
func _pose_position(depth: int, tilt: float) -> Vector2:
	var d := mini(depth, MAX_VISIBLE_DEPTH)
	var center := NOTE_CENTER + DEPTH_OFFSET * float(d)
	return center - NOTE_CENTER.rotated(tilt)
