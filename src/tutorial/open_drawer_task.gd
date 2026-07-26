class_name OpenDrawerTask
extends Task

## Teaches where the phone lives: the best distraction is the one that leaves
## the desk a mess.

func _init(drawer: OfficeDrawer) -> void:
	super._init("Open the drawer", "Open the drawer", drawer)
	drawer.opened.connect(notify_changed)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return (target as OfficeDrawer).is_open
