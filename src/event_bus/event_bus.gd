extends Node

@warning_ignore("unused_signal")
signal activity_started(source_id: StringName, multiplier: float)
signal activity_ended(source_id: StringName)

signal day_started()
## The clock has dropped under an hour, where it starts to crawl.
signal last_hour_started()
signal day_ended(realtime: float)

signal punishment_started(activity_count: int)
signal punishment_ended()

signal boss_watch_started()
signal boss_watch_ended()
signal boss_watch_progress(progress: float)

signal task_added(task: Task)
signal task_completed(task: Task)
