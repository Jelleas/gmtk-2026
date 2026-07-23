class_name PhoneDrawer
extends Control

signal opened
signal closing
signal closed
signal progress_changed(progress: float)

const OPEN_TRAVEL := 140.0
const SWIPE_DECISION_DISTANCE := 24.0

@export var starts_open := true

@onready var drawer_front: Panel = %DrawerFront

var open_progress := 0.0
var is_open := false
var is_dragging := false
var drag_start_y := 0.0
var drag_start_progress := 0.0
var slide_tween: Tween


func _ready() -> void:
	is_open = starts_open
	_set_open_progress(1.0 if is_open else 0.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position.y)
		else:
			_end_drag(event.position.y)
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position.y)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position.y)
		else:
			_end_drag(event.position.y)
	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(event.position.y)


func _begin_drag(pointer_y: float) -> void:
	if slide_tween:
		slide_tween.kill()

	is_dragging = true
	drag_start_y = pointer_y
	drag_start_progress = open_progress


func _update_drag(pointer_y: float) -> void:
	_set_open_progress(clampf(drag_start_progress + (pointer_y - drag_start_y) / OPEN_TRAVEL, 0.0, 1.0))


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


func set_open(open: bool) -> void:
	is_open = open
	if slide_tween:
		slide_tween.kill()

	if not open:
		closing.emit()

	var target_progress := 1.0 if open else 0.0
	slide_tween = create_tween()
	slide_tween.tween_method(_set_open_progress, open_progress, target_progress, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if open:
		slide_tween.tween_callback(opened.emit)
	else:
		slide_tween.tween_callback(closed.emit)


func _set_open_progress(value: float) -> void:
	open_progress = value
	drawer_front.position.y = OPEN_TRAVEL * open_progress
	progress_changed.emit(open_progress)
