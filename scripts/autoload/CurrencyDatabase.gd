extends Node

var currencies_data: Dictionary = {}
var fake_patterns_data: Dictionary = {}

func _ready():
	load_currencies()
	load_fake_patterns()

func load_currencies():
	var file = FileAccess.open("res://data/currencies.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			currencies_data = json.data
			print("Loaded ", currencies_data.size(), " currencies")
		else:
			print("Error parsing currencies.json: ", error)
			load_default_currencies()
	else:
		print("Could not open currencies.json, using defaults")
		load_default_currencies()

func load_default_currencies():
	currencies_data = {
		"USD": {
			"name": "US Dollar",
			"symbol": "$",
			"denominations": [1, 5, 10, 20, 50, 100],
			"security_features": {
				"3d_ribbon": true,
				"color_shifting_ink": true,
				"watermark": true,
				"uv_features": true,
				"micro_printing": true
			},
			"colors": {
				"primary": "#4a5d23",
				"secondary": "#8b9556",
				"accent": "#2d3a0f"
			}
		},
		"EUR": {
			"name": "Euro",
			"symbol": "€",
			"denominations": [5, 10, 20, 50, 100, 200, 500],
			"security_features": {
				"hologram_strip": true,
				"watermark": true,
				"security_thread": true,
				"uv_features": true,
				"micro_printing": true
			},
			"colors": {
				"primary": "#3d5a80",
				"secondary": "#98c1d9",
				"accent": "#293241"
			}
		},
		"GBP": {
			"name": "British Pound",
			"symbol": "£",
			"denominations": [5, 10, 20, 50],
			"security_features": {
				"hologram": true,
				"metallic_patch": true,
				"raised_print": true,
				"uv_features": true,
				"micro_printing": true
			},
			"colors": {
				"primary": "#6b4226",
				"secondary": "#a67c52",
				"accent": "#3d2817"
			}
		}
	}

func load_fake_patterns():
	var file = FileAccess.open("res://data/fake_patterns.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			fake_patterns_data = json.data
			print("Loaded fake patterns")
		else:
			print("Error parsing fake_patterns.json: ", error)
			load_default_fake_patterns()
	else:
		print("Could not open fake_patterns.json, using defaults")
		load_default_fake_patterns()

func load_default_fake_patterns():
	fake_patterns_data = {
		"easy": {
			"color_deviation": 0.3,
			"size_deviation": 0.05,
			"missing_features": ["uv_features", "micro_printing"],
			"detection_chance": 0.9
		},
		"medium": {
			"color_deviation": 0.15,
			"size_deviation": 0.02,
			"missing_features": ["micro_printing"],
			"detection_chance": 0.7
		},
		"hard": {
			"color_deviation": 0.08,
			"size_deviation": 0.01,
			"missing_features": [],
			"detection_chance": 0.5
		},
		"professional": {
			"color_deviation": 0.03,
			"size_deviation": 0.005,
			"missing_features": [],
			"detection_chance": 0.3
		}
	}

func get_currency_data(currency_code: String) -> Dictionary:
	return currencies_data.get(currency_code, {})

func get_denominations(currency_code: String) -> Array:
	var currency = get_currency_data(currency_code)
	return currency.get("denominations", [])

func get_security_features(currency_code: String) -> Dictionary:
	var currency = get_currency_data(currency_code)
	return currency.get("security_features", {})

func get_fake_pattern(difficulty: String) -> Dictionary:
	return fake_patterns_data.get(difficulty, fake_patterns_data["easy"])

func is_valid_currency(currency_code: String) -> bool:
	return currencies_data.has(currency_code)

func is_valid_denomination(currency_code: String, denomination: int) -> bool:
	var denominations = get_denominations(currency_code)
	return denomination in denominations

func generate_banknote_data(currency_code: String, denomination: int, is_fake: bool, difficulty: String = "easy") -> Dictionary:
	var currency = get_currency_data(currency_code)
	if currency.is_empty():
		return {}
	
	var serial_number = _generate_serial_number(currency_code)
	
	var banknote = {
		"currency": currency_code,
		"denomination": denomination,
		"serial_number": serial_number,
		"is_fake": is_fake,
		"difficulty": difficulty,
		"security_features": {},
		"visual_properties": {}
	}
	
	if is_fake:
		var pattern = get_fake_pattern(difficulty)
		banknote["visual_properties"] = {
			"color_deviation": pattern["color_deviation"],
			"size_deviation": pattern["size_deviation"],
			"weight_deviation": randf_range(0.02, 0.08)
		}
		
		var all_features = currency.get("security_features", {})
		var missing = pattern.get("missing_features", [])
		for feature in all_features:
			banknote["security_features"][feature] = not (feature in missing)
	else:
		banknote["visual_properties"] = {
			"color_deviation": 0.0,
			"size_deviation": 0.0,
			"weight_deviation": 0.0
		}
		var all_features = currency.get("security_features", {})
		for feature in all_features:
			banknote["security_features"][feature] = true
	
	return banknote

func _generate_serial_number(currency_code: String) -> String:
	var prefix = currency_code.substr(0, 2).to_upper()
	var number = str(randi() % 99999999).pad_zeros(8)
	return prefix + number
