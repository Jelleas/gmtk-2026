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
const DEPTH_OFFSET := Vector2(6.0, -7.0)
const ANGLE_STEP := 3.0
const MAX_VISIBLE_DEPTH := 4

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
## older notes step back and rotate slightly for the stacked look.
func _restack(animate_new_note: bool) -> void:
	var count := notes.size()
	for i in count:
		var note := notes[i]
		var depth := count - 1 - i
		var target_pos := _pose_position(depth)
		var target_rot := _pose_rotation(depth)
		note.z_index = -depth

		if depth == 0:
			if animate_new_note:
				note.rotation = target_rot
				note.position = target_pos + Vector2(0.0, -FLY_IN_HEIGHT)
				var fly := create_tween()
				fly.tween_property(note, "position", target_pos, FLY_IN_DURATION) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				note.position = target_pos
				note.rotation = target_rot
			continue

		var tween := create_tween().set_parallel()
		tween.tween_property(note, "position", target_pos, POSE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(note, "rotation", target_rot, POSE_DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _pose_position(depth: int) -> Vector2:
	var d := mini(depth, MAX_VISIBLE_DEPTH)
	return DEPTH_OFFSET * float(d)

func _pose_rotation(depth: int) -> float:
	var d := mini(depth, MAX_VISIBLE_DEPTH)
	if d == 0:
		return 0.0
	var sign := 1.0 if d % 2 == 1 else -1.0
	return deg_to_rad(sign * ANGLE_STEP * float(d))
