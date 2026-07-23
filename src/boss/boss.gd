extends Node2D

enum State { RISING, VISIBLE, RETREATING }

@export var min_move_interval := 1.0
@export var max_move_interval := 3.0
@export var move_duration := 0.5
@export var rise_distance := 256.0
@export var activity_check_delay := 5.0
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

func _ready() -> void:
	EventBus.activity_started.connect(on_activity_start)
	EventBus.activity_ended.connect(on_activity_end)
	EventBus.punishment_ended.connect(on_punishment_ended)
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

func on_activity_start(source_id: StringName, _multiplier: float) -> void:
	activity_states[source_id] = true

func on_activity_end(source_id: StringName) -> void:
	activity_states[source_id] = false

func schedule_next_move() -> void:
	move_timer.start(randf_range(min_move_interval, max_move_interval))

func move_boss_face() -> void:
	if state != State.RISING:
		return

	var tween := create_tween()
	tween.tween_property(boss_face, "position:y", visible_y, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(boss_face_visible)

func boss_face_visible() -> void:
	state = State.VISIBLE
	activity_check_timer.start(activity_check_delay)

func check_active_activities() -> void:
	var activity_weight := 0.0
	for is_active in activity_states.values():
		if is_active:
			activity_weight += 20.0

	has_active_activities = activity_weight > 0.0
	if has_active_activities:
		EventBus.punish.emit(activity_weight)
	else:
		retreat_boss_face()

func on_punishment_ended() -> void:
	if state != State.VISIBLE:
		return

	retreat_boss_face()

func retreat_boss_face() -> void:
	activity_check_timer.stop()
	state = State.RETREATING
	var tween := create_tween()
	tween.tween_property(boss_face, "position:y", hidden_y, retreat_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(on_boss_face_hidden)

func on_boss_face_hidden() -> void:
	state = State.RISING
	has_active_activities = false
	schedule_next_move()
