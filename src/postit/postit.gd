extends Node2D

const TodoItemScene := preload("res://src/postit/todo_item.tscn")

@export var note_color: Color = Color(1.0, 0.94, 0.42):
	set(value):
		note_color = value
		if background:
			background.color = value

@onready var background: ColorRect = $Background
@onready var todo_list: VBoxContainer = $TodoList

func _ready() -> void:
	background.color = note_color
	
	EventBus.task_added.connect(on_task_added)
	EventBus.task_completed.connect(on_task_completed)
	
func add_item(text: String, checked: bool = false) -> TodoItem:
	var item: TodoItem = TodoItemScene.instantiate()
	todo_list.add_child(item)
	item.text = text
	item.checked = checked
	return item

func set_item_text(index: int, text: String) -> void:
	(todo_list.get_child(index) as TodoItem).text = text

func set_item_checked(index: int, checked: bool) -> void:
	(todo_list.get_child(index) as TodoItem).checked = checked

func clear_items() -> void:
	for child in todo_list.get_children():
		child.queue_free()

func on_task_added(task: Task):
	add_item(task.description)
	
func on_task_completed(task: Task):
	var i = 0
	for todo_item in todo_list.get_children():
		if todo_item.text == task.text:
			set_item_checked(i, true)
			return
		i += 1
