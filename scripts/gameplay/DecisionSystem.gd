extends Node

signal decision_made(decision_type: String, banknote: Dictionary, result: Dictionary)
signal correct_decision(decision_type: String, points: int)
signal wrong_decision(decision_type: String, penalty: int)
signal report_filed(banknote: Dictionary, reason: String)

enum DecisionType {
	ACCEPT,
	REJECT,
	REPORT
}

var decisions_today: Array = []
var total_decisions: int = 0
var correct_decisions: int = 0
var wrong_decisions: int = 0

func _ready():
	WeekCycleSystem.day_started.connect(_on_day_started)
	print("DecisionSystem initialized")

func make_decision(decision_type: DecisionType, banknote: Dictionary, customer: Dictionary) -> Dictionary:
	var is_fake = banknote.get("is_fake", false)
	var is_money_laundering = customer.get("is_money_laundering", false)
	
	var correct = false
	var points = 0
	var result = {}
	
	match decision_type:
		DecisionType.ACCEPT:
			if not is_fake and not is_money_laundering:
				correct = true
				points = 100
				result = {
					"correct": true,
					"points": points,
					"message": "Doğru karar! Geçerli banknot.",
					"earning": banknote.get("amount", 0)
				}
			else:
				correct = false
				points = -50
				result = {
					"correct": false,
					"points": points,
					"message": "Yanlış karar! Sahte para kabul ettiniz.",
					"penalty": banknote.get("amount", 0)
				}
		
		DecisionType.REJECT:
			if is_fake:
				correct = true
				points = 150
				result = {
					"correct": true,
					"points": points,
					"message": "Doğru karar! Sahte para reddedildi.",
					"earning": 0
				}
			else:
				correct = false
				points = -75
				result = {
					"correct": false,
					"points": points,
					"message": "Yanlış karar! Geçerli parayı reddettiniz.",
					"penalty": 50
				}
		
		DecisionType.REPORT:
			if is_money_laundering:
				correct = true
				points = 300
				result = {
					"correct": true,
					"points": points,
					"message": "Mükemmel! Kara para aklamayı ihbar ettiniz!",
					"earning": 100
				}
				report_filed.emit(banknote, "Kara para aklama şüphesi")
			elif is_fake:
				correct = true
				points = 200
				result = {
					"correct": true,
					"points": points,
					"message": "İyi! Sahte parayı ihbar ettiniz!",
					"earning": 50
				}
				report_filed.emit(banknote, "Sahte para şüphesi")
			else:
				correct = false
				points = -100
				result = {
					"correct": false,
					"points": points,
					"message": "Yanlış ihbar! Geçerli bir işlemi ihbar ettiniz.",
					"penalty": 100
				}
				WarningSystem.issue_procedural_error("Haksız ihbar")
	
	record_decision(decision_type, banknote, correct, points)
	
	if correct:
		correct_decisions += 1
		correct_decision.emit(_get_decision_name(decision_type), points)
	else:
		wrong_decisions += 1
		wrong_decision.emit(_get_decision_name(decision_type), abs(points))
	
	decision_made.emit(_get_decision_name(decision_type), banknote, result)
	
	return result

func record_decision(decision_type: DecisionType, banknote: Dictionary, correct: bool, points: int) -> void:
	var record = {
		"type": decision_type,
		"type_name": _get_decision_name(decision_type),
		"banknote": banknote,
		"correct": correct,
		"points": points,
		"timestamp": Time.get_ticks_msec()
	}
	decisions_today.append(record)
	total_decisions += 1

func get_accuracy() -> float:
	if total_decisions == 0:
		return 0.0
	return float(correct_decisions) / float(total_decisions)

func get_decisions_today() -> Array:
	return decisions_today

func get_total_decisions() -> int:
	return total_decisions

func get_correct_decisions() -> int:
	return correct_decisions

func get_wrong_decisions() -> int:
	return wrong_decisions

func _get_decision_name(decision_type: DecisionType) -> String:
	match decision_type:
		DecisionType.ACCEPT:
			return "Kabul"
		DecisionType.REJECT:
			return "Reddet"
		DecisionType.REPORT:
			return "İhbar"
		_:
			return "Bilinmiyor"

func _on_day_started(_day_number: int) -> void:
	decisions_today.clear()
