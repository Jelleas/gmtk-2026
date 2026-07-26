extends Control

signal authenticated

@onready var sign_in_button: Button = %SignInButton
@onready var status_label: Label = %StatusLabel

var is_authenticating := false


func _ready() -> void:
	sign_in_button.pressed.connect(_authenticate)


func _authenticate() -> void:
	if is_authenticating:
		return

	is_authenticating = true
	Sfx.play_click()
	EventBus.zoom_out_requested.emit()
	status_label.text = "Logging on..."
	await get_tree().create_timer(0.2).timeout
	status_label.text = "Welcome back."
	authenticated.emit()
	queue_free()
