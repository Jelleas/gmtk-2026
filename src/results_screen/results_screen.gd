extends Control

## The other bookend to the login screen: the day is over, so the monitor comes
## back up with the shift written out on it. Everything shown here comes from
## [GameStats], which [StatTracker] filled in while the day was being wasted.

@onready var rank_label: Label = %RankLabel
@onready var subline_label: Label = %SublineLabel
@onready var rows: VBoxContainer = %Rows
@onready var button_row: HBoxContainer = %ButtonRow
@onready var clock_in_again_button: Button = %ClockInAgainButton

const ROW_FONT_SIZE := 9
const HEADER_FONT_SIZE := 8
const LABEL_COLOR := Color(0.1, 0.1, 0.1)
const VALUE_COLOR := Color(0.0, 0.0, 0.5)
const HEADER_COLOR := Color(0.3, 0.3, 0.3)

## How long each row takes to fade in, and how long the next one waits. Slow
## enough to read as a machine printing a report, quick enough that the whole
## thing is up in about a second.
const ROW_FADE := 0.1
const ROW_STEP := 0.05

## What the day is worth, by the average multiplier that earned it. Walked from
## the top down, so the first one the player is under is the one they get.
const RANKS: Array[Dictionary] = [
	{
		"below": 2.0,
		"title": "MODEL EMPLOYEE",
		"quip": "You worked. Nobody asked you to enjoy it, but nobody asked for this either.",
	},
	{
		"below": 4.0,
		"title": "CASUAL SLACKER",
		"quip": "A few stolen minutes here and there. Baby steps.",
	},
	{
		"below": 7.0,
		"title": "SEASONED SKIVER",
		"quip": "You have clearly done this before.",
	},
	{
		"below": 12.0,
		"title": "PROFESSIONAL TIME WASTER",
		"quip": "Barely a keystroke all day. Beautiful work.",
	},
	{
		"below": INF,
		"title": "EMPLOYEE OF THE MONTH",
		"quip": "The company got nothing out of you. Not one thing.",
	},
]

func _ready() -> void:
	clock_in_again_button.pressed.connect(_restart)

## Fills the report in and starts it printing.
func show_stats(stats: GameStats) -> void:
	var rank := _rank_for(stats.average_multiplier())
	rank_label.text = rank["title"]
	subline_label.text = "Clocked out in %s. %s" % [
		GameStats.format_duration(stats.real_seconds),
		rank["quip"],
	]

	for entry in _build_entries(stats):
		rows.add_child(_build_row(entry))

	_reveal()

## The report itself. Order runs from the headline numbers down to the day's
## receipts, so the first thing revealed is the thing worth bragging about.
func _build_entries(stats: GameStats) -> Array[Dictionary]:
	var entries: Array[Dictionary] = [
		{"label": "Shift completed in", "value": GameStats.format_duration(stats.real_seconds)},
		{"label": "Saved by slacking", "value": GameStats.format_duration(stats.real_seconds_saved())},
		{"label": "Average multiplier", "value": "%.1fx" % stats.average_multiplier()},
		{"label": "Peak multiplier", "value": "%.1fx" % stats.peak_multiplier},
		{"header": "DISTRACTIONS"},
		{
			"label": "Fidget spinner",
			"value": "%d spins / %s" % [
				stats.fidget_clicks,
				GameStats.format_duration(stats.get_active_seconds(&"fidget_spinner")),
			],
		},
		{
			"label": "Profiles swiped",
			"value": "%d  (%d right / %d left)" % [
				stats.total_swipes(), stats.swipes_right, stats.swipes_left,
			],
		},
		{
			"label": "Video",
			"value": "%d coins / %d hits" % [stats.video_coins, stats.video_hits],
		},
		{"header": "THE BOSS"},
		{
			"label": "Peeks survived",
			"value": "%d of %d" % [stats.peeks_survived(), stats.boss_peeks],
		},
		{
			"label": "Caught slacking",
			"value": "%d  (%d extra tasks)" % [stats.times_caught, stats.punishment_tasks_completed],
		},
	]
	return entries

func _build_row(entry: Dictionary) -> Control:
	if entry.has("header"):
		return _build_header(entry["header"])

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)

	var label := Label.new()
	label.text = entry["label"]
	label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	label.add_theme_color_override(&"font_color", LABEL_COLOR)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = entry["value"]
	value.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	value.add_theme_color_override(&"font_color", VALUE_COLOR)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	return row

## A section title with a rule running off to the right of it.
func _build_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", HEADER_FONT_SIZE)
	label.add_theme_color_override(&"font_color", HEADER_COLOR)
	row.add_child(label)

	var rule := HSeparator.new()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule)

	return row

## Rows tick in one after another, the button last: the player should have read
## the day before they are offered another one.
func _reveal() -> void:
	var revealing: Array[Control] = []
	for row in rows.get_children():
		revealing.append(row)
	revealing.append(button_row)

	for control in revealing:
		control.modulate.a = 0.0

	var tween := create_tween()
	for control in revealing:
		tween.tween_property(control, "modulate:a", 1.0, ROW_FADE)
		tween.tween_interval(ROW_STEP)

func _rank_for(average_multiplier: float) -> Dictionary:
	for rank in RANKS:
		if average_multiplier < rank["below"]:
			return rank
	return RANKS.back()

func _restart() -> void:
	# The office clears the stats on the way in, so a reload is a clean run.
	get_tree().reload_current_scene()
