extends Node2D

@onready var clock_viewport: SubViewport = $ClockViewport
@onready var clock_surface: Polygon2D = $ClockSurface

var active_multipliers: Dictionary[StringName, float] = {}
var is_punished := false

var is_running = true

var realtime = 0.0
var time = 10 * 3600

func _ready() -> void:
	clock_surface.texture = clock_viewport.get_texture()
	EventBus.day_started.connect(on_day_start)
	EventBus.activity_started.connect(on_activity_start)
	EventBus.activity_ended.connect(on_activity_end)
	EventBus.punishment_started.connect(on_punishment_start)
	EventBus.punishment_ended.connect(on_punishment_end)
	
	%TimeLabel.text = format_time(time)

func _process(delta: float) -> void:
	if not is_running:
		return
	
	realtime += delta
	# The clock stands still while the boss has the player doing punishment work.
	if is_punished:
		return

	time -= delta * 60 * positive_multiplier() * negative_multiplier()

	if time <= 0:
		EventBus.day_ended.emit(realtime)
		is_running = false
		time = 0
	
	%TimeLabel.text = format_time(time)

func on_day_start():
	is_running = true

func on_activity_start(source_id: StringName, multiplier: float):
	active_multipliers[source_id] = multiplier
	
func on_activity_end(source_id: StringName):
	active_multipliers.erase(source_id)

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

func positive_multiplier():
	var m = 1.0
	for multi in active_multipliers.values():
		m *= multi
	return m

func negative_multiplier():
	var hours = 8 - (time / 3600)
	return 1 / exp(hours / (10 - hours))
