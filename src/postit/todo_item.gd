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
	label.text = text
