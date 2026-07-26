extends Node

@warning_ignore("unused_signal")
signal activity_started(source_id: StringName, bonus: float)
signal activity_ended(source_id: StringName)

## Time effects that accelerate the day without making the player catchable.
signal buff_started(source_id: StringName, multiplier: float)
signal buff_ended(source_id: StringName)

signal day_started()
## The clock has dropped under an hour, where it starts to crawl.
signal last_hour_started()
signal day_ended(realtime: float)

signal punishment_started(activity_count: int)
signal punishment_ended()

signal boss_watch_started()
signal boss_watch_ended()

signal task_added(task: Task)
signal task_completed(task: Task)

## Announced for the stat tracker's benefit, next to the local signals the scene
## itself is wired up with.
@warning_ignore_start("unused_signal")
signal fidget_spun(level: int)
## -1 for a swipe left, 1 for a swipe right.
signal profile_swiped(direction: int)
signal video_coin_collected()
signal video_obstacle_hit()
signal punishment_task_completed()
signal tutorial_beat_completed()
@warning_ignore_restore("unused_signal")
signal zoom_out_requested()
signal zoom_in_requested()
