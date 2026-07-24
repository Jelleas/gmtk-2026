class_name OfficeView
extends Node2D

@onready var drawer: OfficeDrawer = $Drawer
@onready var fidget: AnimatedSprite2D = $Fidget
@onready var phone: AnimatedSprite2D = $Phone

func _ready() -> void:
	drawer.progress_changed.connect(_on_drawer_progress_changed)
	drawer.opened.connect(_on_drawer_opened)
	fidget.frame = 0
	phone.frame = 0
	phone.stop()
	phone.hide()
	_on_drawer_progress_changed(drawer.open_progress)


func play_fidget_spin() -> void:
	fidget.play()


func stop_fidget_spin() -> void:
	fidget.stop()
	fidget.frame = 0


func _on_drawer_progress_changed(progress: float) -> void:
	if progress <= 0.0:
		phone.hide()
		return

	phone.show()
	var final_frame := phone.sprite_frames.get_frame_count(phone.animation) - 1
	phone.frame = roundi(progress * final_frame)


func _on_drawer_opened() -> void:
	phone.frame = phone.sprite_frames.get_frame_count(phone.animation) - 1
