extends Node

signal warning_issued(warning_type: String, reason: String)
signal warning_count_changed(count: int)
signal game_over_triggered(reason: String)
signal audit_started
signal complaint_received(customer_name: String)

const MAX_WARNINGS = 3

enum WarningType {
	AUDIT,
	COMPLAINT,
	PROCEDURAL_ERROR
}

var warnings: Array = []
var warning_count: int = 0
var audit_active: bool = false
var audit_timer: float = 0.0
var audit_duration: float = 30.0
var complaints_today: int = 0

func _ready():
	WeekCycleSystem.day_started.connect(_on_day_started)
	print("WarningSystem initialized")

func _process(delta):
	if audit_active:
		audit_timer -= delta
		if audit_timer <= 0:
			end_audit()

func start_new_game():
	warnings.clear()
	warning_count = 0
	audit_active = false
	complaints_today = 0

func issue_warning(warning_type: WarningType, reason: String) -> Dictionary:
	var warning = {
		"type": warning_type,
		"reason": reason,
		"week": WeekCycleSystem.get_current_week(),
		"day": WeekCycleSystem.get_current_day(),
		"timestamp": Time.get_ticks_msec()
	}
	
	warnings.append(warning)
	warning_count += 1
	warning_issued.emit(_get_warning_type_name(warning_type), reason)
	warning_count_changed.emit(warning_count)
	
	print("Warning issued: ", reason, " (", warning_count, "/", MAX_WARNINGS, ")")
	
	if warning_count >= MAX_WARNINGS:
		trigger_game_over("Çok fazla uyarı aldınız! (" + str(warning_count) + "/" + str(MAX_WARNINGS) + ")")
	
	return warning

func trigger_audit(reason: String = "Rutin denetim"):
	audit_active = true
	audit_timer = audit_duration
	audit_started.emit()
	print("Audit started: ", reason)
	
	var warning = issue_warning(WarningType.AUDIT, reason)
	return warning

func receive_complaint(customer_name: String, reason: String = ""):
	complaints_today += 1
	complaint_received.emit(customer_name)
	print("Complaint received from: ", customer_name)
	
	var warning = issue_warning(WarningType.COMPLAINT, "Müşteri şikayeti: " + customer_name)
	return warning

func issue_procedural_error(reason: String):
	var warning = issue_warning(WarningType.PROCEDURAL_ERROR, reason)
	return warning

func end_audit():
	audit_active = false
	print("Audit ended")

func is_audit_active() -> bool:
	return audit_active

func get_audit_time_remaining() -> float:
	return max(0, audit_timer)

func get_warning_count() -> int:
	return warning_count

func get_warnings_remaining() -> int:
	return MAX_WARNINGS - warning_count

func get_warnings() -> Array:
	return warnings

func get_complaints_today() -> int:
	return complaints_today

func can_continue() -> bool:
	return warning_count < MAX_WARNINGS

func trigger_game_over(reason: String):
	print("GAME OVER: ", reason)
	game_over_triggered.emit(reason)

func _get_warning_type_name(warning_type: WarningType) -> String:
	match warning_type:
		WarningType.AUDIT:
			return "Denetim"
		WarningType.COMPLAINT:
			return "Şikayet"
		WarningType.PROCEDURAL_ERROR:
			return "Prosedür Hatası"
		_:
			return "Bilinmiyor"

func _on_day_started(_day_number: int):
	complaints_today = 0
