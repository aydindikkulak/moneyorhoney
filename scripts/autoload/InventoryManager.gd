extends Node

signal item_purchased(item_id: String)
signal item_used(item_id: String)
signal inventory_changed

var inventory: Dictionary = {}
var tool_upgrades: Dictionary = {}
var consumables: Dictionary = {}
var passive_items: Array = []

func _ready():
	print("InventoryManager initialized")

func start_new_game():
	inventory.clear()
	tool_upgrades.clear()
	consumables.clear()
	passive_items.clear()

func add_item(item_data: Dictionary) -> void:
	var item_id = item_data["id"]
	var item_type = item_data["type"]
	
	if not inventory.has(item_id):
		inventory[item_id] = {
			"data": item_data,
			"quantity": 0,
			"purchased_week": WeekCycleSystem.get_current_week()
		}
	
	inventory[item_id]["quantity"] += 1
	
	match item_type:
		"tool_upgrade":
			tool_upgrades[item_data["tool"]] = item_data
		"consumable":
			consumables[item_id] = {
				"data": item_data,
				"remaining_days": item_data["effect"]["duration_days"]
			}
		"passive":
			if item_id not in passive_items:
				passive_items.append(item_id)
	
	item_purchased.emit(item_id)
	inventory_changed.emit()
	print("Item added to inventory: ", item_data["name"])

func use_consumable(item_id: String) -> Dictionary:
	if not consumables.has(item_id):
		return {}
	
	var consumable = consumables[item_id]
	if consumable["remaining_days"] <= 0:
		consumables.erase(item_id)
		inventory_changed.emit()
		return {}
	
	consumable["remaining_days"] -= 1
	item_used.emit(item_id)
	
	if consumable["remaining_days"] <= 0:
		consumables.erase(item_id)
	
	inventory_changed.emit()
	return consumable["data"]["effect"]

func has_item(item_id: String) -> bool:
	return inventory.has(item_id) and inventory[item_id]["quantity"] > 0

func get_item_data(item_id: String) -> Dictionary:
	if inventory.has(item_id):
		return inventory[item_id]["data"]
	return {}

func get_tool_upgrade(tool_name: String) -> Dictionary:
	if tool_upgrades.has(tool_name):
		return tool_upgrades[tool_name]
	return {}

func get_active_consumables() -> Array:
	var active = []
	for item_id in consumables.keys():
		var consumable = consumables[item_id]
		if consumable["remaining_days"] > 0:
			active.append({
				"id": item_id,
				"data": consumable["data"],
				"remaining_days": consumable["remaining_days"]
			})
	return active

func get_passive_items() -> Array:
	return passive_items

func get_total_accuracy_bonus() -> float:
	var bonus = 0.0
	
	for tool_name in tool_upgrades.keys():
		var upgrade = tool_upgrades[tool_name]
		bonus += upgrade["effect"].get("accuracy_bonus", 0.0)
	
	for item_id in consumables.keys():
		var consumable = consumables[item_id]
		if consumable["remaining_days"] > 0:
			bonus += consumable["data"]["effect"].get("accuracy_bonus", 0.0)
	
	for item_id in passive_items:
		if inventory.has(item_id):
			var item_data = inventory[item_id]["data"]
			bonus += item_data["effect"].get("accuracy_bonus", 0.0)
	
	return bonus

func get_total_speed_bonus() -> float:
	var bonus = 0.0
	
	for item_id in consumables.keys():
		var consumable = consumables[item_id]
		if consumable["remaining_days"] > 0:
			bonus += consumable["data"]["effect"].get("speed_bonus", 0.0)
	
	return bonus

func get_combo_chance_bonus() -> float:
	var bonus = 0.0
	
	for item_id in passive_items:
		if inventory.has(item_id):
			var item_data = inventory[item_id]["data"]
			bonus += item_data["effect"].get("combo_chance", 0.0)
	
	return bonus

func has_first_mistake_forgiven() -> bool:
	for item_id in passive_items:
		if inventory.has(item_id):
			var item_data = inventory[item_id]["data"]
			if item_data["effect"].get("first_mistake_forgiven", false):
				return true
	return false

func get_inventory_summary() -> Dictionary:
	return {
		"total_items": inventory.size(),
		"tool_upgrades": tool_upgrades.size(),
		"active_consumables": consumables.size(),
		"passive_items": passive_items.size()
	}
