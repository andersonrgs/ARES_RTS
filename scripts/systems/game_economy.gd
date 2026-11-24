extends Node
class_name GameEconomy

signal credits_changed(current_credits: int)
signal power_changed(produced: int, consumed: int)

@export var starting_credits: int = 5000
var credits: int = 5000
var power_produced: int = 0
var power_consumed: int = 0

func _ready() -> void:
	credits = starting_credits
	emit_signal("credits_changed", credits)
	emit_signal("power_changed", power_produced, power_consumed)

func has_credits(amount: int) -> bool:
	return credits >= amount

func spend_credits(amount: int) -> bool:
	if has_credits(amount):
		credits -= amount
		emit_signal("credits_changed", credits)
		return true
	return false

func add_credits(amount: int) -> void:
	credits += amount
	emit_signal("credits_changed", credits)

func register_building_power(produced: int, consumed: int) -> void:
	power_produced += produced
	power_consumed += consumed
	emit_signal("power_changed", power_produced, power_consumed)

func unregister_building_power(produced: int, consumed: int) -> void:
	power_produced -= produced
	power_consumed -= consumed
	emit_signal("power_changed", power_produced, power_consumed)

func is_power_low() -> bool:
	return power_produced < power_consumed
