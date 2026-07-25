class_name OpenDrawerTask
extends Task

## Teaches where the phone lives. The drawer has to be dragged open, which is
## the point: the best distraction is the one that leaves the desk a mess.

func _init(drawer: OfficeDrawer) -> void:
	super._init("Pull open the drawer", "Pull open the drawer", drawer)
	drawer.opened.connect(notify_changed)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return (target as OfficeDrawer).is_open
