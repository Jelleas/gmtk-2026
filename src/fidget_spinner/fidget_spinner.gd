extends Node2D

signal started(level: int)
signal stopped(forced: bool)

const SOURCE_ID := &"fidget_spinner"
## Worth +2 / +3 / +4 at spin levels 1-3: more than the video, less than the
## phone. The spin timer running out is what keeps it from being free.
const ACTIVITY_BONUS_BASE := 1.0
const ACTIVITY_BONUS_PER_LEVEL := 1.0

@export var spin_duration := 2.5

@onready var spin_timer: Timer = $SpinTimer
var is_running := false
var is_interaction_enabled := true
var is_boss_watching := false
var is_punishment_active := false
var spin_level: int = 0

func _ready() -> void:
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	EventBus.boss_watch_started.connect(_on_boss_watch_started)
	EventBus.boss_watch_ended.connect(_on_boss_watch_ended)

func start() -> void:
	if not is_interaction_enabled or not _can_activate_activity():
		return

	spin_level = clampi(spin_level + 1, 0, 3)
	is_running = true
	spin_timer.start(spin_duration + spin_level * 2.5)
	started.emit(spin_level)
	EventBus.fidget_spun.emit(spin_level)
	EventBus.activity_started.emit(SOURCE_ID, ACTIVITY_BONUS_BASE + spin_level * ACTIVITY_BONUS_PER_LEVEL)

func stop(forced: bool) -> void:
	if not is_running:
		return

	spin_level = 0
	is_running = false
	spin_timer.stop()
	stopped.emit(forced)
	EventBus.activity_ended.emit(SOURCE_ID)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		stop(true)

func set_interaction_enabled(enabled: bool) -> void:
	is_interaction_enabled = enabled
	$ClickArea.input_pickable = enabled

func _on_spin_timer_timeout() -> void:
	stop(false)

func _on_punishment_started(_activity_count: int) -> void:
	is_punishment_active = true

func _on_punishment_ended() -> void:
	is_punishment_active = false

func _on_boss_watch_started() -> void:
	is_boss_watching = true

func _on_boss_watch_ended() -> void:
	is_boss_watching = false

func _can_activate_activity() -> bool:
	return not is_boss_watching and not is_punishment_active
