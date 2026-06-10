extends Node

signal tool_activated(tool_name: String)
signal tool_deactivated
signal inspection_result(result: Dictionary)

enum ToolType {
	NONE,
	MAGNIFIER,
	UV_LAMP,
	SCALE,
	MICROSCOPE
}

var available_tools: Array = []
var active_tool: ToolType = ToolType.NONE
var is_tool_active: bool = false
var tool_usage_stats: Dictionary = {}
var tool_findings_history: Array = []

var tool_info: Dictionary = {
	ToolType.MAGNIFIER: {
		"name": "Buyutec",
		"description": "Detayli inceleme - seri numarasi ve mikro yazilar",
		"shortcut": "1",
		"unlocked": false
	},
	ToolType.UV_LAMP: {
		"name": "UV Lamba",
		"description": "Ultraviyole isik - guvenlik izleri",
		"shortcut": "2",
		"unlocked": false
	},
	ToolType.SCALE: {
		"name": "Terazi",
		"description": "Agirlik kontrolu",
		"shortcut": "3",
		"unlocked": false
	},
	ToolType.MICROSCOPE: {
		"name": "Mikroskop",
		"description": "Yuksek buyutme - mikro yazilar",
		"shortcut": "4",
		"unlocked": false
	}
}

func _ready():
	pass

func setup_tools(level: int):
	available_tools.clear()
	var tool_names = LevelManager.get_available_tools(level)
	
	for tool_name in tool_names:
		match tool_name:
			"magnifier":
				available_tools.append(ToolType.MAGNIFIER)
				tool_info[ToolType.MAGNIFIER]["unlocked"] = true
			"uv_lamp":
				available_tools.append(ToolType.UV_LAMP)
				tool_info[ToolType.UV_LAMP]["unlocked"] = true
			"scale":
				available_tools.append(ToolType.SCALE)
				tool_info[ToolType.SCALE]["unlocked"] = true
			"microscope":
				available_tools.append(ToolType.MICROSCOPE)
				tool_info[ToolType.MICROSCOPE]["unlocked"] = true

func activate_tool(tool: ToolType) -> bool:
	if tool not in available_tools:
		return false
	
	if active_tool == tool:
		deactivate_tool()
		return true
	
	active_tool = tool
	is_tool_active = true
	
	# Track usage statistics
	if not tool_usage_stats.has(tool):
		tool_usage_stats[tool] = 0
	tool_usage_stats[tool] += 1
	
	tool_activated.emit(tool_info[tool]["name"])
	return true

func deactivate_tool():
	active_tool = ToolType.NONE
	is_tool_active = false
	tool_deactivated.emit()

func get_active_tool_name() -> String:
	if active_tool == ToolType.NONE:
		return ""
	return tool_info[active_tool]["name"]

func get_tool_description(tool: ToolType) -> String:
	return tool_info.get(tool, {}).get("description", "")

func inspect_with_tool(banknote: Banknote, tool: ToolType) -> Dictionary:
	if not activate_tool(tool):
		return {"error": "Tool not available"}
	
	var result = banknote.use_tool(tool)
	inspection_result.emit(result)
	
	# Store finding in history
	var finding_record = {
		"tool": tool_info[tool]["name"],
		"result": result,
		"timestamp": Time.get_ticks_msec()
	}
	tool_findings_history.append(finding_record)
	
	return result

func get_tool_usage_stats() -> Dictionary:
	return tool_usage_stats

func get_findings_history() -> Array:
	return tool_findings_history

func get_tool_effectiveness(tool: ToolType) -> float:
	var count = tool_usage_stats.get(tool, 0)
	if count == 0:
		return 0.0
	
	var successful_findings = 0
	for finding in tool_findings_history:
		if finding["tool"] == tool_info[tool]["name"]:
			var result = finding["result"]
			for key in result:
				if result[key] == true or (result[key] is String and "anomaly" in result[key].to_lower()):
					successful_findings += 1
					break
	
	return float(successful_findings) / float(count)

func get_detailed_tool_guide(tool: ToolType) -> Dictionary:
	match tool:
		ToolType.MAGNIFIER:
			return {
				"name": "Buyutec",
				"usage": "Banknot uzerindeki kucuk detaylari inceler",
				"detects": ["Seri numarasi formati", "Mikro yazilar", "Boyut sapmasi"],
				"tip": "Sahte paralarda seri numarasi formati genellikle hatalidir"
			}
		ToolType.UV_LAMP:
			return {
				"name": "UV Lamba",
				"usage": "Ultraviyole isik altinda guvenlik izlerini kontrol eder",
				"detects": ["UV guvenlik izleri", "Ozel murekkep izleri", "Guvenlik iplikleri"],
				"tip": "Cok sahte paralarda UV ozellikler eksik veya zayiftir"
			}
		ToolType.SCALE:
			return {
				"name": "Terazi",
				"usage": "Banknotun agirligini olcer",
				"detects": ["Agirlik sapmasi", "Yanlis kagit tipi"],
				"tip": "Sahte paralar genellikle gerceklerden hafif veya agirdir"
			}
		ToolType.MICROSCOPE:
			return {
				"name": "Mikroskop",
				"usage": "Cok yuksek buyutme ile detayli inceleme yapar",
				"detects": ["Mikro yazilar", "Baski kalitesi", "Lif yapisı"],
				"tip": "Profesyonel sahteciler bile mikro yazilari taklit edemez"
			}
	return {}

func get_available_tool_count() -> int:
	return available_tools.size()

func is_tool_available(tool: ToolType) -> bool:
	return tool in available_tools

func reset():
	deactivate_tool()
	available_tools.clear()
	for key in tool_info:
		tool_info[key]["unlocked"] = false
