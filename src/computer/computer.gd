extends Control

@onready var spreadsheet: Control = %Spreadsheet
@onready var video_distraction: Control = %VideoDistraction
@onready var video_runner: Node2D = %VideoRunner
@onready var taskbar: TabContainer = %Taskbar
@onready var close_button: Button = %TitleButtons/CloseButton

func _ready() -> void:
	taskbar.tab_changed.connect(_on_taskbar_tab_changed)
	_on_taskbar_tab_changed(taskbar.current_tab)
	close_button.pressed.connect(hide)

func _on_taskbar_tab_changed(tab: int) -> void:
	if tab == 0:
		spreadsheet.show()
		video_distraction.hide()
		video_runner.call(&"stop")
	else:
		_show_video_distraction()

func _show_video_distraction() -> void:
	spreadsheet.hide()
	video_distraction.show()
	video_runner.call(&"start")
