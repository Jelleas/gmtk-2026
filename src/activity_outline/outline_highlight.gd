class_name OutlineHighlight
extends RefCounted

## Turns the outline shader on and off for a sprite. The material is shared as a
## resource, so each sprite gets its own copy the first time it lights up -
## otherwise every outlined prop would change colour together.

const OUTLINE_MATERIAL: ShaderMaterial = preload("res://resources/shaders/outline_material.tres")
const OUTLINE_WIDTH := 3.0

static func show_outline(target: CanvasItem, color: Color, width := OUTLINE_WIDTH) -> void:
	if target == null:
		return

	var material := _own_material(target)
	material.set_shader_parameter(&"outline_color", color)
	material.set_shader_parameter(&"outline_width", width)

static func hide_outline(target: CanvasItem) -> void:
	if target == null or target.material == null:
		return

	(target.material as ShaderMaterial).set_shader_parameter(&"outline_width", 0.0)

## Gives the target a private copy of the outline material, keeping whatever
## copy it already has so repeat calls don't reset it.
static func _own_material(target: CanvasItem) -> ShaderMaterial:
	if target.material == null:
		target.material = OUTLINE_MATERIAL.duplicate()
	elif target.material == OUTLINE_MATERIAL:
		target.material = target.material.duplicate()
	return target.material as ShaderMaterial
