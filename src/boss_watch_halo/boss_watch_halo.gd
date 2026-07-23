extends Node2D

const RING_COUNT := 4
const BASE_LINE_WIDTH := 3.0
const BASE_GROW_STEP := 6.0
const NOTICED_LINE_WIDTH := 10.0
const PULSE_SPEED := 6.0
const PULSE_AMOUNT := 0.15

@export var source_id: StringName
@export var target_size := Vector2(200, 200)
@export var target_offset := Vector2.ZERO

var is_active := false
var progress := 0.0
var is_noticed := false
var noticed_frame := -1

func _ready() -> void:
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)
	EventBus.boss_watch_progress.connect(_on_boss_watch_progress)
	EventBus.punish.connect(_on_punish)
	EventBus.punishment_ended.connect(_on_punishment_ended)

func _process(_delta: float) -> void:
	if is_noticed:
		queue_redraw()

func _on_activity_started(id: StringName, _multiplier: float) -> void:
	if id != source_id:
		return
	is_active = true
	queue_redraw()

func _on_activity_ended(id: StringName) -> void:
	if id != source_id:
		return
	is_active = false
	# An activity can stop itself synchronously as a side effect of being
	# noticed (e.g. video_distraction.gd stops on punish). That cascading
	# end happens in the same frame as the notice and shouldn't hide the
	# "you got caught" indicator. A stop in any later frame is a deliberate
	# player action (e.g. putting the phone away) and should clear it.
	var is_self_stop_from_notice := is_noticed and Engine.get_process_frames() == noticed_frame
	if not is_self_stop_from_notice:
		is_noticed = false
		progress = 0.0
	queue_redraw()

func _on_boss_watch_progress(value: float) -> void:
	progress = value
	queue_redraw()

func _on_punish(_weight: float) -> void:
	if not is_active:
		return
	is_noticed = true
	noticed_frame = Engine.get_process_frames()
	queue_redraw()

func _on_punishment_ended() -> void:
	is_noticed = false
	progress = 0.0
	queue_redraw()

func _draw() -> void:
	if not is_active and not is_noticed:
		return

	var rect := Rect2(target_offset, target_size)

	if is_noticed:
		var pulse := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED) * PULSE_AMOUNT
		draw_rect(rect.grow(BASE_GROW_STEP), Color(1.0, 0.0, 0.0, 1.0), false, NOTICED_LINE_WIDTH * pulse)
		return

	for ring in range(RING_COUNT):
		var ring_progress := clampf(progress * RING_COUNT - ring, 0.0, 1.0)
		if ring_progress <= 0.0:
			continue
		var alpha := lerpf(0.0, 0.55, ring_progress) * (1.0 - float(ring) / RING_COUNT * 0.5)
		var grow := BASE_GROW_STEP * (ring + 1) * ring_progress
		draw_rect(rect.grow(grow), Color(1.0, 0.0, 0.0, alpha), false, BASE_LINE_WIDTH)
