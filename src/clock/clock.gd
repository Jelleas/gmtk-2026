extends Node2D

signal total_multiplier_changed(multiplier: float, cap: float)

@onready var clock_viewport: SubViewport = $ClockViewport
@onready var clock_surface: Polygon2D = $ClockSurface

var active_multipliers: Dictionary[StringName, float] = {}
var is_punished := false

## The clock does not move until the day is started, so the tutorial can hold it
## at the opening time until the player has done something worth timing.
var is_running = false

## Under this much left on the clock, the day is on its last hour.
const LAST_HOUR := 3600
## Spinner x phone x video: 2 x 10 x 10.
const MAX_TOTAL_MULTIPLIER := 200.0

var realtime = 0.0
var time = 10 * 3600
var last_hour_announced := false

func _ready() -> void:
	clock_surface.texture = clock_viewport.get_texture()
	EventBus.day_started.connect(on_day_start)
	EventBus.activity_started.connect(on_activity_start)
	EventBus.activity_ended.connect(on_activity_end)
	EventBus.punishment_started.connect(on_punishment_start)
	EventBus.punishment_ended.connect(on_punishment_end)
	
	%TimeLabel.text = format_time(time)
	_update_multiplier_display()

func _process(delta: float) -> void:
	if not is_running:
		return
	
	realtime += delta
	# The clock stands still while the boss has the player doing punishment work.
	if is_punished:
		return

	time -= delta * 60 * positive_multiplier() * negative_multiplier()

	if time <= LAST_HOUR and not last_hour_announced:
		last_hour_announced = true
		EventBus.last_hour_started.emit()

	if time <= 0:
		EventBus.day_ended.emit(realtime)
		is_running = false
		time = 0
	
	%TimeLabel.text = format_time(time)

func on_day_start():
	is_running = true

func on_activity_start(source_id: StringName, multiplier: float) -> void:
	active_multipliers[source_id] = multiplier
	_update_multiplier_display()
	
func on_activity_end(source_id: StringName) -> void:
	active_multipliers.erase(source_id)
	_update_multiplier_display()

func on_punishment_start(_activity_count: int) -> void:
	is_punished = true

func on_punishment_end() -> void:
	is_punished = false

func format_time(seconds: float) -> String:
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total / 60) % 60
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func positive_multiplier() -> float:
	var multiplier := 1.0
	for multi in active_multipliers.values():
		multiplier *= multi
	return multiplier

func max_total_multiplier() -> float:
	return MAX_TOTAL_MULTIPLIER

func negative_multiplier() -> float:
	var hours = 8 - (time / 3600)
	return 1 / exp(hours / (10 - hours))

func _update_multiplier_display() -> void:
	total_multiplier_changed.emit(positive_multiplier(), MAX_TOTAL_MULTIPLIER)
