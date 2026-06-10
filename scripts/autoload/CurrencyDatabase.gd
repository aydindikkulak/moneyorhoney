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
		"visual_properties": {},
		"detection_hints": []
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
		
		banknote["detection_hints"] = _generate_detection_hints(currency_code, difficulty, missing)
	else:
		banknote["visual_properties"] = {
			"color_deviation": 0.0,
			"size_deviation": 0.0,
			"weight_deviation": 0.0
		}
		var all_features = currency.get("security_features", {})
		for feature in all_features:
			banknote["security_features"][feature] = true
		banknote["detection_hints"] = []
	
	return banknote

func _generate_serial_number(currency_code: String) -> String:
	var prefix = currency_code.substr(0, 2).to_upper()
	var number = str(randi() % 99999999).pad_zeros(8)
	return prefix + number

func get_banknote_texture_path(currency_code: String, denomination: int, is_fake: bool) -> String:
	var currency_lower = currency_code.to_lower()
	var note_type = "fake" if is_fake else "real"
	return "res://assets/sprites/currencies/%s/%s_%d_%s.png" % [currency_lower, currency_lower, denomination, note_type]

func get_npc_texture_path(npc_type: String, variant: int = 0) -> String:
	return "res://assets/sprites/npcs/npc_%s_%d.png" % [npc_type, variant]

func get_tool_texture_path(tool_name: String) -> String:
	return "res://assets/sprites/tools/%s.png" % tool_name

func get_document_texture_path(doc_type: String, variant: int = 0) -> String:
	return "res://assets/sprites/documents/%s_%d.png" % [doc_type, variant]

func load_banknote_texture(currency_code: String, denomination: int, is_fake: bool) -> Texture2D:
	var path = get_banknote_texture_path(currency_code, denomination, is_fake)
	if ResourceLoader.exists(path):
		return load(path)
	return null

func load_npc_texture(npc_type: String, variant: int = 0) -> Texture2D:
	var path = get_npc_texture_path(npc_type, variant)
	if ResourceLoader.exists(path):
		return load(path)
	return null

func load_tool_texture(tool_name: String) -> Texture2D:
	var path = get_tool_texture_path(tool_name)
	if ResourceLoader.exists(path):
		return load(path)
	return null

func load_document_texture(doc_type: String, variant: int = 0) -> Texture2D:
	var path = get_document_texture_path(doc_type, variant)
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _generate_detection_hints(currency_code: String, difficulty: String, missing_features: Array) -> Array:
	var hints = []
	
	match difficulty:
		"easy":
			if "uv_features" in missing_features:
				hints.append("UV isik altinda guvenlik izi gorunmuyor")
			if "micro_printing" in missing_features:
				hints.append("Mikro yazilar bulanik veya eksik")
			hints.append("Renk tonu hafif farkli")
		
		"medium":
			if "micro_printing" in missing_features:
				hints.append("Buyutec altinda mikro yazilar net degil")
			if currency_code == "USD":
				hints.append("3D guvenlik seridi hareket etmiyor")
			elif currency_code == "EUR":
				hints.append("Hologram serit soluk")
		
		"hard":
			hints.append("Agirlik %d%% farkli" % int(randf_range(2, 5)))
			if currency_code == "USD":
				hints.append("Renk degisen murekkep yavas tepki veriyor")
		
		"professional":
			hints.append("Cok iyi kopya, sadece uzman gozu yakalayabilir")
			if currency_code == "USD" or currency_code == "EUR":
				hints.append("Watermark hafif bulanik")
	
	return hints

func get_banknote_description(banknote_data: Dictionary) -> String:
	var currency = banknote_data.get("currency", "")
	var denomination = banknote_data.get("denomination", 0)
	var serial = banknote_data.get("serial_number", "")
	var currency_info = get_currency_data(currency)
	var symbol = currency_info.get("symbol", "")
	
	return "%s %d%s - SN: %s" % [symbol, denomination, currency, serial]

func get_security_check_guide(currency_code: String) -> Dictionary:
	var currency = get_currency_data(currency_code)
	var features = currency.get("security_features", {})
	var guide = {}
	
	for feature in features:
		match feature:
			"3d_ribbon":
				guide[feature] = "3D guvenlik seridi: Banknotu egdiginde mavi-yesil arasi renk degisir"
			"color_shifting_ink":
				guide[feature] = "Renk degisen mureke: Sayinin rengini egince bakir-yesil arasi degisir"
			"watermark":
				guide[feature] = "Watermark: Isiga karsi tutuldugunda portre gorunur"
			"uv_features":
				guide[feature] = "UV ozellikler: UV isik altinda kirmizi-mavi izler gorunur"
			"micro_printing":
				guide[feature] = "Mikro yazilar: Buyutec altinda kucuk yazilar okunabilir"
			"hologram_strip":
				guide[feature] = "Hologram serit: Banknotu hareket ettirince hologram degisir"
			"security_thread":
				guide[feature] = "Guvenlik ipligi: Isiga karsi tutuldugunda dikey bir cizgi gorunur"
			"hologram":
				guide[feature] = "Hologram: Hareket ettirince 3D goruntu degisir"
			"metallic_patch":
				guide[feature] = "Metalik yama: Isik altinda parlayan metalik alan"
			"raised_print":
				guide[feature] = "Kabartma baski: Parmakla dokunuldugunda kabartma hissedilir"
	
	return guide
