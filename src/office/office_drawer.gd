class_name OfficeDrawer
extends AnimatedSprite2D

signal opened
signal closing
signal closed
signal progress_changed(progress: float)

const SWIPE_DECISION_DISTANCE := 24.0

@export var starts_open := true
@export var interaction_rect := Rect2(850.0, 540.0, 430.0, 180.0)
@export var phone_stow_position := Vector2(1008.0, 605.0)
@export var phone_entry_height := 55.0

@onready var drawer_input: Control = $DrawerInput

var open_progress := 0.0
var is_open := false
var is_dragging := false
var drag_start_y := 0.0
var drag_start_progress := 0.0
var slide_tween: Tween


func _ready() -> void:
	is_open = starts_open
	_set_open_progress(1.0 if is_open else 0.0)
	drawer_input.gui_input.connect(_on_drawer_input)


func _on_drawer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(_to_global_y(event.position))
		else:
			_end_drag(_to_global_y(event.position))
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(_to_global_y(event.position))
		else:
			_end_drag(_to_global_y(event.position))


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag(event.position.y)
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_end_drag(event.position.y)
	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(event.position.y)
		get_viewport().set_input_as_handled()


func _begin_drag(pointer_y: float) -> void:
	if slide_tween:
		slide_tween.kill()

	is_dragging = true
	drag_start_y = pointer_y
	drag_start_progress = open_progress


func _update_drag(pointer_y: float) -> void:
	_set_open_progress(clampf(drag_start_progress + (pointer_y - drag_start_y) / interaction_rect.size.y, 0.0, 1.0))


func _end_drag(pointer_y: float) -> void:
	if not is_dragging:
		return

	is_dragging = false
	var drag_distance := pointer_y - drag_start_y
	if drag_distance > SWIPE_DECISION_DISTANCE:
		set_open(true)
	elif drag_distance < -SWIPE_DECISION_DISTANCE:
		set_open(false)
	else:
		set_open(open_progress >= 0.5)


func _to_global_y(local_position: Vector2) -> float:
	return (drawer_input.get_global_transform() * local_position).y


func set_open(open: bool) -> void:
	is_open = open
	if slide_tween:
		slide_tween.kill()

	if not open:
		closing.emit()

	var target_progress := 1.0 if open else 0.0
	slide_tween = create_tween()
	slide_tween.tween_method(_set_open_progress, open_progress, target_progress, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if open:
		slide_tween.tween_callback(opened.emit)
	else:
		slide_tween.tween_callback(closed.emit)


func get_phone_stow_position() -> Vector2:
	return to_global(phone_stow_position)


func get_phone_entry_position() -> Vector2:
	return to_global(phone_stow_position - Vector2(0.0, phone_entry_height))


func _set_open_progress(value: float) -> void:
	open_progress = value
	var frame_count := sprite_frames.get_frame_count(animation)
	frame = roundi(open_progress * (frame_count - 1))
	progress_changed.emit(open_progress)
