class_name DatingCard
extends Control

const SWIPE_ROTATION := 0.12
const SWIPE_FEEDBACK_THRESHOLD := 110.0

@export_group("Profile")
@export var profile_image: Texture2D:
	set(value):
		profile_image = value
		_refresh_profile()
@export var profile_name := "Maya":
	set(value):
		profile_name = value
		_refresh_profile()
@export_range(18, 99, 1) var age := 25:
	set(value):
		age = value
		_refresh_profile()

@onready var picture: TextureRect = %Picture
@onready var picture_placeholder: Control = %PicturePlaceholder
@onready var name_label: Label = %NameLabel
@onready var age_label: Label = %AgeLabel
@onready var like_badge: Label = %LikeBadge
@onready var pass_badge: Label = %PassBadge

var is_animating := false


func _ready() -> void:
	pivot_offset = size * 0.5
	_set_mouse_filter_ignored(self)
	_refresh_profile()


func preview_swipe(offset: Vector2) -> void:
	if is_animating:
		return

	position = offset
	rotation = clampf(offset.x / size.x, -1.0, 1.0) * SWIPE_ROTATION
	_update_swipe_feedback(offset.x)


func reset_swipe() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(like_badge, "modulate:a", 0.0, 0.12)
	tween.tween_property(pass_badge, "modulate:a", 0.0, 0.12)


func animate_swipe(direction: float, finished: Callable) -> void:
	is_animating = true
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:x", position.x + direction * size.x * 1.5, 0.2)
	tween.tween_property(self, "rotation", direction * SWIPE_ROTATION * 2.0, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(finished)


func _update_swipe_feedback(horizontal_offset: float) -> void:
	var strength := clampf(absf(horizontal_offset) / SWIPE_FEEDBACK_THRESHOLD, 0.0, 1.0)
	like_badge.modulate.a = strength if horizontal_offset > 0.0 else 0.0
	pass_badge.modulate.a = strength if horizontal_offset < 0.0 else 0.0


func _refresh_profile() -> void:
	if not is_node_ready():
		return

	picture.texture = profile_image
	picture_placeholder.visible = profile_image == null
	name_label.text = profile_name
	age_label.text = str(age)


func _set_mouse_filter_ignored(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignored(child)
