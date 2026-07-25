extends Camera2D

const ZOOM_IN_ZOOM = Vector2(2.3, 2.3)
const ZOOM_IN_POSITION = Vector2(0, -42)
const OFFSET = Vector2(640.0, 360.0)
const ZOOM_SECONDS = 1.0

func _ready() -> void:
	zoom = ZOOM_IN_ZOOM
	offset = OFFSET + ZOOM_IN_POSITION
	EventBus.zoom_in_requested.connect(zoom_in)
	EventBus.zoom_out_requested.connect(zoom_out)
	
func zoom_in():
	var tween = create_tween()
	tween.parallel().tween_property(self, "zoom", ZOOM_IN_ZOOM, ZOOM_SECONDS)
	tween.parallel().tween_property(self, "offset", OFFSET + ZOOM_IN_POSITION, ZOOM_SECONDS)
	
func zoom_out():
	var tween = create_tween()
	tween.parallel().tween_property(self, "zoom", Vector2.ONE, ZOOM_SECONDS)
	tween.parallel().tween_property(self, "offset", OFFSET, ZOOM_SECONDS)
