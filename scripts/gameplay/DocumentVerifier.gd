extends Node

signal document_checked(document: Dictionary, is_valid: bool)
signal mismatch_found(details: String)

func _ready():
	pass

func verify_documents(documents: Array, customer_data: Dictionary) -> Dictionary:
	var results: Dictionary = {
		"all_valid": true,
		"documents": [],
		"issues": []
	}
	
	for doc in documents:
		var doc_result = _verify_single_document(doc, customer_data)
		results["documents"].append(doc_result)
		
		if not doc_result["is_valid"]:
			results["all_valid"] = false
			results["issues"].append(doc_result["issue"])
	
	return results

func _verify_single_document(document: Dictionary, customer_data: Dictionary) -> Dictionary:
	var result = {
		"type": document.get("type", "unknown"),
		"is_valid": true,
		"issue": ""
	}
	
	var doc_name = document.get("name", "")
	var customer_name = customer_data.get("name", "")
	if doc_name != customer_name and doc_name != "Belirsiz Sirket":
		result["is_valid"] = false
		result["issue"] = "Isim eslesmiyor: %s vs %s" % [doc_name, customer_name]
		document_checked.emit(document, false)
		mismatch_found.emit(result["issue"])
		return result
	
	var doc_amount = document.get("amount", 0)
	var expected_amount = customer_data.get("amount", 0)
	if doc_amount != expected_amount:
		result["is_valid"] = false
		result["issue"] = "Miktar eslesmiyor: %d vs %d" % [doc_amount, expected_amount]
		document_checked.emit(document, false)
		mismatch_found.emit(result["issue"])
		return result
	
	var doc_currency = document.get("currency", "")
	var expected_currency = customer_data.get("currency", "")
	if doc_currency != expected_currency:
		result["is_valid"] = false
		result["issue"] = "Para birimi eslesmiyor: %s vs %s" % [doc_currency, expected_currency]
		document_checked.emit(document, false)
		mismatch_found.emit(result["issue"])
		return result
	
	document_checked.emit(document, true)
	return result

func check_source_consistency(customer_data: Dictionary) -> Dictionary:
	var result = {
		"is_consistent": true,
		"issues": []
	}
	
	var purpose = customer_data.get("purpose", "")
	var source = customer_data.get("source", "")
	var amount = customer_data.get("amount", 0)
	
	var suspicious_sources = ["Ozel isler", "Bazi yatirimlar", "Arkadasimdan", "Detayini veremem", "Kisisel"]
	if source in suspicious_sources:
		result["is_consistent"] = false
		result["issues"].append("Kaynak belirsiz: " + source)
	
	var suspicious_purposes = ["Aile yardimi", "Borckapanma", "Yatirim getirisi", "Online satis geliri", "Kripto satisi", "Danismanlik ucreti"]
	if purpose in suspicious_purposes:
		result["is_consistent"] = false
		result["issues"].append("Supheli islem amaci: " + purpose)
	
	if amount > 10000:
		result["is_consistent"] = false
		result["issues"].append("Buyuk miktar: %d" % amount)
	
	return result

func check_money_laundering_indicators(customer_data: Dictionary) -> Dictionary:
	var indicators: Array = []
	var risk_score = 0.0
	
	var amount = customer_data.get("amount", 0)
	if amount > 5000:
		indicators.append("Yuksek miktar")
		risk_score += 0.3
	
	var source = customer_data.get("source", "")
	var suspicious_sources = ["Ozel isler", "Bazi yatirimlar", "Arkadasimdan", "Detayini veremem", "Kisisel"]
	if source in suspicious_sources:
		indicators.append("Belirsiz kaynak")
		risk_score += 0.3
	
	var documents = customer_data.get("documents", [])
	for doc in documents:
		if not doc.get("is_valid", true):
			indicators.append("Gecersiz belge")
			risk_score += 0.2
	
	var consistency = customer_data.get("consistency_score", 1.0)
	if consistency < 0.5:
		indicators.append("Dusuk tutarlilik")
		risk_score += 0.2
	
	var type = customer_data.get("type", 0)
	if type == 2 or type == 3:
		risk_score += 0.2
	
	return {
		"risk_score": clampf(risk_score, 0.0, 1.0),
		"indicators": indicators,
		"is_likely_laundering": risk_score >= 0.6
	}
