extends Node2D

signal total_multiplier_changed(multiplier: float, cap: float, active_count: int)

@onready var clock_viewport: SubViewport = $ClockViewport
@onready var clock_surface: Polygon2D = $ClockSurface

var active_bonuses: Dictionary[StringName, float] = {}
var is_punished := false

## The clock does not move until the day is started, so the tutorial can hold it
## at the opening time until the player has done something worth timing.
var is_running = false

## Under this much left on the clock, the day is on its last hour.
const LAST_HOUR := 3600
## Base 1 + video 2 + spinner 4 + phone 7, times the three-distraction combo bonus.
const MAX_TOTAL_MULTIPLIER := 21.0

## What the distractions are worth together, by how many are running. Distractions
## add rather than multiply: multiplied, a second one would halve the round and a
## third would end it in seconds, which leaves no room to tune between a good run
## and a bad one. The combo bonus is what keeps juggling all three worth the risk
## of being caught with all three.
const COMBO_BONUS: Array[float] = [1.0, 1.0, 1.2, 1.5]

## How long an untouched day takes in real time. Every distraction's bonus is
## derived from this: a round lasts IDLE_DAY_SECONDS / average multiplier.
const IDLE_DAY_SECONDS := 1800.0
## The day drags towards home time, but never slower than this share of full
## speed. Unfloored the curve bottoms out near 0.02 and the last hour alone eats
## over half the round.
const MIN_DRAG := 0.15
## Scales the drag curve so an untouched day comes out at IDLE_DAY_SECONDS.
## tools/balance_sim.gd measures it - re-run that after touching MIN_DRAG.
const DRAG_SCALE := 0.86

## What the clock face does once the day is on its last hour, which is a quarter
## of the round and wants to read as a moment rather than a stall.
const LAST_HOUR_TINT := Color(1.0, 0.45, 0.4, 1.0)
const LAST_HOUR_PULSE_SECONDS := 0.9

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
	EventBus.last_hour_started.connect(on_last_hour_start)

	%TimeLabel.text = format_time(time)
	_update_multiplier_display()

func _process(delta: float) -> void:
	if not is_running:
		return
	
	realtime += delta
	# The clock stands still while the boss has the player doing punishment work.
	if is_punished:
		StatTracker.record_punished_tick(delta)
		return

	# The tracker is handed the multiplier the clock is actually spending, so the
	# stats cannot drift away from the day the player watched go by.
	var multiplier := positive_multiplier()
	StatTracker.record_tick(delta, multiplier)
	time -= delta * 60 * multiplier * negative_multiplier()

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

func on_activity_start(source_id: StringName, bonus: float) -> void:
	active_bonuses[source_id] = bonus
	_update_multiplier_display()

func on_activity_end(source_id: StringName) -> void:
	active_bonuses.erase(source_id)
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
	var total := 1.0
	for bonus in active_bonuses.values():
		if bonus > 0.0:
			total += bonus
	return total * combo_bonus()

## How many distractions are really running. A punishment cuts one off by zeroing
## its bonus rather than ending it, and one worth nothing is not part of a combo.
func active_bonus_count() -> int:
	var active := 0
	for bonus in active_bonuses.values():
		if bonus > 0.0:
			active += 1
	return active

func combo_bonus() -> float:
	return COMBO_BONUS[mini(active_bonus_count(), COMBO_BONUS.size() - 1)]

func max_total_multiplier() -> float:
	return MAX_TOTAL_MULTIPLIER

func negative_multiplier() -> float:
	var hours = 8 - (time / 3600)
	return DRAG_SCALE * maxf(MIN_DRAG, 1 / exp(hours / (10 - hours)))

func _update_multiplier_display() -> void:
	total_multiplier_changed.emit(positive_multiplier(), MAX_TOTAL_MULTIPLIER, active_bonus_count())

## Home time is close enough to see. The face keeps pulsing for the rest of the
## day - this is the stretch the drag curve makes a quarter of the round, so it
## should look like it was meant.
func on_last_hour_start() -> void:
	var pulse := create_tween().set_loops()
	pulse.tween_property(clock_surface, "modulate", LAST_HOUR_TINT, LAST_HOUR_PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE)
	pulse.tween_property(clock_surface, "modulate", Color.WHITE, LAST_HOUR_PULSE_SECONDS) \
		.set_trans(Tween.TRANS_SINE)
