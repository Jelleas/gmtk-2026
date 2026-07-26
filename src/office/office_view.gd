class_name OfficeView
extends Node2D

@onready var drawer: OfficeDrawer = $Drawer
@onready var fidget: AnimatedSprite2D = $Fidget
@onready var phone: AnimatedSprite2D = $Phone

var fidget_slow_down_tween: Tween

func _ready() -> void:
	drawer.progress_changed.connect(_on_drawer_progress_changed)
	drawer.opened.connect(_on_drawer_opened)
	fidget.frame = 0
	phone.frame = 0
	phone.stop()
	phone.hide()
	_on_drawer_progress_changed(drawer.open_progress)


func play_fidget_spin(spin_level: int) -> void:
	if fidget_slow_down_tween: 
		fidget_slow_down_tween.kill()
		fidget_slow_down_tween = null
		
	fidget.play()
	fidget.speed_scale = spin_level


func stop_fidget_spin(forced: bool) -> void:
	if not fidget.is_playing(): return
	if forced:
		fidget.stop()
	else:
		var tween := create_tween()
		tween.tween_property(fidget, "speed_scale", 0, 0.3)
		tween.tween_callback(func(): fidget.stop())
		
func highlight_fidget_spin_start(color: Color):
	OutlineHighlight.show_outline(fidget, color)

func highlight_fidget_spin_end():
	OutlineHighlight.hide_outline(fidget)

func _on_drawer_progress_changed(progress: float) -> void:
	if progress <= 0.0:
		phone.hide()
		return

	phone.show()
	var final_frame := phone.sprite_frames.get_frame_count(phone.animation) - 1
	phone.frame = roundi(progress * final_frame)


func _on_drawer_opened() -> void:
	phone.frame = phone.sprite_frames.get_frame_count(phone.animation) - 1
