class_name ProfilePortrait
extends Control

enum HairStyle { SHORT, LONG, CURLY, BUZZ }

const SKIN_TONES := [
	Color("f7c9a8"),
	Color("db9b72"),
	Color("a86648"),
	Color("70432f"),
]
const HAIR_COLORS := [
	Color("2d1b20"),
	Color("5a3425"),
	Color("9b5d32"),
	Color("d7a24b"),
	Color("542b4c"),
]
const SHIRT_COLORS := [
	Color("5f4b8b"),
	Color("3f7881"),
	Color("c06571"),
	Color("476395"),
]

@export var randomize_features := true
@export var hair_style: HairStyle = HairStyle.SHORT
@export var has_glasses := false
@export var masculine_features := false

var skin_color := SKIN_TONES[0]
var hair_color := HAIR_COLORS[0]
var shirt_color := SHIRT_COLORS[0]


func _ready() -> void:
	if randomize_features:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		masculine_features = rng.randf() < 0.5
		if masculine_features:
			hair_style = [HairStyle.SHORT, HairStyle.CURLY, HairStyle.BUZZ][rng.randi_range(0, 2)] as HairStyle
		else:
			hair_style = rng.randi_range(HairStyle.SHORT, HairStyle.CURLY) as HairStyle
		has_glasses = rng.randf() < 0.4
		skin_color = SKIN_TONES[rng.randi_range(0, SKIN_TONES.size() - 1)]
		hair_color = HAIR_COLORS[rng.randi_range(0, HAIR_COLORS.size() - 1)]
		shirt_color = SHIRT_COLORS[rng.randi_range(0, SHIRT_COLORS.size() - 1)]
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var portrait_scale := minf(size.x / 320.0, size.y / 456.0)
	var face_center := Vector2(size.x * 0.5, size.y * 0.43)
	var face_radius := 69.0 * portrait_scale
	var hair_radius := 82.0 * portrait_scale
	var eye_y := face_center.y - 9.0 * portrait_scale

	if hair_style == HairStyle.LONG:
		draw_circle(Vector2(face_center.x, face_center.y + 10.0 * portrait_scale), hair_radius, hair_color)
		draw_rect(Rect2(face_center.x - hair_radius, face_center.y + 8.0 * portrait_scale, hair_radius * 2.0, 122.0 * portrait_scale), hair_color)
	elif hair_style == HairStyle.CURLY:
		for offset in [Vector2(-52, -39), Vector2(0, -53), Vector2(52, -39), Vector2(-69, 4), Vector2(69, 4)]:
			draw_circle(face_center + offset * portrait_scale, 34.0 * portrait_scale, hair_color)
	elif hair_style == HairStyle.BUZZ:
		draw_circle(Vector2(face_center.x, face_center.y - 22.0 * portrait_scale), 73.0 * portrait_scale, hair_color)
	else:
		draw_circle(Vector2(face_center.x, face_center.y - 8.0 * portrait_scale), hair_radius, hair_color)

	# Keep the face above every hair layer so each portrait remains clear at a glance.
	if hair_style == HairStyle.SHORT:
		draw_circle(Vector2(face_center.x, face_center.y - 54.0 * portrait_scale), 67.0 * portrait_scale, hair_color)
		draw_rect(Rect2(face_center.x - 68.0 * portrait_scale, face_center.y - 54.0 * portrait_scale, 136.0 * portrait_scale, 35.0 * portrait_scale), hair_color)
	elif hair_style == HairStyle.LONG:
		draw_arc(face_center, 73.0 * portrait_scale, PI, TAU, 24, hair_color, 20.0 * portrait_scale, true)

	# Draw the body after hair so long styles stay behind the neck and shoulders.
	var shoulder_radius := 122.0 if masculine_features else 104.0
	draw_circle(Vector2(face_center.x, face_center.y + 149.0 * portrait_scale), shoulder_radius * portrait_scale, shirt_color)
	draw_rect(Rect2(face_center.x - shoulder_radius * portrait_scale, face_center.y + 149.0 * portrait_scale, shoulder_radius * 2.0 * portrait_scale, 100.0 * portrait_scale), shirt_color)
	draw_rect(Rect2(face_center.x - 19.0 * portrait_scale, face_center.y + 49.0 * portrait_scale, 38.0 * portrait_scale, 58.0 * portrait_scale), skin_color)

	draw_circle(face_center + Vector2(-face_radius * 0.92, 2.0 * portrait_scale), 13.0 * portrait_scale, skin_color)
	draw_circle(face_center + Vector2(face_radius * 0.92, 2.0 * portrait_scale), 13.0 * portrait_scale, skin_color)
	draw_circle(face_center, face_radius, skin_color)

	for eye_x in [-27.0, 27.0]:
		draw_line(
			Vector2(face_center.x + (eye_x - 11.0) * portrait_scale, eye_y - 20.0 * portrait_scale),
			Vector2(face_center.x + (eye_x + 11.0) * portrait_scale, eye_y - 22.0 * portrait_scale),
			hair_color,
			3.0 * portrait_scale,
		)
		draw_circle(Vector2(face_center.x + eye_x * portrait_scale, eye_y), 6.0 * portrait_scale, Color("2b2023"))

	draw_arc(
		Vector2(face_center.x, face_center.y + 25.0 * portrait_scale),
		17.0 * portrait_scale,
		0.15,
		PI - 0.15,
		16,
		Color("9b4e58"),
		3.5 * portrait_scale,
		true,
	)

	if has_glasses:
		_draw_glasses(face_center, eye_y, portrait_scale)


func _draw_glasses(face_center: Vector2, eye_y: float, portrait_scale: float) -> void:
	var glasses_color := Color("352f38")
	for eye_x in [-27.0, 27.0]:
		draw_arc(
			Vector2(face_center.x + eye_x * portrait_scale, eye_y),
			16.0 * portrait_scale,
			0.0,
			TAU,
			20,
			glasses_color,
			3.0 * portrait_scale,
			true,
		)
	draw_line(
		Vector2(face_center.x - 11.0 * portrait_scale, eye_y),
		Vector2(face_center.x + 11.0 * portrait_scale, eye_y),
		glasses_color,
		3.0 * portrait_scale,
	)
