extends Node2D

const SOURCE_ID := &"video_distraction"
const DESIGN_SIZE := Vector2(1270.0, 642.0)
const PLAYFIELD := Rect2(-DESIGN_SIZE * 0.5, DESIGN_SIZE)
const VIDEO_AREA := Rect2(Vector2(-330.0, -DESIGN_SIZE.y * 0.5), Vector2(660.0, DESIGN_SIZE.y))
const PLAYER_SIZE := Vector2(64.0, 52.0)
const PLAYER_Y := 240.0
const LANE_X := [-180.0, 0.0, 180.0]

var time_multiplier := 10.0

@export var player_speed := 760.0
@export var spawn_interval := 0.7
@export var obstacle_speed := 420.0

@onready var content_area: Control = get_parent() as Control

var is_running := false
var is_punishment_active := false
var player_position := Vector2(LANE_X[1], PLAYER_Y)
var items: Array[Dictionary] = []
var spawn_elapsed := 0.0
var coins_collected := 0
var hits := 0
var hit_flash := 0.0
var player_lane := 1


func _ready() -> void:
	EventBus.punish.connect(_on_punish)
	EventBus.punishment_ended.connect(_on_punishment_ended)
	content_area.resized.connect(_resize_to_content_area)
	_resize_to_content_area()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_running:
		return

	player_lane = _choose_target_lane()
	player_position.x = clampf(
		move_toward(player_position.x, LANE_X[player_lane], player_speed * delta),
		PLAYFIELD.position.x + PLAYER_SIZE.x * 0.5,
		PLAYFIELD.end.x - PLAYER_SIZE.x * 0.5,
	)

	spawn_elapsed += delta
	if spawn_elapsed >= spawn_interval:
		spawn_elapsed = 0.0
		_spawn_item()

	var player_rect := _player_rect()
	for index in range(items.size() - 1, -1, -1):
		var item := items[index]
		var item_rect: Rect2 = item["rect"]
		item_rect.position.y += obstacle_speed * delta
		item["rect"] = item_rect

		if item_rect.intersects(player_rect):
			if item["type"] == &"coin":
				coins_collected += 1
			else:
				hits += 1
				hit_flash = 0.18
			items.remove_at(index)
		elif item_rect.position.y > PLAYFIELD.end.y:
			items.remove_at(index)

	hit_flash = maxf(0.0, hit_flash - delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(PLAYFIELD, Color("080b12"))
	draw_rect(VIDEO_AREA, Color("192438"))
	draw_rect(VIDEO_AREA, Color("8ba4c7"), false, 6.0)
	for x in [-90.0, 90.0]:
		for y in range(-310, 320, 110):
			draw_rect(Rect2(x - 8.0, y, 16.0, 58.0), Color("4d6381"))

	for item in items:
		var item_rect: Rect2 = item["rect"]
		if item["type"] == &"coin":
			draw_rect(item_rect, Color("ffd85a"))
			draw_rect(item_rect.grow(-7.0), Color("fff1a6"))
		else:
			draw_rect(item_rect, Color("d7564e"))
			draw_rect(item_rect.grow(-6.0), Color("8e2f35"))

	var player_color := Color("ff8c52") if hit_flash <= 0.0 else Color("fff4f0")
	var player_rect := _player_rect()
	draw_rect(player_rect, player_color)
	draw_rect(Rect2(player_rect.position + Vector2(14.0, -22.0), Vector2(36.0, 22.0)), Color("ffd0a8"))
	draw_rect(Rect2(player_rect.position + Vector2(8.0, player_rect.size.y - 8.0), Vector2(48.0, 12.0)), Color("4e75b8"))

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(VIDEO_AREA.position.x + 28.0, VIDEO_AREA.position.y + 48.0), "AUTO-RUN VIDEO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color.WHITE)
	draw_string(font, Vector2(VIDEO_AREA.position.x + 28.0, VIDEO_AREA.position.y + 78.0), "Blocks are bad. Coins are good.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("b9cce8"))
	draw_string(font, Vector2(VIDEO_AREA.end.x - 190.0, VIDEO_AREA.position.y + 48.0), "COINS: %d" % coins_collected, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("ffd85a"))
	draw_string(font, Vector2(VIDEO_AREA.end.x - 190.0, VIDEO_AREA.position.y + 76.0), "HITS: %d" % hits, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("ff9c96"))


func start() -> void:
	if is_running or is_punishment_active:
		return

	is_running = true
	player_lane = 1
	player_position = Vector2(LANE_X[player_lane], PLAYER_Y)
	items.clear()
	spawn_elapsed = spawn_interval * 0.5
	coins_collected = 0
	hits = 0
	hit_flash = 0.0
	EventBus.activity_started.emit(SOURCE_ID, time_multiplier)
	queue_redraw()


func stop() -> void:
	if not is_running:
		return

	is_running = false
	EventBus.activity_ended.emit(SOURCE_ID)
	queue_redraw()


func _spawn_item() -> void:
	var is_coin := randf() < 0.35
	var size := Vector2(34.0, 34.0) if is_coin else Vector2(randf_range(54.0, 100.0), randf_range(34.0, 66.0))
	var lane := randi_range(0, LANE_X.size() - 1)
	items.append({
		"rect": Rect2(Vector2(LANE_X[lane] - size.x * 0.5, VIDEO_AREA.position.y - size.y), size),
		"lane": lane,
		"type": &"coin" if is_coin else &"obstacle",
	})


func _player_rect() -> Rect2:
	return Rect2(player_position - PLAYER_SIZE * 0.5, PLAYER_SIZE)


func _choose_target_lane() -> int:
	var player_rect := _player_rect()
	var blocked_lanes := [false, false, false]
	var closest_coin: Dictionary = {}
	var closest_coin_distance := INF

	for item in items:
		var item_rect: Rect2 = item["rect"]
		var distance_to_player := player_rect.position.y - item_rect.end.y
		if distance_to_player < -PLAYER_SIZE.y or distance_to_player > 360.0:
			continue

		if item["type"] == &"obstacle":
			blocked_lanes[item["lane"]] = true
		elif item["type"] == &"coin" and distance_to_player < closest_coin_distance:
			closest_coin = item
			closest_coin_distance = distance_to_player

	if blocked_lanes[player_lane]:
		for lane_offset in [1, -1, 2]:
			var lane: int = player_lane + int(lane_offset)
			if lane < 0:
				lane += LANE_X.size()
			elif lane >= LANE_X.size():
				lane -= LANE_X.size()
			if not blocked_lanes[lane]:
				return lane

	if not closest_coin.is_empty() and not blocked_lanes[closest_coin["lane"]]:
		return closest_coin["lane"]

	return player_lane


func _resize_to_content_area() -> void:
	position = content_area.size * 0.5
	var scale_factor := minf(
		content_area.size.x / DESIGN_SIZE.x,
		content_area.size.y / DESIGN_SIZE.y,
	)
	scale = Vector2.ONE * scale_factor


func _on_punish(_weight: float) -> void:
	is_punishment_active = true
	stop()


func _on_punishment_ended() -> void:
	is_punishment_active = false
