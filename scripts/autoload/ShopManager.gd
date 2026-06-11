extends Node

signal shop_opened
signal shop_closed
signal item_purchased(item_id: String)
signal purchase_failed(item_id: String, reason: String)

var shop_items: Array = []
var purchased_items: Array = []

func _ready():
	load_shop_items()
	print("ShopManager initialized")

func load_shop_items() -> void:
	var file = FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			shop_items = json.data
		file.close()
	else:
		print("Failed to load shop_items.json")

func open_shop() -> void:
	shop_opened.emit()
	print("Shop opened")

func close_shop() -> void:
	shop_closed.emit()
	print("Shop closed")

func get_available_items() -> Array:
	var current_week = WeekCycleSystem.get_current_week()
	var available = []
	
	for item in shop_items:
		if item["requirements"]["week"] <= current_week:
			if not is_purchased(item["id"]):
				available.append(item)
	
	return available

func is_purchased(item_id: String) -> bool:
	return item_id in purchased_items

func can_afford(item_price: int) -> bool:
	return EarningsSystem.get_total_earnings() >= item_price

func purchase_item(item_id: String) -> Dictionary:
	if is_purchased(item_id):
		purchase_failed.emit(item_id, "Zaten satın alındı")
		return {"success": false, "reason": "Zaten satın alındı"}
	
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		purchase_failed.emit(item_id, "Öğe bulunamadı")
		return {"success": false, "reason": "Öğe bulunamadı"}
	
	if not can_afford(item_data["price"]):
		purchase_failed.emit(item_id, "Yetersiz bakiye")
		return {"success": false, "reason": "Yetersiz bakiye"}
	
	EarningsSystem.subtract_money(item_data["price"])
	purchased_items.append(item_id)
	InventoryManager.add_item(item_data)
	
	item_purchased.emit(item_id)
	print("Item purchased: ", item_data["name"])
	
	return {"success": true, "item": item_data}

func get_item_data(item_id: String) -> Dictionary:
	for item in shop_items:
		if item["id"] == item_id:
			return item
	return {}

func get_total_purchased() -> int:
	return purchased_items.size()

func reset() -> void:
	purchased_items.clear()
