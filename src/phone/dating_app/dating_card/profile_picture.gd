class_name ProfilePicture extends TextureRect

var bodies: Array[Texture2D] = [preload("res://resources/images/dating/body1.png"), preload("res://resources/images/dating/body2.png")]
var eyes: Array[Texture2D] = [preload("res://resources/images/dating/eyes1.png"), preload("res://resources/images/dating/eyes2.png"), preload("res://resources/images/dating/eyes3.png")]
var hair: Array[Texture2D] = [preload("res://resources/images/dating/hair1.png"), preload("res://resources/images/dating/hair2.png"), preload("res://resources/images/dating/hair3.png")]
var mouths: Array[Texture2D] = [preload("res://resources/images/dating/mouth1.png"), preload("res://resources/images/dating/mouth2.png"), preload("res://resources/images/dating/mouth3.png")]
var noses: Array[Texture2D] = [preload("res://resources/images/dating/nose1.png"), preload("res://resources/images/dating/nose2.png"), preload("res://resources/images/dating/nose3.png"), preload("res://resources/images/dating/nose4.png")]

const SKIN_TONES := [
	Color("F2D3B4"),
	Color("E4B189"),
	Color("C9946A"),
	Color("A16E42"),
	Color("6E4626"),
	Color("3F2517"),
]
const HAIR_COLORS := [
	Color("1F1917"),
	Color("3D2817"),
	Color("6B4423"),
	Color("A67C4E"),
	Color("D4A55A"),
	Color("C9BFA8"),
	Color("A0442B"),
	Color("8A8478"),
	Color("D97298"),
	Color("4A7BB8"),
]
const SHIRT_COLORS := [
	Color("E8E4D8"),
	Color("2A2A2E"),
	Color("4A6D8C"),
	Color("2C3E5A"),
	Color("3A8B92"),
	Color("3D5D3F"),
	Color("6D7040"),
	Color("C99B34"),
	Color("8C3846"),
	Color("D26E5C"),
]

func _ready() -> void:
	self_modulate = SKIN_TONES.pick_random()
	$Body.texture = bodies.pick_random()
	$Body.modulate = SHIRT_COLORS.pick_random()
	$Hair.texture = hair.pick_random()
	$Hair.modulate = HAIR_COLORS.pick_random()
	$Eyes.texture = eyes.pick_random()
	$Nose.texture = noses.pick_random()
	$Mouth.texture = mouths.pick_random()