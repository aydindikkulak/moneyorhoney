extends Node

class CurrencyInfo:
	var code: String
	var name: String
	var symbol: String
	var denominations: Array
	var colors: Dictionary
	
	func _init(c: String, n: String, s: String, d: Array, col: Dictionary):
		code = c
		name = n
		symbol = s
		denominations = d
		colors = col

var currencies: Dictionary = {}

func _ready():
	_init_currencies()

func _init_currencies():
	currencies["USD"] = CurrencyInfo.new("USD", "US Dollar", "$", [1, 5, 10, 20, 50, 100], {
		"1": {"primary": "#3d6b3d", "secondary": "#5a8a5a"},
		"5": {"primary": "#6b4a3d", "secondary": "#8a6a5a"},
		"10": {"primary": "#3d4a6b", "secondary": "#5a6a8a"},
		"20": {"primary": "#4a6b3d", "secondary": "#6a8a5a"},
		"50": {"primary": "#6b3d4a", "secondary": "#8a5a6a"},
		"100": {"primary": "#3d6b5a", "secondary": "#5a8a7a"}
	})
	
	currencies["EUR"] = CurrencyInfo.new("EUR", "Euro", "€", [5, 10, 20, 50, 100, 200, 500], {
		"5": {"primary": "#808080", "secondary": "#a0a0a0"},
		"10": {"primary": "#804040", "secondary": "#a06060"},
		"20": {"primary": "#406080", "secondary": "#6080a0"},
		"50": {"primary": "#806040", "secondary": "#a08060"},
		"100": {"primary": "#408060", "secondary": "#60a080"},
		"200": {"primary": "#604080", "secondary": "#8060a0"},
		"500": {"primary": "#806080", "secondary": "#a080a0"}
	})
	
	currencies["GBP"] = CurrencyInfo.new("GBP", "British Pound", "£", [5, 10, 20, 50], {
		"5": {"primary": "#3d5a80", "secondary": "#5a7aa0"},
		"10": {"primary": "#805a3d", "secondary": "#a07a5a"},
		"20": {"primary": "#5a803d", "secondary": "#7aa05a"},
		"50": {"primary": "#803d5a", "secondary": "#a05a7a"}
	})

func get_currency_info(code: String) -> CurrencyInfo:
	return currencies.get(code, null)

func get_color(currency: String, denomination: int) -> Dictionary:
	var info = get_currency_info(currency)
	if info == null:
		return {"primary": "#666666", "secondary": "#888888"}
	return info.colors.get(str(denomination), {"primary": "#666666", "secondary": "#888888"})
