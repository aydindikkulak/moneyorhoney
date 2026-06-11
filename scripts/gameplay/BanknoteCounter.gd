extends Node

signal batch_started(count: int)
signal banknote_processed(index: int, total: int)
signal batch_completed(results: Dictionary)
signal suspicious_flagged(index: int, reason: String)

var current_batch: Array = []
var batch_results: Array = []
var is_processing: bool = false
var current_index: int = 0

func _ready():
	print("BanknoteCounter initialized")

func start_batch(banknotes: Array) -> void:
	current_batch = banknotes
	batch_results.clear()
	current_index = 0
	is_processing = true
	batch_started.emit(current_batch.size())
	print("Started processing batch of ", current_batch.size(), " banknotes")

func process_next_banknote() -> Dictionary:
	if current_index >= current_batch.size():
		complete_batch()
		return {}
	
	var banknote = current_batch[current_index]
	var result = analyze_banknote(banknote)
	
	batch_results.append(result)
	banknote_processed.emit(current_index + 1, current_batch.size())
	current_index += 1
	
	return result

func analyze_banknote(banknote: Dictionary) -> Dictionary:
	var suspicion_score = 0.0
	var issues = []
	
	if banknote.get("is_fake", false):
		suspicion_score += 0.8
		issues.append("Sahte para tespit edildi")
	
	if banknote.get("weight_anomaly", false):
		suspicion_score += 0.3
		issues.append("Ağırlık anormalliği")
	
	if banknote.get("size_issue", false):
		suspicion_score += 0.2
		issues.append("Boyut sorunu")
	
	if banknote.get("color_issue", false):
		suspicion_score += 0.2
		issues.append("Renk sorunu")
	
	if banknote.get("uv_response", false) == false:
		suspicion_score += 0.4
		issues.append("UV yanıtı yok")
	
	if banknote.get("serial_valid", false) == false:
		suspicion_score += 0.5
		issues.append("Geçersiz seri no")
	
	var is_suspicious = suspicion_score >= 0.5
	var decision = "accept"
	
	if is_suspicious:
		decision = "flag"
		suspicious_flagged.emit(current_index, ", ".join(issues))
	
	return {
		"banknote": banknote,
		"suspicion_score": suspicion_score,
		"issues": issues,
		"is_suspicious": is_suspicious,
		"decision": decision,
		"processed": true
	}

func manual_decision(index: int, decision: String) -> void:
	if index >= 0 and index < batch_results.size():
		batch_results[index]["decision"] = decision
		batch_results[index]["manual_override"] = true

func complete_batch() -> Dictionary:
	is_processing = false
	
	var accepted = 0
	var rejected = 0
	var flagged = 0
	
	for result in batch_results:
		match result["decision"]:
			"accept":
				accepted += 1
			"reject":
				rejected += 1
			"flag":
				flagged += 1
	
	var summary = {
		"total": batch_results.size(),
		"accepted": accepted,
		"rejected": rejected,
		"flagged": flagged,
		"results": batch_results
	}
	
	batch_completed.emit(summary)
	print("Batch completed: ", accepted, " accepted, ", rejected, " rejected, ", flagged, " flagged")
	
	return summary

func get_current_progress() -> Dictionary:
	return {
		"current": current_index,
		"total": current_batch.size(),
		"remaining": current_batch.size() - current_index
	}

func is_batch_complete() -> bool:
	return current_index >= current_batch.size()

func get_batch_results() -> Array:
	return batch_results
