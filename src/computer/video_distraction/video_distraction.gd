extends Node2D

const SOURCE_ID := &"video_distraction"
const DESIGN_SIZE := Vector2(1270.0, 642.0)
const CENTER_LANE := 1

var time_multiplier := 10.0

@export var lane_width := 120.0
@export var lane_change_interval := 0.8
@export var lane_move_duration := 0.25

@onready var skateboarder: Sprite2D = $Skateboarder
@onready var speed_trail: GPUParticles2D = $Skateboarder/SpeedTrail
@onready var lane_timer: Timer = $LaneTimer
@onready var content_area: Control = get_parent() as Control

var is_running := false
var is_punishment_active := false
var lane_index := CENTER_LANE
var center_position := Vector2.ZERO
var lane_tween: Tween

func _ready() -> void:
	EventBus.punish.connect(_on_punish)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	content_area.resized.connect(_resize_to_content_area)
	_resize_to_content_area()

func _resize_to_content_area() -> void:
	position = content_area.size / 2.0
	var scale_factor := minf(
		content_area.size.x / DESIGN_SIZE.x,
		content_area.size.y / DESIGN_SIZE.y,
	)
	scale = Vector2.ONE * scale_factor

func start() -> void:
	if is_running or is_punishment_active:
		return

	is_running = true
	speed_trail.emitting = true
	lane_timer.start(lane_change_interval)
	EventBus.activity_started.emit(SOURCE_ID, time_multiplier)

func stop() -> void:
	if not is_running:
		return

	is_running = false
	speed_trail.emitting = false
	lane_timer.stop()
	if lane_tween:
		lane_tween.kill()
	EventBus.activity_ended.emit(SOURCE_ID)

func _on_lane_timer_timeout() -> void:
	if not is_running:
		return

	if lane_index == 0:
		lane_index = 1
	elif lane_index == 2:
		lane_index = 1
	elif randi() % 2 == 0:
		lane_index = 0
	else:
		lane_index = 2

	var target_position := center_position
	target_position.x += (lane_index - CENTER_LANE) * lane_width
	if lane_tween:
		lane_tween.kill()
	lane_tween = create_tween()
	lane_tween.tween_property(skateboarder, "position", target_position, lane_move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	lane_timer.start(lane_change_interval)

func _on_punish(_weight: float) -> void:
	is_punishment_active = true

func _on_punishment_ended() -> void:
	is_punishment_active = false
