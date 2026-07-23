extends Control

const CARD_SCENE := preload("res://src/phone/dating_app/dating_card/dating_card.tscn")
const SWIPE_THRESHOLD := 110.0
const STACK_SIZE := 3
const PROFILES := [
	{"name": "Maya", "age": 25},
	{"name": "Noah", "age": 28},
	{"name": "Avery", "age": 24},
	{"name": "Luca", "age": 29},
	{"name": "Jamie", "age": 27},
	{"name": "Rowan", "age": 26},
]

@onready var card_stack: Control = %CardStack

var active_card: DatingCard
var stacked_cards: Array[DatingCard] = []
var profile_index := 0
var drag_start := Vector2.ZERO
var is_dragging := false
var is_resolving_swipe := false

func _ready() -> void:
	_build_stack()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and is_dragging:
		_update_drag(event.position)


func _begin_drag(pointer_position: Vector2) -> void:
	if is_resolving_swipe or active_card == null:
		return
	if not Rect2(card_stack.position, card_stack.size).has_point(pointer_position):
		return

	is_dragging = true
	drag_start = pointer_position


func _update_drag(pointer_position: Vector2) -> void:
	active_card.preview_swipe(pointer_position - drag_start)


func _end_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false
	var horizontal_offset := active_card.position.x
	if absf(horizontal_offset) >= SWIPE_THRESHOLD:
		is_resolving_swipe = true
		active_card.animate_swipe(signf(horizontal_offset), _finish_swipe.bind(active_card))
	else:
		active_card.reset_swipe()


func _finish_swipe(card: DatingCard) -> void:
	stacked_cards.erase(card)
	card.queue_free()
	profile_index = (profile_index + 1) % PROFILES.size()

	for depth in range(stacked_cards.size()):
		_set_stack_pose(stacked_cards[depth], depth, true)

	var new_profile: Dictionary = PROFILES[(profile_index + STACK_SIZE - 1) % PROFILES.size()]
	var new_card := _create_card(new_profile)
	card_stack.add_child(new_card)
	stacked_cards.append(new_card)
	_set_stack_pose(new_card, STACK_SIZE - 1, false)
	active_card = stacked_cards.front()
	is_resolving_swipe = false


func _build_stack() -> void:
	for depth in range(STACK_SIZE - 1, -1, -1):
		var profile: Dictionary = PROFILES[(profile_index + depth) % PROFILES.size()]
		var card := _create_card(profile)
		card_stack.add_child(card)
		_set_stack_pose(card, depth, false)
		stacked_cards.push_front(card)

	active_card = stacked_cards.front()


func _create_card(profile: Dictionary) -> DatingCard:
	var card := CARD_SCENE.instantiate() as DatingCard
	card.profile_name = profile["name"]
	card.age = profile["age"]
	return card


func _set_stack_pose(card: DatingCard, depth: int, animate: bool) -> void:
	var target_position := Vector2(0.0, depth * 12.0)
	var target_scale := Vector2.ONE * (1.0 - depth * 0.04)
	card.z_index = STACK_SIZE - depth
	if not animate:
		card.position = target_position
		card.scale = target_scale
		return

	var tween := create_tween().set_parallel()
	tween.tween_property(card, "position", target_position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", target_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
