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
		if checkbox_box:
			checkbox_box.checked = value

@onready var checkbox_box: CheckboxBox = $CheckboxBox
@onready var label: Label = $Label

func _ready() -> void:
	checkbox_box.checked = checked
	label.text = text
