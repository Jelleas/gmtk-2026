class_name Computer
extends Control

signal login_authenticated

const DESIGN_SIZE := Vector2(328.0, 257.0)
const OUTER_MARGIN := 5
const TITLE_MARGIN := 4
const TITLE_BUTTON_SIZE := 25
const TITLE_BUTTON_SEPARATION := 3
const TITLE_BUTTON_FONT_SIZE := 16
const TASKBAR_MARGIN := 6
const TASKBAR_BUTTON_HEIGHT := 24
const START_BUTTON_WIDTH := 60
const SPREADSHEET_BUTTON_WIDTH := 104
const VIDEO_BUTTON_WIDTH := 136
const TASKBAR_FONT_SIZE := 16
const CHROME_SCALE := 0.5

var can_activate_activity = true

@onready var spreadsheet: Control = %Spreadsheet
@onready var video_distraction: Control = %VideoDistraction
@onready var video_runner: Node2D = %VideoRunner
@onready var taskbar: TabContainer = %Taskbar
@onready var close_button: Button = %TitleButtons/CloseButton
@onready var computer_margin: MarginContainer = $PanelContainer/MarginContainer
@onready var title_margin: MarginContainer = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer
@onready var title_buttons: HBoxContainer = %TitleButtons
@onready var minimize_button: Button = %TitleButtons/MinimizeButton
@onready var maximize_button: Button = %TitleButtons/MaximizeButton
@onready var taskbar_margin: MarginContainer = $PanelContainer/MarginContainer/VBoxContainer/TaskbarPanel/MarginContainer
@onready var taskbar_buttons: HBoxContainer = %TaskbarButtons
@onready var start_button: Button = %StartButton
@onready var spreadsheet_selector: Button = %SpreadsheetSelector
@onready var video_distraction_selector: Button = %VideoDistractionSelector
@onready var login_screen: Control = $LoginScreen

func _ready() -> void:
	login_screen.connect(&"authenticated", _on_login_authenticated)
	taskbar.tab_changed.connect(_on_taskbar_tab_changed)
	spreadsheet_selector.pressed.connect(_select_task.bind(0))
	video_distraction_selector.pressed.connect(_select_task.bind(1))
	resized.connect(_scale_chrome)
	_scale_chrome()
	_on_taskbar_tab_changed(taskbar.current_tab)
	EventBus.punishment_started.connect(_on_deactivate_activities)
	EventBus.boss_watch_started.connect(_on_deactivate_activities)
	EventBus.punishment_ended.connect(_on_activate_activities)
	EventBus.boss_watch_ended.connect(_on_activate_activities)

	#close_button.pressed.connect(hide)

func _on_login_authenticated() -> void:
	login_authenticated.emit()

func _on_taskbar_tab_changed(tab: int) -> void:
	spreadsheet_selector.set_pressed_no_signal(tab == 0)
	video_distraction_selector.set_pressed_no_signal(tab == 1)
	if tab == 0:
		spreadsheet.show()
		video_distraction.hide()
		video_runner.call(&"stop")
	else:
		_show_video_distraction()


## Brings a tab up as if the player had clicked its taskbar button.
func show_tab(tab: int) -> void:
	if tab == 1 and not can_activate_activity:
		_on_taskbar_tab_changed(taskbar.current_tab)
		return
	taskbar.current_tab = tab
	_on_taskbar_tab_changed(tab)


func _select_task(tab: int) -> void:
	show_tab(tab)


func _show_video_distraction() -> void:
	spreadsheet.hide()
	video_distraction.show()
	video_runner.call(&"start")


func _on_deactivate_activities(_activity_count: int = 0) -> void:
	can_activate_activity = false

func _on_activate_activities() -> void:
	can_activate_activity = true

func _scale_chrome() -> void:
	var scale_factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y) * CHROME_SCALE
	var outer_margin := roundi(OUTER_MARGIN * scale_factor)
	var scaled_title_margin := roundi(TITLE_MARGIN * scale_factor)

	computer_margin.add_theme_constant_override(&"margin_left", outer_margin)
	computer_margin.add_theme_constant_override(&"margin_top", outer_margin)
	computer_margin.add_theme_constant_override(&"margin_right", outer_margin)
	computer_margin.add_theme_constant_override(&"margin_bottom", outer_margin)
	title_margin.add_theme_constant_override(&"margin_left", scaled_title_margin)
	title_margin.add_theme_constant_override(&"margin_top", scaled_title_margin)
	title_margin.add_theme_constant_override(&"margin_right", scaled_title_margin)
	title_margin.add_theme_constant_override(&"margin_bottom", scaled_title_margin)
	title_buttons.add_theme_constant_override(&"separation", roundi(TITLE_BUTTON_SEPARATION * scale_factor))
	taskbar_margin.add_theme_constant_override(&"margin_left", roundi(TASKBAR_MARGIN * scale_factor))
	taskbar_margin.add_theme_constant_override(&"margin_top", roundi(TASKBAR_MARGIN * scale_factor))
	taskbar_margin.add_theme_constant_override(&"margin_right", roundi(TASKBAR_MARGIN * scale_factor))
	taskbar_margin.add_theme_constant_override(&"margin_bottom", roundi(TASKBAR_MARGIN * scale_factor))
	taskbar_buttons.add_theme_constant_override(&"separation", roundi(TITLE_BUTTON_SEPARATION * scale_factor))

	var button_size := Vector2.ONE * roundi(TITLE_BUTTON_SIZE * scale_factor)
	for button in [minimize_button, maximize_button, close_button]:
		button.custom_minimum_size = button_size
		button.add_theme_font_size_override(&"font_size", roundi(TITLE_BUTTON_FONT_SIZE * scale_factor))

	start_button.custom_minimum_size = Vector2(START_BUTTON_WIDTH, TASKBAR_BUTTON_HEIGHT) * scale_factor
	spreadsheet_selector.custom_minimum_size = Vector2(SPREADSHEET_BUTTON_WIDTH, TASKBAR_BUTTON_HEIGHT) * scale_factor
	video_distraction_selector.custom_minimum_size = Vector2(VIDEO_BUTTON_WIDTH, TASKBAR_BUTTON_HEIGHT) * scale_factor
	for button in [start_button, spreadsheet_selector, video_distraction_selector]:
		button.add_theme_font_size_override(&"font_size", roundi(TASKBAR_FONT_SIZE * scale_factor))
