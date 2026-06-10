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
	
	# 1. Miktar kontrolü
	var amount = customer_data.get("amount", 0)
	var currency = customer_data.get("currency", "USD")
	var threshold = _get_amount_threshold(currency)
	
	if amount > threshold * 2:
		indicators.append("Cok yuksek miktar: %d %s" % [amount, currency])
		risk_score += 0.4
	elif amount > threshold:
		indicators.append("Yuksek miktar: %d %s" % [amount, currency])
		risk_score += 0.2
	
	# 2. Kaynak kontrolü
	var source = customer_data.get("source", "")
	var source_risk = _analyze_source_risk(source)
	if source_risk > 0:
		indicators.append("Kaynak riski: " + source)
		risk_score += source_risk
	
	# 3. Belge kontrolü
	var documents = customer_data.get("documents", [])
	var doc_issues = _check_document_patterns(documents, customer_data)
	if doc_issues.size() > 0:
		indicators.append_array(doc_issues)
		risk_score += doc_issues.size() * 0.15
	
	# 4. Tutarlılık analizi
	var consistency = customer_data.get("consistency_score", 1.0)
	if consistency < 0.3:
		indicators.append("Cok dusuk tutarlilik")
		risk_score += 0.3
	elif consistency < 0.5:
		indicators.append("Dusuk tutarlilik")
		risk_score += 0.2
	elif consistency < 0.7:
		indicators.append("Orta tutarlilik")
		risk_score += 0.1
	
	# 5. Müşteri tipi analizi
	var type = customer_data.get("type", 0)
	if type == 3:  # Professional
		risk_score += 0.3
		indicators.append("Profesyonel musteri profili")
	elif type == 2:  # Suspicious
		risk_score += 0.2
		indicators.append("Supheli musteri profili")
	
	# 6. Davranışsal analiz
	var mood = customer_data.get("mood", "normal")
	if mood == "nervous":
		risk_score += 0.1
		indicators.append("Gergin davranis")
	
	# 7. İşlem amacı kontrolü
	var purpose = customer_data.get("purpose", "")
	var purpose_risk = _analyze_purpose_risk(purpose, amount)
	if purpose_risk > 0:
		indicators.append("Supheli islem amaci: " + purpose)
		risk_score += purpose_risk
	
	# 8. Yapısal analiz (structuring)
	if _is_structuring_pattern(amount, threshold):
		indicators.append("Yapilandirma deseni tespit edildi")
		risk_score += 0.25
	
	return {
		"risk_score": clampf(risk_score, 0.0, 1.0),
		"indicators": indicators,
		"is_likely_laundering": risk_score >= 0.6,
		"risk_level": _get_risk_level(risk_score)
	}

func _get_amount_threshold(currency: String) -> int:
	match currency:
		"USD": return 10000
		"EUR": return 9000
		"GBP": return 8000
		_: return 10000

func _analyze_source_risk(source: String) -> float:
	var high_risk = ["Nakit satis", "Kumar kazanci", "Miras (belgesiz)", "Yurtdisi transfer"]
	var medium_risk = ["Ozel isler", "Bazi yatirimlar", "Arkadasimdan", "Kisisel"]
	
	if source in high_risk:
		return 0.4
	elif source in medium_risk:
		return 0.2
	return 0.0

func _check_document_patterns(documents: Array, customer_data: Dictionary) -> Array:
	var issues = []
	
	if documents.size() == 0:
		issues.append("Belge eksik")
		return issues
	
	for doc in documents:
		# Tarih kontrolü
		var doc_date = doc.get("date", "")
		if _is_date_suspicious(doc_date):
			issues.append("Supheli belge tarihi: " + doc_date)
		
		# Miktar tutarsızlığı
		var doc_amount = doc.get("amount", 0)
		var customer_amount = customer_data.get("amount", 0)
		if abs(doc_amount - customer_amount) > customer_amount * 0.1:
			issues.append("Belge ve islem miktari arasinda buyuk fark")
		
		# Belge tipi kontrolü
		var doc_type = doc.get("type", "")
		if doc_type == "invoice" and not doc.get("has_tax_number", false):
			issues.append("Faturada vergi numarasi eksik")
	
	return issues

func _is_date_suspicious(date: String) -> bool:
	if date.length() < 10:
		return true
	
	# Geçmiş tarih kontrolü
	var year = date.substr(0, 4).to_int()
	if year < 2020 or year > 2026:
		return true
	
	return false

func _analyze_purpose_risk(purpose: String, amount: int) -> float:
	var high_risk_purposes = ["Yatirim", "Ticaret", "Danismanlik"]
	var medium_risk_purposes = ["Aile yardimi", "Borc odemesi"]
	
	if purpose in high_risk_purposes and amount > 5000:
		return 0.3
	elif purpose in medium_risk_purposes and amount > 3000:
		return 0.15
	return 0.0

func _is_structuring_pattern(amount: int, threshold: int) -> bool:
	# Structuring: 10.000$ altındaki işlemlerle raporlamadan kaçınma
	return amount >= threshold * 0.8 and amount < threshold

func _get_risk_level(risk_score: float) -> String:
	if risk_score >= 0.8:
		return "CRITICAL"
	elif risk_score >= 0.6:
		return "HIGH"
	elif risk_score >= 0.4:
		return "MEDIUM"
	elif risk_score >= 0.2:
		return "LOW"
	return "MINIMAL"

func get_laundering_report(customer_data: Dictionary) -> Dictionary:
	var analysis = check_money_laundering_indicators(customer_data)
	var doc_check = verify_documents(customer_data.get("documents", []), customer_data)
	var source_check = check_source_consistency(customer_data)
	
	return {
		"customer_name": customer_data.get("name", ""),
		"amount": customer_data.get("amount", 0),
		"currency": customer_data.get("currency", ""),
		"risk_assessment": analysis,
		"document_validation": doc_check,
		"source_consistency": source_check,
		"recommendation": _generate_recommendation(analysis, doc_check, source_check)
	}

func _generate_recommendation(laundering: Dictionary, documents: Dictionary, source: Dictionary) -> String:
	var risk = laundering.get("risk_score", 0.0)
	var has_doc_issues = not documents.get("all_valid", true)
	var has_source_issues = not source.get("is_consistent", true)
	
	if risk >= 0.8:
		return "RED - Yuksek kara para riski, rapor edilmeli"
	elif risk >= 0.6 or (has_doc_issues and has_source_issues):
		return "ORANGE - Supheli islem, ek inceleme gerekli"
	elif risk >= 0.4 or has_doc_issues or has_source_issues:
		return "YELLOW - Dikkatli olunmali, belgeler kontrol edilmeli"
	else:
		return "GREEN - Normal islem, onaylanabilir"
