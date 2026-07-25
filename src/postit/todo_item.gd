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

## The checkbox is filled with the colour of the note it sits on.
@export var box_color: Color = Color("edcb44"):
	set(value):
		box_color = value
		if checkbox_box:
			checkbox_box.fill_color = value

## Dims the whole item to show it is not the player's turn yet.
const PENDING_ALPHA := 0.35

@export var pending: bool = false:
	set(value):
		pending = value
		modulate.a = PENDING_ALPHA if value else 1.0

@onready var checkbox_box: CheckboxBox = $CheckboxBox
@onready var label: Label = $Label

func _ready() -> void:
	checkbox_box.checked = checked
	checkbox_box.fill_color = box_color
	label.text = text
