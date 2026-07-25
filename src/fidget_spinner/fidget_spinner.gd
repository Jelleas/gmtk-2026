extends Node2D

signal started
signal stopped

const SOURCE_ID := &"fidget_spinner"
const ACTIVITY_MULTIPLIER := 2.0

@export var spin_duration := 60.0

@onready var spin_timer: Timer = $SpinTimer
var is_running := false
var can_activate_activity := true

func _ready() -> void:
	EventBus.punishment_started.connect(_on_deactivate_activity)
	EventBus.boss_watch_started.connect(_on_deactivate_activity)
	EventBus.punishment_ended.connect(_on_activate_activity)
	EventBus.boss_watch_ended.connect(_on_activate_activity)

func start() -> void:
	if is_running or not can_activate_activity:
		return

	is_running = true
	spin_timer.start(spin_duration)
	started.emit()
	EventBus.activity_started.emit(SOURCE_ID, ACTIVITY_MULTIPLIER)

func stop() -> void:
	if not is_running:
		return

	is_running = false
	spin_timer.stop()
	stopped.emit()
	EventBus.activity_ended.emit(SOURCE_ID)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		stop()

func _on_spin_timer_timeout() -> void:
	stop()

func _on_deactivate_activity(_activity_count: int = 0) -> void:
	can_activate_activity = false

func _on_activate_activity() -> void:
	can_activate_activity = true
