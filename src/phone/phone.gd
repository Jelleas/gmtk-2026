extends Control

const SOURCE_ID := &"dating_app"
const ACTIVITY_MULTIPLIER := 5.0
const SWIPE_MULTIPLIER_INCREASE := 0.5
const SWIPE_RESET_DELAY := 3.0
const HELD_POSITION := Vector2(14.0, 8.0)
const STOWED_SCALE := Vector2(0.22, 0.22)
const STOWED_ROTATION := PI * 0.5

@onready var phone_body: Panel = %PhoneBody
@onready var drawer: PhoneDrawer = %Drawer
@onready var dating_app: DatingApp = $PhoneBody/Screen/DatingApp

var is_activity_active := false
var current_activity_multiplier := ACTIVITY_MULTIPLIER
var swipe_reset_timer: Timer

func _ready() -> void:
	drawer.progress_changed.connect(_on_drawer_progress_changed)
	drawer.opened.connect(_on_drawer_opened)
	drawer.closing.connect(_on_drawer_closing)
	dating_app.profile_swiped.connect(_on_profile_swiped)
	swipe_reset_timer = Timer.new()
	swipe_reset_timer.one_shot = true
	swipe_reset_timer.wait_time = SWIPE_RESET_DELAY
	swipe_reset_timer.timeout.connect(_reset_swipe_multiplier)
	add_child(swipe_reset_timer)
	phone_body.pivot_offset = phone_body.size * 0.5
	_on_drawer_progress_changed(drawer.open_progress)
	if drawer.is_open:
		_start_activity()

func _exit_tree() -> void:
	_stop_activity()

func _on_drawer_opened() -> void:
	_start_activity()

func _on_drawer_closing() -> void:
	_stop_activity()

func _start_activity() -> void:
	if is_activity_active:
		return

	is_activity_active = true
	EventBus.activity_started.emit(SOURCE_ID, current_activity_multiplier)

func _stop_activity() -> void:
	if not is_activity_active:
		return

	is_activity_active = false
	swipe_reset_timer.stop()
	current_activity_multiplier = ACTIVITY_MULTIPLIER
	EventBus.activity_ended.emit(SOURCE_ID)


func _on_profile_swiped() -> void:
	if not is_activity_active:
		return

	current_activity_multiplier += SWIPE_MULTIPLIER_INCREASE
	swipe_reset_timer.start()
	EventBus.activity_started.emit(SOURCE_ID, current_activity_multiplier)


func _reset_swipe_multiplier() -> void:
	current_activity_multiplier = ACTIVITY_MULTIPLIER
	if is_activity_active:
		EventBus.activity_started.emit(SOURCE_ID, current_activity_multiplier)

func _on_drawer_progress_changed(progress: float) -> void:
	if progress > 0.0:
		phone_body.visible = true

	var stow_progress := 1.0 - progress
	var entry_position := _entry_position()
	if stow_progress <= 0.5:
		phone_body.position = HELD_POSITION.lerp(entry_position, stow_progress * 2.0)
		phone_body.rotation = lerpf(0.0, STOWED_ROTATION, stow_progress * 2.0)
		phone_body.scale = Vector2.ONE.lerp(STOWED_SCALE, stow_progress * 2.0)
	else:
		phone_body.position = entry_position.lerp(_stowed_position(), (stow_progress - 0.5) * 2.0)
		phone_body.rotation = STOWED_ROTATION
		phone_body.scale = STOWED_SCALE
	if is_zero_approx(progress):
		phone_body.hide()

func _stowed_position() -> Vector2:
	var drawer_center := drawer.position + Vector2(drawer.size.x * 0.5, 90.0)
	return drawer_center - phone_body.pivot_offset

func _entry_position() -> Vector2:
	var entry_center := Vector2(_stowed_position().x + phone_body.pivot_offset.x, drawer.position.y - 80.0)
	return entry_center - phone_body.pivot_offset
