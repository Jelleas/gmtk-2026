extends Node2D

var time = 0.0

func _ready() -> void:
	%TimeLabel.text = str(time)

func _process(delta: float) -> void:
	time += delta
	%TimeLabel.text = str(time)
