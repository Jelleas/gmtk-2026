extends Node2D

var task_store: TaskStore

func _ready():
	task_store = TaskStore.new($Screen/Computer.spreadsheet)

	for i in range(2):
		task_store.assign_new_task()
