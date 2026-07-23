extends Node2D

var active_multipliers: Dictionary[StringName, float] = {}
var punishment_weight := 0.0

var is_running = true

var realtime = 0.0
var time = 10 * 3600

func _ready() -> void:
	EventBus.day_started.connect(on_day_start)
	EventBus.activity_started.connect(on_activity_start)
	EventBus.activity_ended.connect(on_activity_end)
	EventBus.punish.connect(on_punish)
	EventBus.punishment_ended.connect(on_punishment_end)
	
	%TimeLabel.text = format_time(time)

func _process(delta: float) -> void:
	if not is_running:
		return
	
	realtime += delta
	if punishment_weight > 0.0:
		time += delta * 60 * punishment_weight
	else:
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

func on_punish(weight: float) -> void:
	punishment_weight = weight

func on_punishment_end() -> void:
	punishment_weight = 0.0

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
