extends Node2D

var time = 0.0

func _ready() -> void:
	%TimeLabel.text = _format_time(time)

func _process(delta: float) -> void:
	time += delta
	%TimeLabel.text = _format_time(time)

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total / 60) % 60
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
