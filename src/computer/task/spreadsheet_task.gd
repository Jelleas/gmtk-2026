@abstract class_name SpreadsheetTask
extends Task

func _init(p_title: String, p_description: String, spreadsheet: Spreadsheet) -> void:
	super._init(p_title, p_description, spreadsheet)
	spreadsheet.cell_text_changed.connect(_on_cell_text_changed)

func get_spreadsheet() -> Spreadsheet:
	return target as Spreadsheet

func _on_cell_text_changed(_row: int, _col: int, _text: String) -> void:
	if check_completed():
		EventBus.task_completed.emit(self)
