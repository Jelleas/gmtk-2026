extends Node

## Rims an activity's object in red once the boss has caught the player at it.
## One of these sits in each activity's scene, naming the object it speaks for
## through target_path; the office view owns the actual outline material, since
## the thing being outlined is the desk prop rather than the activity itself.

const CAUGHT_COLOR := Color(1.0, 0.0, 0.0, 1.0)

@export var source_id: StringName
## The sprite to outline, named relative to the scene root (the office) rather
## than to this node: the activities sit at different depths, and the props they
## light up all live together under the office view.
@export var target_path: NodePath

var target: CanvasItem
var is_active := false
var is_noticed := false
var noticed_frame := -1

func _ready() -> void:
	EventBus.activity_started.connect(_on_activity_started)
	EventBus.activity_ended.connect(_on_activity_ended)
	EventBus.punishment_started.connect(_on_punishment_started)
	EventBus.punishment_ended.connect(_on_punishment_ended)

func _on_activity_started(id: StringName, _multiplier: float) -> void:
	if id != source_id:
		return
	is_active = true

func _on_activity_ended(id: StringName) -> void:
	if id != source_id:
		return
	is_active = false
	# An activity can stop itself synchronously as a side effect of being
	# noticed (e.g. video_distraction.gd stops when punishment starts). That
	# cascading end happens in the same frame as the notice and shouldn't clear
	# the "you got caught" outline. A stop in any later frame is a deliberate
	# player action (e.g. putting the phone away) and should clear it.
	var is_self_stop_from_notice := is_noticed and Engine.get_process_frames() == noticed_frame
	if not is_self_stop_from_notice:
		_set_noticed(false)

func _on_punishment_started(_activity_count: int) -> void:
	if not is_active:
		return
	noticed_frame = Engine.get_process_frames()
	_set_noticed(true)

func _on_punishment_ended() -> void:
	_set_noticed(false)

func _set_noticed(noticed: bool) -> void:
	is_noticed = noticed
	if noticed:
		_resolve_target()
		OutlineHighlight.show_outline(target, CAUGHT_COLOR)
	else:
		OutlineHighlight.hide_outline(target)

## Deferred until first use: the props live elsewhere in the tree and are not
## guaranteed to be ready when this node is.
##
## Walks up looking for the first ancestor the path resolves against, rather than
## assuming a particular one is the root. The office is the scene root when run
## on its own but sits under Main in the real game, and the activities themselves
## are instanced at varying depths - so neither owner nor current_scene is
## reliably the node holding the props.
func _resolve_target() -> void:
	if target != null or target_path.is_empty():
		return

	var node := get_parent()
	while node:
		var found := node.get_node_or_null(target_path) as CanvasItem
		if found:
			target = found
			return
		node = node.get_parent()

	push_warning("ActivityOutline (%s): no ancestor resolves '%s'" % [source_id, target_path])
