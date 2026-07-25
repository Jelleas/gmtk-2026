extends Node2D

@export var clock_path: NodePath

@onready var display: Node2D = $Display
@onready var multiplier_label: Label = %MultiplierLabel
@onready var progress_bar: ProgressBar = %ProgressBar

var clock: Node
var multiplier := 1.0
var cap := 1.0
var float_time := 0.0


func _ready() -> void:
	clock = get_node_or_null(clock_path)
	if clock == null:
		push_warning("Multiplier meter needs a clock node.")
		return

	clock.connect(&"total_multiplier_changed", _on_total_multiplier_changed)
	_on_total_multiplier_changed(
		clock.call(&"positive_multiplier"),
		clock.call(&"max_total_multiplier"),
	)


func _process(delta: float) -> void:
	float_time += delta
	display.position.y = sin(float_time * 1.7) * 3.0
	display.rotation = sin(float_time * 1.1) * 0.012


func _on_total_multiplier_changed(new_multiplier: float, new_cap: float) -> void:
	multiplier = new_multiplier
	cap = new_cap
	multiplier_label.text = _format_multiplier(multiplier)
	progress_bar.value = clampf(multiplier / cap * 100.0, 0.0, 100.0)


func _format_multiplier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(value)
	return "%.1f" % value
