extends Node

## Keeps score of a run. Everything it needs is already announced on the
## [EventBus], so it sits off to the side and listens rather than being wired
## into the scene - the one exception is the clock, which hands it a tick per
## frame so the time figures come from the same numbers the clock spends.
##
## It is an autoload so the stats outlive the office scene, which is what a
## post-game screen needs.

## The day is over and the stats are final.
signal run_finished(stats: GameStats)

var stats := GameStats.new()

## Which activities are running right now. The bus alone cannot answer this:
## activity_started is re-emitted for an activity that is already going.
var active_sources: Dictionary[StringName, bool] = {}

func _ready() -> void:
	EventBus.day_ended.connect(_on_day_ended)
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.boss_watch_started.connect(_on_boss_watch_started)
	EventBus.fidget_spun.connect(_on_fidget_spun)
	EventBus.profile_swiped.connect(_on_profile_swiped)
	EventBus.video_coin_collected.connect(_on_video_coin_collected)
	EventBus.video_obstacle_hit.connect(_on_video_obstacle_hit)
	EventBus.punishment_task_completed.connect(_on_punishment_task_completed)
	EventBus.tutorial_beat_completed.connect(_on_tutorial_beat_completed)

## Called by the office when it starts a run. It cannot hang off day_started:
## the tutorial holds the day until the player's first spin, and that spin
## counts.
func reset() -> void:
	stats = GameStats.new()
	active_sources.clear()

# --- Per-frame, from the clock ----------------------------------------------

func record_tick(delta: float, multiplier: float) -> void:
	stats.real_seconds += delta
	stats.multiplier_seconds += delta * multiplier
	stats.peak_multiplier = maxf(stats.peak_multiplier, multiplier)

	for source_id in active_sources:
		if active_sources[source_id]:
			stats.active_seconds[source_id] = stats.get_active_seconds(source_id) + delta

## The clock stands still during punishment, so nothing is being saved and no
## activity is really running - the time still counts as time spent playing.
func record_punished_tick(delta: float) -> void:
	stats.real_seconds += delta
	stats.multiplier_seconds += delta
	stats.punished_seconds += delta

# --- Bus --------------------------------------------------------------------

func _on_day_ended(_realtime: float) -> void:
	stats.finished = true
	run_finished.emit(stats)

## Only a stopped activity starting again counts: the phone re-emits this on
## every swipe, the spinner on every click that winds it up further, and the
## video with a multiplier of 0.0 when a punishment cuts it off.
func _on_activity_started(source_id: StringName, _multiplier: float) -> void:
	if active_sources.get(source_id, false):
		return

	active_sources[source_id] = true
	stats.activations[source_id] = stats.get_activations(source_id) + 1

func _on_activity_ended(source_id: StringName) -> void:
	active_sources[source_id] = false

func _on_boss_watch_started() -> void:
	stats.boss_peeks += 1

## Being caught is the punishment, not the look: the boss ends its watch either
## way.
func _on_punishment_started(_activity_count: int) -> void:
	stats.times_caught += 1

func _on_fidget_spun(_level: int) -> void:
	stats.fidget_clicks += 1

func _on_profile_swiped(direction: int) -> void:
	if direction < 0:
		stats.swipes_left += 1
	else:
		stats.swipes_right += 1

func _on_video_coin_collected() -> void:
	stats.video_coins += 1

func _on_video_obstacle_hit() -> void:
	stats.video_hits += 1

func _on_punishment_task_completed() -> void:
	stats.punishment_tasks_completed += 1

func _on_tutorial_beat_completed() -> void:
	stats.tutorial_beats_completed += 1
