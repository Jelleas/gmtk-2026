class_name OfficeDrawer
extends AnimatedSprite2D

signal opened
signal closing
signal closed
signal progress_changed(progress: float)

@export var starts_open := true
@export var phone_stow_position := Vector2(1008.0, 605.0)
@export var phone_entry_height := 55.0

@onready var drawer_input: Control = $DrawerInput

var open_progress := 0.0
var is_open := false
var can_open := true
var slide_tween: Tween


func _ready() -> void:
	is_open = starts_open
	_set_open_progress(1.0 if is_open else 0.0)
	drawer_input.gui_input.connect(_on_drawer_input)


func _on_drawer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_open(not is_open)
	elif event is InputEventScreenTouch and event.pressed:
		set_open(not is_open)


func set_open(open: bool) -> void:
	if open and not can_open:
		return

	# Repeated requests for the current state should be silent.
	var target := 1.0 if open else 0.0
	if not is_equal_approx(open_progress, target):
		Sfx.play(Sfx.DRAWER_OPEN if open else Sfx.DRAWER_CLOSE)

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
