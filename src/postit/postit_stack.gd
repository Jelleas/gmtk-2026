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
## The boss's notes, bottom to top. They are kept at the tail of `notes`, so
## regular notes always slot in underneath them.
var special_notes: Array[PostIt] = []
## The punishment note, while the boss has one out.
var punishment_note: PostIt
## The prep note listing what to sort out before the punishment work starts.
var prep_note: PostIt

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
	punishment_note = null
	prep_note = null
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

# --- The boss's notes -------------------------------------------------------

## Flies in the boss's punishment note listing every task the player owes.
## Only the first one is the player's turn; the rest wait, greyed out.
func start_punishment(descriptions: Array[String]) -> void:
	var note := _spawn_special_note(descriptions)
	punishment_note = note
	for i in descriptions.size():
		note.set_item_pending(i, i > 0)

## Checks off the punishment task at `index` and hands the player the next one.
func advance_punishment(index: int) -> void:
	if not punishment_note:
		return
	punishment_note.set_item_checked(index, true)
	if index + 1 < punishment_note.item_count():
		punishment_note.set_item_pending(index + 1, false)

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

# --- Internals --------------------------------------------------------------

## The boss's notes, bottom to top, skipping any that have already left.
func _special_notes() -> Array[PostIt]:
	var alive: Array[PostIt] = []
	for note in special_notes:
		if is_instance_valid(note):
			alive.append(note)
	return alive

## Flies in one of the boss's notes on top of the pile, listing `descriptions`.
func _spawn_special_note(descriptions: Array[String]) -> PostIt:
	var note := _spawn_note(true, true)
	for description in descriptions:
		note.add_item(description)
	return note

## Sends a note off the top of the pile for good, instead of sealing it.
func _remove_note(note: PostIt) -> void:
	if not is_instance_valid(note):
		return

	notes.erase(note)
	special_notes.erase(note)

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

func _spawn_note(animate: bool, is_special := false) -> PostIt:
	var note: PostIt = PostItScene.instantiate()
	note.connect_events = false
	note.note_color = PUNISHMENT_COLOR if is_special else note_color
	notes_root.add_child(note)
	# Give each note a fixed slight tilt, alternating lean per note, kept for
	# the note's whole life so it stays visibly angled as it moves back.
	var lean := 1.0 if notes.size() % 2 == 0 else -1.0
	note.rotation = deg_to_rad(lean * randf_range(MIN_TILT, MAX_TILT))

	if is_special:
		special_notes.append(note)
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
		var base_color := PUNISHMENT_COLOR if special.has(note) else note_color
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
