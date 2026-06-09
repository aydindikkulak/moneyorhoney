extends Node

var levels_data: Array = []
var current_level_index: int = 0

func _ready():
	load_levels()

func load_levels():
	var file = FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			levels_data = json.data
			print("Loaded ", levels_data.size(), " levels")
		else:
			print("Error parsing levels.json: ", error)
			load_default_levels()
	else:
		print("Could not open levels.json, using defaults")
		load_default_levels()

func load_default_levels():
	levels_data = [
		{
			"id": 1,
			"name": "Is Baslangici",
			"description": "Temel gorsel inceleme",
			"currencies": ["USD"],
			"tools": [],
			"has_documents": false,
			"has_money_laundering": false,
			"customers_per_day": 5,
			"days": 1,
			"fake_count": 2,
			"fake_difficulty": "easy",
			"suspicious_count": 0,
			"money_laundering_count": 0,
			"required_correct": 4,
			"time_per_customer": 60
		},
		{
			"id": 2,
			"name": "Arac Kutusu",
			"description": "Buyutec ve UV lamba kullanimi",
			"currencies": ["USD", "EUR"],
			"tools": ["magnifier", "uv_lamp"],
			"has_documents": false,
			"has_money_laundering": false,
			"customers_per_day": 8,
			"days": 1,
			"fake_count": 3,
			"fake_difficulty": "medium",
			"suspicious_count": 1,
			"money_laundering_count": 0,
			"required_correct": 6,
			"time_per_customer": 55
		},
		{
			"id": 3,
			"name": "Belge Kontrolu",
			"description": "Fatura ve dekont eslestirme",
			"currencies": ["USD", "EUR", "GBP"],
			"tools": ["magnifier", "uv_lamp", "scale"],
			"has_documents": true,
			"has_money_laundering": false,
			"customers_per_day": 10,
			"days": 1,
			"fake_count": 4,
			"fake_difficulty": "medium_hard",
			"suspicious_count": 2,
			"money_laundering_count": 1,
			"required_correct": 8,
			"time_per_customer": 50
		},
		{
			"id": 4,
			"name": "Kara Para Avcisi",
			"description": "Kara para tespiti ve kaynak kontrolu",
			"currencies": ["USD", "EUR", "GBP"],
			"tools": ["magnifier", "uv_lamp", "scale", "microscope"],
			"has_documents": true,
			"has_money_laundering": true,
			"customers_per_day": 12,
			"days": 1,
			"fake_count": 5,
			"fake_difficulty": "hard_professional",
			"suspicious_count": 3,
			"money_laundering_count": 2,
			"required_correct": 10,
			"time_per_customer": 45
		},
		{
			"id": 5,
			"name": "Uzman Vezneci",
			"description": "Tum mekanikler, zaman baskisi",
			"currencies": ["USD", "EUR", "GBP"],
			"tools": ["magnifier", "uv_lamp", "scale", "microscope"],
			"has_documents": true,
			"has_money_laundering": true,
			"customers_per_day": 15,
			"days": 1,
			"fake_count": 6,
			"fake_difficulty": "professional",
			"suspicious_count": 4,
			"money_laundering_count": 3,
			"required_correct": 13,
			"time_per_customer": 40
		}
	]

func get_level_data(level_id: int) -> Dictionary:
	for level in levels_data:
		if level["id"] == level_id:
			return level
	return {}

func get_total_levels() -> int:
	return levels_data.size()

func get_available_currencies(level_id: int) -> Array:
	var level_data = get_level_data(level_id)
	return level_data.get("currencies", ["USD"])

func get_available_tools(level_id: int) -> Array:
	var level_data = get_level_data(level_id)
	return level_data.get("tools", [])

func has_documents(level_id: int) -> bool:
	var level_data = get_level_data(level_id)
	return level_data.get("has_documents", false)

func has_money_laundering(level_id: int) -> bool:
	var level_data = get_level_data(level_id)
	return level_data.get("has_money_laundering", false)

func get_customer_count(level_id: int) -> int:
	var level_data = get_level_data(level_id)
	return level_data.get("customers_per_day", 5)

func get_fake_count(level_id: int) -> int:
	var level_data = get_level_data(level_id)
	return level_data.get("fake_count", 0)

func get_fake_difficulty(level_id: int) -> String:
	var level_data = get_level_data(level_id)
	return level_data.get("fake_difficulty", "easy")

func get_time_per_customer(level_id: int) -> int:
	var level_data = get_level_data(level_id)
	return level_data.get("time_per_customer", 60)
