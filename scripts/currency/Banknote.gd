extends Node
class_name Banknote

signal inspection_started(banknote_data: Dictionary)
signal inspection_completed(result: Dictionary)

var banknote_data: Dictionary = {}
var is_inspected: bool = false
var tool_results: Dictionary = {}

func setup(data: Dictionary):
	banknote_data = data
	is_inspected = false
	tool_results.clear()
	inspection_started.emit(banknote_data)

func use_tool(tool_type: int) -> Dictionary:
	var result = {}
	
	match tool_type:
		1:  # MAGNIFIER
			result = _check_magnifier()
		2:  # UV_LAMP
			result = _check_uv_lamp()
		3:  # SCALE
			result = _check_scale()
		4:  # MICROSCOPE
			result = _check_microscope()
	
	tool_results[tool_type] = result
	return result

func _check_magnifier() -> Dictionary:
	var findings = {}
	
	if banknote_data.get("is_fake", false):
		var deviation = banknote_data.get("visual_properties", {}).get("size_deviation", 0.0)
		if deviation > 0.01:
			findings["size_anomaly"] = true
			findings["detail"] = "Boyut sapmasi tespit edildi"
		else:
			findings["size_anomaly"] = false
		
		var serial = banknote_data.get("serial_number", "")
		if _check_serial_format(serial):
			findings["serial_valid"] = true
		else:
			findings["serial_valid"] = false
			findings["detail"] = "Seri numarasi format hatasi"
	else:
		findings["size_anomaly"] = false
		findings["serial_valid"] = true
	
	return findings

func _check_uv_lamp() -> Dictionary:
	var findings = {}
	var features = banknote_data.get("security_features", {})
	
	var has_uv = features.get("uv_features", true)
	
	if banknote_data.get("is_fake", false):
		var difficulty = banknote_data.get("difficulty", "easy")
		if difficulty == "easy":
			findings["uv_response"] = false
			findings["detail"] = "UV yaniti yok - sahte!"
		elif difficulty == "medium":
			findings["uv_response"] = randf() > 0.5
			if not findings["uv_response"]:
				findings["detail"] = "Zayif UV yaniti"
		else:
			findings["uv_response"] = true
			findings["detail"] = "Normal UV yaniti"
	else:
		findings["uv_response"] = true
		findings["detail"] = "Normal UV yaniti"
	
	return findings

func _check_scale() -> Dictionary:
	var findings = {}
	var weight_dev = banknote_data.get("visual_properties", {}).get("weight_deviation", 0.0)
	
	if weight_dev > 0.05:
		findings["weight_anomaly"] = true
		findings["detail"] = "Agirlik sapmasi: %.1f%%" % (weight_dev * 100)
	elif weight_dev > 0.02:
		findings["weight_anomaly"] = randf() > 0.5
		findings["detail"] = "Hafif agirlik sapmasi"
	else:
		findings["weight_anomaly"] = false
		findings["detail"] = "Normal agirlik"
	
	return findings

func _check_microscope() -> Dictionary:
	var findings = {}
	var features = banknote_data.get("security_features", {})
	
	var has_micro = features.get("micro_printing", true)
	
	if banknote_data.get("is_fake", false):
		if not has_micro:
			findings["micro_printing"] = false
			findings["detail"] = "Mikro yazilar eksik veya bulanik"
		else:
			findings["micro_printing"] = true
			findings["detail"] = "Mikro yazilar mevcut"
	else:
		findings["micro_printing"] = true
		findings["detail"] = "Mikro yazilar net ve mevcut"
	
	return findings

func _check_serial_format(serial: String) -> bool:
	if serial.length() < 10:
		return false
	var prefix = serial.substr(0, 2)
	var expected_prefix = banknote_data.get("currency", "XX").substr(0, 2).to_upper()
	return prefix == expected_prefix

func get_visual_description() -> String:
	var currency = banknote_data.get("currency", "???")
	var denom = banknote_data.get("denomination", 0)
	var serial = banknote_data.get("serial_number", "N/A")
	return "%s %d - SN: %s" % [currency, denom, serial]

func get_suspicion_level() -> float:
	var suspicion = 0.0
	
	for tool in tool_results:
		var result = tool_results[tool]
		if result.get("size_anomaly", false):
			suspicion += 0.3
		if result.get("serial_valid", true) == false:
			suspicion += 0.2
		if result.get("uv_response", true) == false:
			suspicion += 0.3
		if result.get("weight_anomaly", false):
			suspicion += 0.2
		if result.get("micro_printing", true) == false:
			suspicion += 0.3
	
	return clampf(suspicion, 0.0, 1.0)
