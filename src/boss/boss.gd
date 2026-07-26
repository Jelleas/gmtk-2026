class_name Boss
extends Node2D

enum State { RISING, VISIBLE, RETREATING }

## The tutorial keeps the boss away for its first beat, so it activates the boss
## itself once the player has been told there is one.
@export var auto_activate := true

@export var min_move_interval := 5.0
@export var max_move_interval := 20.0
@export var move_duration := 0.5
@export var rise_distance := 256.0
@export var activity_check_delay := 4.0
@export var retreat_duration := 0.5

@onready var boss_face: Sprite2D = $BossFace

var activity_states: Dictionary[StringName, bool] = {}
var state := State.RISING
var has_active_activities := false
var is_activated := false
var move_timer: Timer
var activity_check_timer: Timer
var hidden_y := 0.0
var visible_y := 0.0
var becoming_red_tween: Tween
## How long the watch on the rise currently underway runs for, so the face has
## the length actually being counted down to redden over.
var current_watch_delay := 0.0
## True while the pending rise was asked for by rise_in(): its delay is a promise
## to whoever scripted it, so a change of pace must not reschedule it away.
var scripted_rise_pending := false
## Set just before a rise to shorten that one look; cleared as it is used.
var next_watch_delay := 0.0

func _ready() -> void:
	EventBus.activity_started.connect(on_activity_start)
	EventBus.activity_ended.connect(on_activity_end)
	EventBus.punishment_ended.connect(on_punishment_ended)
	if auto_activate:
		activate()

func activate() -> void:
	if is_activated:
		return

	is_activated = true
	hidden_y = boss_face.position.y
	visible_y = hidden_y - rise_distance

	move_timer = Timer.new()
	move_timer.one_shot = true
	move_timer.timeout.connect(move_boss_face)
	add_child(move_timer)

	activity_check_timer = Timer.new()
	activity_check_timer.one_shot = true
	activity_check_timer.timeout.connect(check_active_activities)
	add_child(activity_check_timer)

	if is_zero_approx(rise_distance):
		boss_face_visible()
		return

	schedule_next_move()

## Sends the boss home for good. Once the day is over there is nothing left to
## catch, and a last peek would start a punishment behind the shift report.
func deactivate() -> void:
	if not is_activated:
		return

	is_activated = false
	scripted_rise_pending = false
	move_timer.stop()
	if state == State.VISIBLE:
		retreat_boss_face()
	else:
		activity_check_timer.stop()

func on_activity_start(source_id: StringName, _bonus: float) -> void:
	activity_states[source_id] = true

func on_activity_end(source_id: StringName) -> void:
	activity_states[source_id] = false
	if becoming_red_tween && activity_states.values().all(func(b): return not b):
		becoming_red_tween.kill()
		becoming_red_tween = null
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func schedule_next_move() -> void:
	if scripted_rise_pending or not is_activated:
		return

	move_timer.start(randf_range(min_move_interval, max_move_interval))

## Brings the next rise forward to a fixed delay instead of the random interval,
## and holds it there: schedule_next_move() leaves it alone until it goes off.
## The tutorial uses this to put a deadline on a lesson - the boss turns up in
## answer to something the player just did, at a moment they can count on.
func rise_in(delay: float) -> void:
	if not is_activated:
		activate()
	if state != State.RISING:
		return

	scripted_rise_pending = true
	move_timer.start(delay)

## Cuts a pending rise short and comes up now, for a single look of the given
## length. Does nothing once the boss is on its way up or already watching - that
## look is running on its own terms and is not to be interrupted.
func appear_now(watch_duration: float) -> void:
	if not is_activated:
		activate()
	if state != State.RISING or move_timer.is_stopped():
		return

	move_timer.stop()
	next_watch_delay = watch_duration
	move_boss_face()

func move_boss_face() -> void:
	if state != State.RISING:
		return

	scripted_rise_pending = false
	position.x = randf_range(200, 1080)
	var tween := create_tween()
	tween.tween_property(boss_face, "position:y", visible_y, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(boss_face_visible)

func boss_face_visible() -> void:
	state = State.VISIBLE
	current_watch_delay = next_watch_delay if next_watch_delay > 0.0 else activity_check_delay
	next_watch_delay = 0.0
	activity_check_timer.start(current_watch_delay)
	Sfx.play_random(Sfx.BOSS_INVESTIGATE)
	EventBus.boss_watch_started.emit()
	if activity_states.values().any(func(b): return b):
		becoming_red_tween = create_tween()
		becoming_red_tween.tween_property(self, "modulate", Color("#D14B3E"), current_watch_delay)

func check_active_activities() -> void:
	var activity_count := 0
	for is_active in activity_states.values():
		if is_active:
			activity_count += 1

	has_active_activities = activity_count > 0
	if has_active_activities:
		Sfx.play_random(Sfx.BOSS_ANGRY)
		EventBus.punishment_started.emit(activity_count)
		shake()
	else:
		retreat_boss_face()

func on_punishment_ended() -> void:
	if state != State.VISIBLE:
		return

	retreat_boss_face()

func retreat_boss_face() -> void:
	activity_check_timer.stop()
	EventBus.boss_watch_ended.emit()
	state = State.RETREATING
	var tween := create_tween()
	tween.tween_property(boss_face, "position:y", hidden_y, retreat_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(on_boss_face_hidden)

func on_boss_face_hidden() -> void:
	state = State.RISING
	has_active_activities = false
	schedule_next_move()

func shake() -> void:
	var original := position
	var elapsed := 0.0
	var duration = 1.0
	var strength = 20.0
	while elapsed < duration:
		var t: float = 1.0 - (elapsed / duration)  # decay so it settles instead of cutting
		position = original + Vector2(
			randf_range(-strength, strength), 
			randf_range(-strength, strength)
		) * t
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	position = original
