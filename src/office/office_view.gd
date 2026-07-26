class_name OfficeView
extends Node2D

const FIDGET_SOUND := preload("res://resources/audio/fidget.mp3")
const EMPTY_CUP_TEXTURE := preload("res://resources/images/cup.png")
const FULL_CUP_TEXTURE := preload("res://resources/images/cup-full.png")
const MULTIPLIER_GOLD := Color(0.92941177, 0.79607844, 0.26666668, 1.0)
const REFILL_BROWN := Color(0.78, 0.36, 0.10, 1.0)

## What the spin sound does between a level 1 spin and a level 3 one. The pitch
## range is deliberately narrow - much past this and the loop reads as a
## different object rather than the same one going faster.
const FIDGET_PITCH := Vector2(0.9, 1.35)
const FIDGET_VOLUME_DB := Vector2(-6.0, 0.0)
const FIDGET_SPIN_DOWN_SECONDS := 0.3
## Where the sound fades to on a spin-down. Low enough to be gone, and the
## player is stopped once it lands.
const FIDGET_SILENT_DB := -40.0

@onready var drawer: OfficeDrawer = $Drawer
@onready var fidget: AnimatedSprite2D = $Fidget
@onready var phone: AnimatedSprite2D = $Phone
@onready var cup: Sprite2D = $Cup
@onready var coffee_steam: Array[GPUParticles2D] = [$CoffeeSteamLeft, $CoffeeSteam, $CoffeeSteamRight]

var fidget_slow_down_tween: Tween
var fidget_player: AudioStreamPlayer

func _ready() -> void:
	drawer.progress_changed.connect(_on_drawer_progress_changed)
	drawer.opened.connect(_on_drawer_opened)
	fidget.frame = 0
	phone.frame = 0
	phone.stop()
	phone.hide()
	for steam in coffee_steam:
		steam.emitting = false
	set_coffee_state(false, 1.0, false)
	_on_drawer_progress_changed(drawer.open_progress)

	# The loop runs for as long as the spinner does, so it gets a player of its
	# own rather than one of Sfx's one-shot slots.
	fidget_player = AudioStreamPlayer.new()
	fidget_player.stream = FIDGET_SOUND
	add_child(fidget_player)


func play_fidget_spin(spin_level: int) -> void:
	if fidget_slow_down_tween:
		fidget_slow_down_tween.kill()
		fidget_slow_down_tween = null

	fidget.play()
	fidget.speed_scale = spin_level

	# Faster spins sit a little higher and a little louder.
	var t := _fidget_level_ratio(spin_level)
	fidget_player.pitch_scale = lerpf(FIDGET_PITCH.x, FIDGET_PITCH.y, t)
	fidget_player.volume_db = lerpf(FIDGET_VOLUME_DB.x, FIDGET_VOLUME_DB.y, t)
	if not fidget_player.playing:
		fidget_player.play()


func stop_fidget_spin(forced: bool) -> void:
	if not fidget.is_playing(): return
	if forced:
		fidget.stop()
		fidget_player.stop()
	else:
		# Kept on fidget_slow_down_tween so a new spin can cancel the wind-down
		# and take the sound back up with it.
		fidget_slow_down_tween = create_tween()
		fidget_slow_down_tween.parallel().tween_property(fidget, "speed_scale", 0, FIDGET_SPIN_DOWN_SECONDS)
		fidget_slow_down_tween.parallel().tween_property(fidget_player, "volume_db", FIDGET_SILENT_DB, FIDGET_SPIN_DOWN_SECONDS)
		fidget_slow_down_tween.parallel().tween_property(fidget_player, "pitch_scale", FIDGET_PITCH.x * 0.8, FIDGET_SPIN_DOWN_SECONDS)
		fidget_slow_down_tween.tween_callback(func():
			fidget.stop()
			fidget_player.stop()
		)


## Spin levels run 1-3 (fidget_spinner.gd clamps them), so this maps that onto
## 0-1 for the pitch and volume ramps.
func _fidget_level_ratio(spin_level: int) -> float:
	return clampf((spin_level - 1) / 2.0, 0.0, 1.0)


## The props live here rather than with the scripts that own the rules about them,
## so this is where a rule saying no turns into something the player can see.
func deny_fidget() -> void:
	DeniedFeedback.deny(fidget)

func deny_cup() -> void:
	DeniedFeedback.deny(cup)

func deny_phone() -> void:
	DeniedFeedback.deny(phone)


func highlight_fidget_spin_start(color: Color):
	OutlineHighlight.show_outline(fidget, color)

func highlight_fidget_spin_end():
	OutlineHighlight.hide_outline(fidget)


func set_coffee_state(is_active: bool, fill_amount: float, is_ready: bool) -> void:
	var material := cup.material as ShaderMaterial
	cup.texture = FULL_CUP_TEXTURE if is_ready else EMPTY_CUP_TEXTURE
	for steam in coffee_steam:
		steam.emitting = is_ready
	material.set_shader_parameter(&"fill_amount", fill_amount)

	if is_active:
		material.set_shader_parameter(&"outline_color", MULTIPLIER_GOLD)
		material.set_shader_parameter(&"outline_width", 5.0)
	elif is_ready:
		material.set_shader_parameter(&"outline_color", MULTIPLIER_GOLD)
		material.set_shader_parameter(&"outline_width", 3.0)
	else:
		material.set_shader_parameter(&"outline_color", REFILL_BROWN)
		material.set_shader_parameter(&"outline_width", 3.0 if fill_amount < 1.0 else 0.0)

func _on_drawer_progress_changed(progress: float) -> void:
	if progress <= 0.0:
		phone.hide()
		return

	phone.show()
	var final_frame := phone.sprite_frames.get_frame_count(phone.animation) - 1
	phone.frame = roundi(progress * final_frame)


func _on_drawer_opened() -> void:
	phone.frame = phone.sprite_frames.get_frame_count(phone.animation) - 1
