class_name TodoItem
extends HBoxContainer

@export var text: String = "":
	set(value):
		text = value
		if label:
			label.text = value

@export var checked: bool = false:
	set(value):
		checked = value
		if check_box:
			check_box.button_pressed = value

@onready var check_box: CheckBox = $CheckBox
@onready var label: Label = $Label

func _ready() -> void:
	check_box.button_pressed = checked
	label.text = text
