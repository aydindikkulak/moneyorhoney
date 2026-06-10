extends Node

signal customer_arrived(customer_data: Dictionary)
signal customer_left(satisfied: bool)
signal dialog_response(response: String)

enum CustomerType {
	NORMAL,
	CARELESS,
	SUSPICIOUS,
	PROFESSIONAL
}

var current_customer: Dictionary = {}
var customer_queue: Array = []
var consistency_score: float = 1.0
var questions_asked: int = 0
var max_questions: int = 3

var customer_names: Array = [
	"John Smith", "Mary Johnson", "Robert Williams", "Patricia Brown",
	"James Jones", "Linda Davis", "Michael Miller", "Elizabeth Wilson",
	"William Moore", "Jennifer Taylor", "David Anderson", "Susan Thomas",
	"Richard Jackson", "Margaret White", "Joseph Harris", "Dorothy Martin",
	"Thomas Garcia", "Lisa Rodriguez", "Charles Martinez", "Nancy Lopez"
]

var transaction_purposes: Array = [
	"Maas odemesi", "Fatura odemesi", "Havale islemi", "Doviz bozdurma",
	"Kredi geri odemesi", "Ticaret odemesi", "Kira odemesi", "Sigorta odemesi",
	"Vergi odemesi", "Egitim odemesi"
]

var suspicious_purposes: Array = [
	"Aile yardimi", "Borckapanma", "Yatirim getirisi", "Online satis geliri",
	"Kripto satisi", "Danismanlik ucreti"
]

var normal_responses: Dictionary = {
	"source": ["Maas", "Sirket kazanci", "Biriktigim para", "Miras", "Satis geliri"],
	"purpose": transaction_purposes,
	"frequency": ["Ilk kez geliyorum", "Ayda bir geliyorum", "Duzenli musteriyim"],
	"amount": ["Tam olarak bu miktar", "Yuvarlak hesap", "Faturadaki tutar"]
}

var suspicious_responses: Dictionary = {
	"source": ["Ozel isler", "Bazi yatirimlar", "Arkadasimdan", "Detayini veremem", "Kisisel"],
	"purpose": suspicious_purposes,
	"frequency": ["Bazen geliyorum", "Cok sik degil", "Hatirlamiyorum"],
	"amount": ["Yaklasik", "Tam emin degilim", "Degisebilir"]
}

func _ready():
	pass

func generate_customer(level: int, customer_type: int = -1) -> Dictionary:
	if customer_type == -1:
		customer_type = _determine_customer_type(level)
	
	var name = customer_names[randi() % customer_names.size()]
	var currencies_available = LevelManager.get_available_currencies(level)
	var currency = currencies_available[randi() % currencies_available.size()]
	var denominations = CurrencyDatabase.get_denominations(currency)
	var denomination = denominations[randi() % denominations.size()]
	
	var amount_multiplier = randi_range(1, 10)
	var amount = denomination * amount_multiplier
	
	var is_fake = false
	var fake_difficulty = LevelManager.get_fake_difficulty(level)
	var fake_chance = _get_fake_chance(fake_difficulty)
	is_fake = randf() < fake_chance
	
	var banknote_data = CurrencyDatabase.generate_banknote_data(
		currency, denomination, is_fake, fake_difficulty
	)
	
	var purpose = ""
	var source = ""
	var documents: Array = []
	var is_money_laundering = false
	
	match customer_type:
		CustomerType.NORMAL:
			purpose = normal_responses["purpose"][randi() % normal_responses["purpose"].size()]
			source = normal_responses["source"][randi() % normal_responses["source"].size()]
			consistency_score = 1.0
			if LevelManager.has_documents(level):
				documents = _generate_valid_documents(name, amount, currency)
		
		CustomerType.CARELESS:
			purpose = normal_responses["purpose"][randi() % normal_responses["purpose"].size()]
			source = normal_responses["source"][randi() % normal_responses["source"].size()]
			consistency_score = randf_range(0.6, 0.8)
			if LevelManager.has_documents(level) and randf() > 0.4:
				documents = _generate_invalid_documents(name, amount, currency)
			elif LevelManager.has_documents(level):
				documents = _generate_valid_documents(name, amount, currency)
		
		CustomerType.SUSPICIOUS:
			purpose = suspicious_purposes[randi() % suspicious_purposes.size()]
			source = suspicious_responses["source"][randi() % suspicious_responses["source"].size()]
			consistency_score = randf_range(0.2, 0.5)
			is_fake = randf() > 0.3
			banknote_data = CurrencyDatabase.generate_banknote_data(
				currency, denomination, is_fake, fake_difficulty
			)
			if LevelManager.has_documents(level):
				documents = _generate_suspicious_documents(name, amount, currency)
			if LevelManager.has_money_laundering(level) and randf() > 0.4:
				is_money_laundering = true
		
		CustomerType.PROFESSIONAL:
			purpose = normal_responses["purpose"][randi() % normal_responses["purpose"].size()]
			source = normal_responses["source"][randi() % normal_responses["source"].size()]
			consistency_score = randf_range(0.8, 0.95)
			is_fake = true
			banknote_data = CurrencyDatabase.generate_banknote_data(
				currency, denomination, true, "professional"
			)
			if LevelManager.has_documents(level):
				documents = _generate_valid_documents(name, amount, currency)
	
	current_customer = {
		"name": name,
		"type": customer_type,
		"currency": currency,
		"denomination": denomination,
		"amount": amount,
		"purpose": purpose,
		"source": source,
		"banknote": banknote_data,
		"documents": documents,
		"is_fake": is_fake,
		"is_money_laundering": is_money_laundering,
		"consistency_score": consistency_score,
		"mood": _get_mood(customer_type),
		"sprite_index": randi() % 10,
		"behavioral_hints": _get_behavioral_hints(customer_type),
		"observation_notes": _get_observation_notes(customer_type, is_money_laundering)
	}
	
	questions_asked = 0
	customer_arrived.emit(current_customer)
	return current_customer

func respond_to_question(question_type: String) -> String:
	questions_asked += 1
	var response = ""
	
	var type = current_customer.get("type", CustomerType.NORMAL)
	
	match type:
		CustomerType.NORMAL, CustomerType.CARELESS:
			var responses = normal_responses.get(question_type, ["Bilmiyorum"])
			response = responses[randi() % responses.size()]
		CustomerType.SUSPICIOUS:
			if randf() < 0.6:
				var responses = suspicious_responses.get(question_type, ["..."])
				response = responses[randi() % responses.size()]
			else:
				var responses = normal_responses.get(question_type, ["Bilmiyorum"])
				response = responses[randi() % responses.size()]
		CustomerType.PROFESSIONAL:
			var responses = normal_responses.get(question_type, ["Bilmiyorum"])
			response = responses[randi() % responses.size()]
			if randf() > 0.8:
				response += "..."
	
	dialog_response.emit(response)
	return response

func is_suspicious() -> bool:
	var type = current_customer.get("type", CustomerType.NORMAL)
	return type == CustomerType.SUSPICIOUS or type == CustomerType.PROFESSIONAL

func get_suspicion_indicators() -> Array:
	var indicators: Array = []
	
	var type = current_customer.get("type", CustomerType.NORMAL)
	if type == CustomerType.SUSPICIOUS:
		indicators.append("Musteri gergin görünüyor")
		indicators.append("Tutarsiz ifadeler")
	elif type == CustomerType.PROFESSIONAL:
		indicators.append("Cok rahat ve hazirlikli")
	
	if current_customer.get("is_money_laundering", false):
		indicators.append("Supheli buyuk miktar")
		indicators.append("Kaynak belirsiz")
	
	if current_customer.get("is_fake", false):
		indicators.append("Para supheli gorunuyor")
	
	return indicators

func _determine_customer_type(level: int) -> int:
	var rand = randf()
	var level_data = LevelManager.get_level_data(level)
	
	var suspicious_chance = float(level_data.get("suspicious_count", 0)) / float(level_data.get("customers_per_day", 5))
	var laundering_chance = float(level_data.get("money_laundering_count", 0)) / float(level_data.get("customers_per_day", 5))
	
	if rand < 0.05 and level >= 4:
		return CustomerType.PROFESSIONAL
	elif rand < suspicious_chance + 0.05:
		return CustomerType.SUSPICIOUS
	elif rand < 0.2:
		return CustomerType.CARELESS
	else:
		return CustomerType.NORMAL

func _get_fake_chance(difficulty: String) -> float:
	match difficulty:
		"easy": return 0.3
		"medium": return 0.35
		"medium_hard": return 0.4
		"hard_professional": return 0.45
		"professional": return 0.5
		_: return 0.3

func _get_mood(type: int) -> String:
	match type:
		CustomerType.NORMAL: return "normal"
		CustomerType.CARELESS: return "distracted"
		CustomerType.SUSPICIOUS: return "nervous"
		CustomerType.PROFESSIONAL: return "confident"
	return "normal"

func _get_behavioral_hints(type: int) -> Array:
	var hints = []
	match type:
		CustomerType.NORMAL:
			hints.append("Rahat ve dogal davranislar")
			hints.append("Net ve tutarli yanitlar")
		CustomerType.CARELESS:
			hints.append("Dikkati daginik gorunuyor")
			hints.append("Bazen tutarsiz ifadeler")
		CustomerType.SUSPICIOUS:
			hints.append("Gergin ve tedirgin")
			hints.append("Goz temasi kurmaktan kaciniyor")
			hints.append("Sorulara hazirliksiz yanitlar")
		CustomerType.PROFESSIONAL:
			hints.append("Asiri rahat ve kendinden emin")
			hints.append("Her seyi onceden planlamis gibi")
			hints.append("Cok detayli ve tutarli hikaye")
	return hints

func _get_observation_notes(type: int, is_money_laundering: bool) -> Array:
	var notes = []
	match type:
		CustomerType.NORMAL:
			notes.append("Normal bir musteri gibi gorunuyor")
		CustomerType.CARELESS:
			notes.append("Belgelerini duzgun tutmamis")
			notes.append("Islem detaylarini tam hatirlamiyor")
		CustomerType.SUSPICIOUS:
			notes.append("Supheli davranislar sergiliyor")
			if is_money_laundering:
				notes.append("Buyuk miktarda nakit getiriyor")
				notes.append("Kaynak konusunda belirsiz")
		CustomerType.PROFESSIONAL:
			notes.append("Cok profesyonel gorunuyor")
			notes.append("Her seyi onceden hazirlamis")
			if is_money_laundering:
				notes.append("Karmaşık bir islem hikayesi anlatiyor")
	return notes

func _generate_valid_documents(name: String, amount: int, currency: String) -> Array:
	return [{
		"type": "invoice",
		"name": name,
		"amount": amount,
		"currency": currency,
		"is_valid": true,
		"date": "2026-06-%02d" % (randi() % 28 + 1)
	}]

func _generate_invalid_documents(name: String, amount: int, currency: String) -> Array:
	var wrong_amount = amount + randi_range(-500, 500)
	if wrong_amount == amount:
		wrong_amount += 100
	return [{
		"type": "invoice",
		"name": name,
		"amount": wrong_amount,
		"currency": currency,
		"is_valid": false,
		"date": "2026-06-%02d" % (randi() % 28 + 1)
	}]

func _generate_suspicious_documents(name: String, amount: int, currency: String) -> Array:
	var docs: Array = []
	if randf() > 0.5:
		docs.append({
			"type": "invoice",
			"name": "Belirsiz Sirket",
			"amount": amount / 2,
			"currency": currency,
			"is_valid": false,
			"date": "2026-06-%02d" % (randi() % 28 + 1)
		})
	else:
		docs.append({
			"type": "receipt",
			"name": name,
			"amount": amount,
			"currency": currency,
			"is_valid": false,
			"date": "2026-06-%02d" % (randi() % 28 + 1),
			"note": "Nakit odeme"
		})
	return docs
