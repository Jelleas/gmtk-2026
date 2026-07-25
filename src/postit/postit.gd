class_name PostIt
extends Node2D

const TodoItemScene := preload("res://src/postit/todo_item.tscn")

## When true, the post-it subscribes to EventBus task signals itself.
## The PostItStack disables this and drives its child post-its manually.
@export var connect_events: bool = true

@export var note_color: Color = Color("edcb44"):
	set(value):
		note_color = value
		if background:
			background.color = value
		# The checkboxes are drawn in the note's colour, so they follow along.
		if todo_list:
			for todo_item: TodoItem in todo_list.get_children():
				todo_item.box_color = value

@onready var background: ColorRect = $Background
@onready var todo_list: VBoxContainer = $TodoList

func _ready() -> void:
	background.color = note_color

	if connect_events:
		EventBus.task_added.connect(on_task_added)
		EventBus.task_completed.connect(on_task_completed)

func add_item(text: String, checked: bool = false) -> TodoItem:
	var item: TodoItem = TodoItemScene.instantiate()
	todo_list.add_child(item)
	item.text = text
	item.checked = checked
	item.box_color = note_color
	return item

func set_item_text(index: int, text: String) -> void:
	(todo_list.get_child(index) as TodoItem).text = text

func set_item_checked(index: int, checked: bool) -> void:
	(todo_list.get_child(index) as TodoItem).checked = checked

func set_item_pending(index: int, pending: bool) -> void:
	(todo_list.get_child(index) as TodoItem).pending = pending

func clear_items() -> void:
	for child in todo_list.get_children():
		child.queue_free()

func on_task_added(task: Task):
	add_item(task.description)
	
func on_task_completed(task: Task):
	var i = 0
	for todo_item: TodoItem in todo_list.get_children():
		if todo_item.text == task.description and not todo_item.checked:
			set_item_checked(i, true)
			return
		i += 1

func item_count() -> int:
	return todo_list.get_child_count()

func checked_count() -> int:
	var count := 0
	for todo_item: TodoItem in todo_list.get_children():
		if todo_item.checked:
			count += 1
	return count
