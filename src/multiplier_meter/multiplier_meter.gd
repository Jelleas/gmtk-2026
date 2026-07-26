extends Node2D

@export var clock_path: NodePath
@export var coffee_buff_path: NodePath

@onready var display: Node2D = $Display
@onready var panel: PanelContainer = $Display/PanelContainer
@onready var multiplier_label: Label = %MultiplierLabel
@onready var combo_label: Label = %ComboLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var coffee_glow: Panel = %CoffeeGlow
@onready var coffee_indicator: Label = %CoffeeIndicator

## Where the meter sits when nothing is running, and where it gets to when the day
## is going as fast as it can. Everything between is a lerp on how full the bar is.
const COOL_COLOR := Color(0.92941177, 0.79607844, 0.26666668, 1)
const HOT_COLOR := Color(1.0, 0.36, 0.2, 1)
## The idle bob, and what it grows into. The low end is what the meter has always
## done, so a meter with nothing running looks untouched.
const BOB_PIXELS := Vector2(3.0, 7.0)
const BOB_SPEED := Vector2(1.7, 3.4)
const TILT_RADIANS := Vector2(0.012, 0.035)

const PUNCH_SCALE := 1.12
const PUNCH_SECONDS := 0.18

var clock: Node
var coffee_buff: CoffeeBuff
var multiplier := 1.0
var cap := 1.0
var float_time := 0.0
## How full the bar is, 0-1. Drives the colour and the bob as well as the bar.
var heat := 0.0
var punch_tween: Tween
var glow_tween: Tween
## Owned by this instance so the tint does not write back into the scene's shared
## style box.
var fill_style: StyleBoxFlat


func _ready() -> void:
	var scene_fill := progress_bar.get_theme_stylebox(&"fill")
	if scene_fill is StyleBoxFlat:
		fill_style = scene_fill.duplicate()
		progress_bar.add_theme_stylebox_override(&"fill", fill_style)

	combo_label.hide()

	clock = get_node_or_null(clock_path)
	if clock == null:
		push_warning("Multiplier meter needs a clock node.")
		return

	clock.connect(&"total_multiplier_changed", _on_total_multiplier_changed)
	_on_total_multiplier_changed(
		clock.call(&"positive_multiplier"),
		clock.call(&"max_total_multiplier"),
		clock.call(&"active_bonus_count"),
	)
	coffee_buff = get_node_or_null(coffee_buff_path) as CoffeeBuff
	if coffee_buff != null:
		coffee_buff.buff_state_changed.connect(_on_coffee_buff_state_changed)
		_on_coffee_buff_state_changed(coffee_buff.is_active)
	call_deferred("_sync_glow_size")


func _process(delta: float) -> void:
	# The bob winds up with the multiplier, so a day being burned through looks
	# like it out of the corner of an eye.
	float_time += delta * lerpf(1.0, BOB_SPEED.y / BOB_SPEED.x, heat)
	display.position.y = sin(float_time * BOB_SPEED.x) * lerpf(BOB_PIXELS.x, BOB_PIXELS.y, heat)
	display.rotation = sin(float_time * 1.1) * lerpf(TILT_RADIANS.x, TILT_RADIANS.y, heat)


func _on_total_multiplier_changed(new_multiplier: float, new_cap: float, active_count: int) -> void:
	var previous := multiplier
	multiplier = new_multiplier
	cap = new_cap
	heat = clampf(multiplier / cap, 0.0, 1.0)

	multiplier_label.text = _format_multiplier(multiplier)
	progress_bar.value = heat * 100.0

	var color := COOL_COLOR.lerp(HOT_COLOR, heat)
	multiplier_label.add_theme_color_override(&"font_color", color)
	if fill_style:
		fill_style.bg_color = color

	_update_combo(active_count, color)
	# Only on the way up: a kick as the boss forces everything off would read as a
	# reward for being caught.
	if multiplier > previous:
		_punch()


## Names the bonus for running more than one distraction at once, which is
## otherwise invisible - the number moves, but nothing says why.
func _update_combo(active_count: int, color: Color) -> void:
	var bonus: float = clock.call(&"combo_bonus") if clock else 1.0
	if active_count < 2 or is_equal_approx(bonus, 1.0):
		combo_label.hide()
		return

	combo_label.text = "COMBO x%s" % _format_multiplier(bonus)
	combo_label.add_theme_color_override(&"font_color", color)
	combo_label.show()


func _punch() -> void:
	if punch_tween:
		punch_tween.kill()

	display.scale = Vector2.ONE * PUNCH_SCALE
	punch_tween = create_tween()
	punch_tween.tween_property(display, "scale", Vector2.ONE, PUNCH_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
