class_name PostItStack
extends Node2D

## A layered stack of PostIt notes. Drop-in replacement for a single PostIt:
## it owns the active-task logic (EventBus subscriptions) and exposes the same
## public API. New tasks land on the top note; once a note reaches
## SEAL_AT_CHECKED checked-off tasks it is sealed and a fresh note flies in
## from the top, keeping any still-active tasks visible on the new top note.

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

@export var note_color: Color = Color(1.0, 0.94, 0.42):
	set(value):
		note_color = value
		for note in notes:
			if is_instance_valid(note):
				note.note_color = value

@onready var notes_root: Node2D = $Notes

## Notes in creation order (notes[0] is oldest, notes.back() is the top note).
var notes: Array[PostIt] = []
## The top / newest note where new items are added.
var active_note: PostIt

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
	_spawn_note(false)

func on_task_added(task: Task) -> void:
	add_item(task.description)

func on_task_completed(task: Task) -> void:
	for note in notes:
		var i := 0
		for todo_item: TodoItem in note.todo_list.get_children():
			if todo_item.text == task.description and not todo_item.checked:
				note.set_item_checked(i, true)
				if note == active_note and note.checked_count() >= SEAL_AT_CHECKED:
					_seal_active()
				return
			i += 1

# --- Internals --------------------------------------------------------------

## Maps a global item index to [note, local_index]; empty array if out of range.
func _resolve(index: int) -> Array:
	var remaining := index
	for note in notes:
		var count := note.item_count()
		if remaining < count:
			return [note, remaining]
		remaining -= count
	return []

func _spawn_note(animate: bool) -> PostIt:
	var note: PostIt = PostItScene.instantiate()
	note.connect_events = false
	note.note_color = note_color
	notes_root.add_child(note)
	# Give each note a fixed slight tilt, alternating lean per note, kept for
	# the note's whole life so it stays visibly angled as it moves back.
	var lean := 1.0 if notes.size() % 2 == 0 else -1.0
	note.rotation = deg_to_rad(lean * randf_range(MIN_TILT, MAX_TILT))
	notes.append(note)
	active_note = note
	_restack(animate)
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

## Re-applies the layered pose to every note. depth 0 is the top/newest note;
## older notes step further back. Each note keeps its own fixed tilt (set in
## _spawn_note); only the depth-based position is (re)animated here.
func _restack(animate_new_note: bool) -> void:
	var count := notes.size()
	for i in count:
		var note := notes[i]
		var depth := count - 1 - i
		var target_pos := _pose_position(depth, note.rotation)
		# Draw order comes from child order (newest is the last child, on top);
		# z_index is left at 0 so notes stay in front of the office background.
		note.note_color = note_color.darkened(minf(depth, MAX_VISIBLE_DEPTH) * DEPTH_DARKEN)

		if depth == 0 and animate_new_note:
			note.position = target_pos + Vector2(0.0, -FLY_IN_HEIGHT)
			var fly := create_tween()
			fly.tween_property(note, "position", target_pos, FLY_IN_DURATION) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif depth == 0:
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
