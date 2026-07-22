extends Node2D

@onready var spreadsheet: Node2D = $Spreadsheet
@onready var video_distraction: Node2D = $VideoDistraction
@onready var taskbar: TabContainer = $Taskbar

func _ready() -> void:
	taskbar.tab_changed.connect(_on_taskbar_tab_changed)
	_on_taskbar_tab_changed(taskbar.current_tab)

func _on_taskbar_tab_changed(tab: int) -> void:
	if tab == 0:
		spreadsheet.show()
		video_distraction.hide()
		video_distraction.call(&"stop")
	else:
		_show_video_distraction()

func _show_video_distraction() -> void:
	spreadsheet.hide()
	video_distraction.show()
	video_distraction.call(&"start")
