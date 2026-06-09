extends Node

signal inspection_complete(result: Dictionary)
signal visual_check_complete(result: Dictionary)
signal tool_check_complete(tool: String, result: Dictionary)

var current_banknote: Banknote
var current_customer_data: Dictionary = {}
var active_tool: int = 0

var visual_findings: Dictionary = {}
var tool_findings: Dictionary = {}
var overall_suspicion: float = 0.0

func _ready():
	pass

func start_inspection(customer_data: Dictionary):
	current_customer_data = customer_data
	current_banknote = Banknote.new()
	current_banknote.setup(customer_data.get("banknote", {}))
	
	visual_findings.clear()
	tool_findings.clear()
	overall_suspicion = 0.0

func perform_visual_check() -> Dictionary:
	if current_banknote == null:
		return {}
	
	var banknote_data = current_banknote.banknote_data
	var findings: Dictionary = {}
	
	var color_dev = banknote_data.get("visual_properties", {}).get("color_deviation", 0.0)
	if color_dev > 0.15:
		findings["color_issue"] = true
		findings["color_detail"] = "Renk tonu normalden farkli"
		overall_suspicion += 0.2
	else:
		findings["color_issue"] = false
	
	var size_dev = banknote_data.get("visual_properties", {}).get("size_deviation", 0.0)
	if size_dev > 0.03:
		findings["size_issue"] = true
		findings["size_detail"] = "Boyut farki goruluyor"
		overall_suspicion += 0.2
	else:
		findings["size_issue"] = false
	
	var serial = banknote_data.get("serial_number", "")
	findings["serial_number"] = serial
	if serial.length() >= 10:
		findings["serial_format_ok"] = true
	else:
		findings["serial_format_ok"] = false
		overall_suspicion += 0.1
	
	findings["currency"] = banknote_data.get("currency", "")
	findings["denomination"] = banknote_data.get("denomination", 0)
	
	visual_findings = findings
	visual_check_complete.emit(findings)
	return findings

func use_tool_on_banknote(tool_type: int) -> Dictionary:
	if current_banknote == null:
		return {}
	
	var result = current_banknote.use_tool(tool_type)
	tool_findings[tool_type] = result
	
	var tool_name = ""
	match tool_type:
		1: tool_name = "Buyutec"
		2: tool_name = "UV Lamba"
		3: tool_name = "Terazi"
		4: tool_name = "Mikroskop"
	
	tool_check_complete.emit(tool_name, result)
	
	if result.get("size_anomaly", false):
		overall_suspicion += 0.25
	if result.get("serial_valid", true) == false:
		overall_suspicion += 0.2
	if result.get("uv_response", true) == false:
		overall_suspicion += 0.3
	if result.get("weight_anomaly", false):
		overall_suspicion += 0.2
	if result.get("micro_printing", true) == false:
		overall_suspicion += 0.3
	
	overall_suspicion = clampf(overall_suspicion, 0.0, 1.0)
	return result

func make_decision() -> Dictionary:
	var is_fake = current_customer_data.get("is_fake", false)
	var is_money_laundering = current_customer_data.get("is_money_laundering", false)
	
	var decision = {
		"suspicion_level": overall_suspicion,
		"visual_findings": visual_findings,
		"tool_findings": tool_findings,
		"recommendation": "",
		"is_fake": is_fake,
		"is_money_laundering": is_money_laundering
	}
	
	if overall_suspicion >= 0.6:
		decision["recommendation"] = "RED - Sahte veya supheli"
	elif overall_suspicion >= 0.3:
		decision["recommendation"] = "DIKKAT - Ek inceleme gerekli"
	else:
		decision["recommendation"] = "KABUL - Normal gorunuyor"
	
	inspection_complete.emit(decision)
	return decision

func get_suspicion_level() -> float:
	return overall_suspicion

func reset():
	current_banknote = null
	current_customer_data = {}
	visual_findings.clear()
	tool_findings.clear()
	overall_suspicion = 0.0
