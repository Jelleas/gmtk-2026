class_name GoToSpreadsheetTask
extends Task

## A prerequisite the boss hands out before the punishment work: the player has
## to have the spreadsheet in view. The Spreadsheet is a direct child of the
## computer's tab container, so switching tabs toggles its visibility.

func _init(spreadsheet: Spreadsheet) -> void:
	super._init("Go to the spreadsheet", "Go to the spreadsheet", spreadsheet)
	spreadsheet.visibility_changed.connect(notify_changed)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return (target as Spreadsheet).is_visible_in_tree()
