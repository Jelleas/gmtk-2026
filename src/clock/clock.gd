extends Node2D

var is_running = true

var realtime = 0.0
var time = 10 * 3600

func _ready() -> void:
	EventBus.day_started.connect(on_day_start)
	
	%TimeLabel.text = format_time(time)

func _process(delta: float) -> void:
	if not is_running:
		return
	
	realtime += delta
	time -= delta * 60 * negative_multiplier()
	
	if time <= 0:
		EventBus.day_ended.emit(realtime)
		is_running = false
		time = 0
	
	%TimeLabel.text = format_time(time)

func on_day_start():
	is_running = true

func format_time(seconds: float) -> String:
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total / 60) % 60
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func negative_multiplier():
	var hours = 8 - (time / 3600)
	return 1 / exp(hours / (10 - hours))
