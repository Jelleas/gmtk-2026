class_name CoffeeBuff
extends Control

signal buff_state_changed(is_active: bool)
signal visual_state_changed(is_active: bool, fill_amount: float, is_ready: bool)

const SOURCE_ID := &"coffee"

@export var multiplier := 1.5
@export var duration := 6.0
@export var cooldown := 20.0
@export var refill_delay := 0.5

@onready var active_timer: Timer = $ActiveTimer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var refill_delay_timer: Timer = $RefillDelayTimer

var is_active := false
var is_interaction_enabled := false
var is_refill_pending := false


func _ready() -> void:
	active_timer.timeout.connect(_on_active_timer_timeout)
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	refill_delay_timer.timeout.connect(_on_refill_delay_timer_timeout)
	tooltip_text = "Drink coffee: %.1fx time for %d seconds" % [multiplier, int(duration)]
	_emit_visual_state()


func _process(_delta: float) -> void:
	if is_active or not cooldown_timer.is_stopped():
		_emit_visual_state()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if not _can_activate():
		return

	activate()
	accept_event()


func set_interaction_enabled(enabled: bool) -> void:
	is_interaction_enabled = enabled
	_emit_visual_state()


func activate() -> void:
	if not _can_activate():
		return

	is_active = true
	EventBus.buff_started.emit(SOURCE_ID, multiplier)
	active_timer.start(duration)
	buff_state_changed.emit(true)
	_emit_visual_state()


func reset() -> void:
	active_timer.stop()
	cooldown_timer.stop()
	refill_delay_timer.stop()
	is_refill_pending = false
	_end_buff()
	_emit_visual_state()


func _on_active_timer_timeout() -> void:
	_end_buff()
	is_refill_pending = true
	refill_delay_timer.start(refill_delay)
	_emit_visual_state()


func _on_refill_delay_timer_timeout() -> void:
	is_refill_pending = false
	cooldown_timer.start(cooldown)
	_emit_visual_state()


func _on_cooldown_timer_timeout() -> void:
	_emit_visual_state()


func _end_buff() -> void:
	if not is_active:
		return

	is_active = false
	EventBus.buff_ended.emit(SOURCE_ID)
	buff_state_changed.emit(false)


func _can_activate() -> bool:
	return is_interaction_enabled and not is_active and not is_refill_pending and cooldown_timer.is_stopped()


func refresh_visual_state() -> void:
	_emit_visual_state()


func _emit_visual_state() -> void:
	var fill_amount := 1.0
	if is_active:
		fill_amount = active_timer.time_left / maxf(duration, 0.001)
	elif is_refill_pending:
		fill_amount = 0.0
	elif not cooldown_timer.is_stopped():
		fill_amount = 1.0 - cooldown_timer.time_left / maxf(cooldown, 0.001)
	visual_state_changed.emit(is_active, clampf(fill_amount, 0.0, 1.0), _can_activate())
