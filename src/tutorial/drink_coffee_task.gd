class_name DrinkCoffeeTask
extends Task

## Teaches the one thing on the desk that is not itself a risk: the coffee does
## not move the clock, it multiplies whatever the player already has running. It
## comes after the distractions for that reason - there has to be something worth
## multiplying before the lesson means anything.
##
## Completed on the first sip, whenever it happens: a player who tried the cup
## out during an earlier beat has already learned this one.

var drunk := false

func _init() -> void:
	super._init("Drink coffee", "Drink your coffee while distracted", null)
	EventBus.buff_started.connect(_on_buff_started)

func start_task() -> void:
	pass

func check_completed() -> bool:
	return drunk

func _on_buff_started(source_id: StringName, _multiplier: float) -> void:
	if source_id != CoffeeBuff.SOURCE_ID:
		return
	drunk = true
	notify_changed()
