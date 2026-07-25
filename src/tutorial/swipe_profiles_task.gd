class_name SwipeProfilesTask
extends Task

## Teaches that a distraction has an inside: every swipe stacks another
## multiplier on the clock, and it decays again if the player stops. Ten swipes
## is enough for the ramp to be felt.

const REQUIRED_SWIPES := 5

var swipes := 0

func _init(dating_app: DatingApp) -> void:
	super._init(
		"Swipe %d your phone times" % [REQUIRED_SWIPES],
		"Swipe %d your phone times" % [REQUIRED_SWIPES],
		dating_app,
	)
	dating_app.profile_swiped.connect(_on_profile_swiped)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return swipes >= REQUIRED_SWIPES

## The note carries the count, so the player can watch the ramp add up.
func progress_description() -> String:
	if check_completed():
		return description
	return "%s (%d/%d)" % [description, swipes, REQUIRED_SWIPES]

func _on_profile_swiped() -> void:
	swipes += 1
	notify_changed()
