extends Node2D

@export var clock_path: NodePath
@export var coffee_buff_path: NodePath

@onready var display: Node2D = $Display
@onready var panel: PanelContainer = $Display/PanelContainer
@onready var multiplier_label: Label = %MultiplierLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var coffee_glow: Panel = %CoffeeGlow
@onready var coffee_indicator: Label = %CoffeeIndicator

var clock: Node
var coffee_buff: CoffeeBuff
var multiplier := 1.0
var cap := 1.0
var float_time := 0.0
var glow_tween: Tween


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
	coffee_buff = get_node_or_null(coffee_buff_path) as CoffeeBuff
	if coffee_buff != null:
		coffee_buff.buff_state_changed.connect(_on_coffee_buff_state_changed)
		_on_coffee_buff_state_changed(coffee_buff.is_active)
	call_deferred("_sync_glow_size")


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


func _on_coffee_buff_state_changed(is_active: bool) -> void:
	coffee_indicator.visible = is_active
	coffee_glow.visible = is_active
	call_deferred("_sync_glow_size")
	if glow_tween != null:
		glow_tween.kill()

	if not is_active:
		return

	coffee_glow.modulate.a = 0.9
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(coffee_glow, "modulate:a", 0.35, 0.55)
	glow_tween.tween_property(coffee_glow, "modulate:a", 0.9, 0.55)


func _sync_glow_size() -> void:
	coffee_glow.position = panel.position - Vector2(4.0, 4.0)
	coffee_glow.size = panel.size + Vector2(8.0, 8.0)
