extends Control

const SOURCE_ID := &"dating_app"
## The biggest payout of the three, because it costs the most to run: the drawer
## has to be open, a swipe is needed every SWIPE_RESET_DELAY to hold the bonus up,
## and dragging the drawer shut is the slowest way to go clean when the boss rises.
const ACTIVITY_BONUS := 4.0
const SWIPE_BONUS_INCREASE := 0.5
const MAX_ACTIVITY_BONUS := 7.0
const SWIPE_RESET_DELAY := 3.0
const CARDS_VISIBLE_PROGRESS := 0.92

@export var drawer_path: NodePath

@onready var app_viewport: SubViewport = $AppViewport
@onready var phone_surface: Polygon2D = $PhoneSurface
@onready var dating_app: DatingApp = %DatingApp

var drawer: OfficeDrawer
var is_activity_active := false
var is_boss_watching := false
var is_punishment_active := false
var current_activity_bonus := ACTIVITY_BONUS
var swipe_reset_timer: Timer

func _ready() -> void:
	phone_surface.texture = app_viewport.get_texture()
	if not drawer_path.is_empty():
		drawer = get_node_or_null(drawer_path) as OfficeDrawer
	if drawer:
		drawer.progress_changed.connect(_on_drawer_progress_changed)
		drawer.opened.connect(_on_drawer_opened)
		drawer.closing.connect(_on_drawer_closing)
	dating_app.profile_swiped.connect(_on_profile_swiped)
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	EventBus.boss_watch_started.connect(_on_boss_watch_started)
	EventBus.boss_watch_ended.connect(_on_boss_watch_ended)
	swipe_reset_timer = Timer.new()
	swipe_reset_timer.one_shot = true
	swipe_reset_timer.wait_time = SWIPE_RESET_DELAY
	swipe_reset_timer.timeout.connect(_reset_swipe_bonus)
	add_child(swipe_reset_timer)
	phone_surface.hide()
	_update_phone_access()
	if drawer == null or drawer.is_open:
		_show_cards()

func _exit_tree() -> void:
	_stop_activity()

func _on_drawer_opened() -> void:
	_show_cards()

func _on_drawer_closing() -> void:
	_hide_cards()


func _on_drawer_progress_changed(progress: float) -> void:
	if progress >= CARDS_VISIBLE_PROGRESS:
		_show_cards()
	else:
		_hide_cards()


func _hide_cards() -> void:
	phone_surface.hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stop_activity()


func _show_cards() -> void:
	if not _can_open_phone():
		_hide_cards()
		return
	phone_surface.show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_start_activity()


func _gui_input(event: InputEvent) -> void:
	if not _can_open_phone():
		accept_event()
		return

	if event is InputEventMouse:
		_forward_input(event, event.position)
	elif event is InputEventScreenTouch:
		_forward_input(event, event.position)
	elif event is InputEventScreenDrag:
		_forward_input(event, event.position)


func _input(event: InputEvent) -> void:
	if not _can_open_phone() or not dating_app.is_dragging:
		return

	if event is InputEventMouse:
		_forward_input(event, get_global_transform().affine_inverse() * event.position, true)
	elif event is InputEventScreenTouch:
		_forward_input(event, get_global_transform().affine_inverse() * event.position, true)
	elif event is InputEventScreenDrag:
		_forward_input(event, get_global_transform().affine_inverse() * event.position, true)
	else:
		return

	get_viewport().set_input_as_handled()


func _forward_input(event: InputEvent, input_position: Vector2, allow_outside := false) -> void:
	if not _can_open_phone() or not phone_surface.visible:
		return

	var surface_point: Vector2 = phone_surface.get_global_transform().affine_inverse() * (get_global_transform() * input_position)
	var app_position = _map_to_app(surface_point, allow_outside)
	if app_position == null:
		return

	if event is InputEventMouseButton:
		var mouse_button := event.duplicate() as InputEventMouseButton
		mouse_button.position = app_position
		mouse_button.global_position = app_position
		dating_app._gui_input(mouse_button)
	elif event is InputEventMouseMotion:
		var mouse_motion := event.duplicate() as InputEventMouseMotion
		mouse_motion.position = app_position
		mouse_motion.global_position = app_position
		dating_app._gui_input(mouse_motion)
	elif event is InputEventScreenTouch:
		var screen_touch := event.duplicate() as InputEventScreenTouch
		screen_touch.position = app_position
		dating_app._gui_input(screen_touch)
	elif event is InputEventScreenDrag:
		var screen_drag := event.duplicate() as InputEventScreenDrag
		screen_drag.position = app_position
		dating_app._gui_input(screen_drag)
	else:
		return

	accept_event()


func _map_to_app(point: Vector2, allow_outside: bool):
	var polygon := phone_surface.polygon
	var uv := phone_surface.uv
	if polygon.size() != 4 or uv.size() != 4:
		return null

	var mapped_position = _map_triangle(point, polygon[0], polygon[1], polygon[2], uv[0], uv[1], uv[2], allow_outside)
	if mapped_position != null:
		return mapped_position
	return _map_triangle(point, polygon[0], polygon[2], polygon[3], uv[0], uv[2], uv[3], allow_outside)


func _map_triangle(point: Vector2, first: Vector2, second: Vector2, third: Vector2, first_uv: Vector2, second_uv: Vector2, third_uv: Vector2, allow_outside: bool):
	var denominator := (second.y - third.y) * (first.x - third.x) + (third.x - second.x) * (first.y - third.y)
	if is_zero_approx(denominator):
		return null

	var first_weight := ((second.y - third.y) * (point.x - third.x) + (third.x - second.x) * (point.y - third.y)) / denominator
	var second_weight := ((third.y - first.y) * (point.x - third.x) + (first.x - third.x) * (point.y - third.y)) / denominator
	var third_weight := 1.0 - first_weight - second_weight
	if not allow_outside and (first_weight < 0.0 or second_weight < 0.0 or third_weight < 0.0):
		return null

	return first_uv * first_weight + second_uv * second_weight + third_uv * third_weight


func _start_activity() -> void:
	if is_activity_active or not _can_activate_activity():
		return

	is_activity_active = true
	EventBus.activity_started.emit(SOURCE_ID, current_activity_bonus)

func _stop_activity() -> void:
	if not is_activity_active:
		return

	is_activity_active = false
	swipe_reset_timer.stop()
	current_activity_bonus = ACTIVITY_BONUS
	EventBus.activity_ended.emit(SOURCE_ID)


func _on_profile_swiped() -> void:
	if not is_activity_active or not _can_activate_activity():
		return

	current_activity_bonus = minf(
		MAX_ACTIVITY_BONUS,
		current_activity_bonus + SWIPE_BONUS_INCREASE,
	)
	swipe_reset_timer.start()
	EventBus.activity_started.emit(SOURCE_ID, current_activity_bonus)


func _reset_swipe_bonus() -> void:
	current_activity_bonus = ACTIVITY_BONUS
	if is_activity_active and _can_activate_activity():
		EventBus.activity_started.emit(SOURCE_ID, current_activity_bonus)


func _on_punishment_started(_activity_count: int) -> void:
	is_punishment_active = true
	current_activity_bonus = 0.0
	swipe_reset_timer.stop()
	if is_activity_active:
		EventBus.activity_started.emit(SOURCE_ID, current_activity_bonus)
	_update_phone_access()


func _on_punishment_ended() -> void:
	is_punishment_active = false
	# The punishment zeroed the bonus on an activity that is still flagged active,
	# so _start_activity() will not run again to put it back. Without this the
	# phone stays worth nothing until the drawer is closed and reopened.
	current_activity_bonus = ACTIVITY_BONUS
	if is_activity_active:
		EventBus.activity_started.emit(SOURCE_ID, current_activity_bonus)
	_update_phone_access()


func _on_boss_watch_started() -> void:
	is_boss_watching = true
	_update_phone_access()


func _on_boss_watch_ended() -> void:
	is_boss_watching = false
	_update_phone_access()


func _can_open_phone() -> bool:
	return _can_activate_activity()


func _can_activate_activity() -> bool:
	return not is_punishment_active


func _update_phone_access() -> void:
	if drawer:
		drawer.can_open = _can_activate_activity()
	if not _can_open_phone():
		dating_app.cancel_drag()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	elif phone_surface.visible:
		mouse_filter = Control.MOUSE_FILTER_STOP
	elif drawer == null or drawer.is_open:
		_show_cards()
