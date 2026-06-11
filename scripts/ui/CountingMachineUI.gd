extends Control

signal counting_completed(results: Dictionary)

@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel
@onready var currency_label: Label = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/CurrencyLabel
@onready var amount_label: Label = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/AmountLabel
@onready var serial_label: Label = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/SerialLabel
@onready var suspicion_bar: ProgressBar = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/SuspicionBar
@onready var suspicion_label: Label = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/SuspicionLabel
@onready var findings_label: Label = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/InfoVBox/FindingsLabel
@onready var banknote_image: TextureRect = $MarginContainer/VBoxContainer/BanknoteDisplay/HBoxContainer/BanknoteImage
@onready var accept_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/AcceptButton
@onready var reject_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/RejectButton
@onready var flag_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/FlagButton
@onready var summary_panel: PanelContainer = $MarginContainer/VBoxContainer/SummaryPanel
@onready var total_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/TotalLabel
@onready var accepted_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/AcceptedLabel
@onready var rejected_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/RejectedLabel
@onready var flagged_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/FlaggedLabel
@onready var continue_button: Button = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/ContinueButton

var banknote_counter: Node
var current_batch: Array = []

func _ready():
	accept_button.pressed.connect(_on_accept_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	flag_button.pressed.connect(_on_flag_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	
	banknote_counter = preload("res://scripts/gameplay/BanknoteCounter.gd").new()
	add_child(banknote_counter)
	
	banknote_counter.batch_started.connect(_on_batch_started)
	banknote_counter.banknote_processed.connect(_on_banknote_processed)
	banknote_counter.batch_completed.connect(_on_batch_completed)
	banknote_counter.suspicious_flagged.connect(_on_suspicious_flagged)
	
	hide_buttons()
	summary_panel.visible = false

func start_counting(banknotes: Array) -> void:
	current_batch = banknotes
	banknote_counter.start_batch(banknotes)
	summary_panel.visible = false
	show_buttons()

func _on_batch_started(count: int) -> void:
	progress_label.text = "İşleniyor: 0/%d" % count

func _on_banknote_processed(index: int, total: int) -> void:
	progress_label.text = "İşleniyor: %d/%d" % [index, total]
	
	var result = banknote_counter.get_batch_results()[-1]
	display_banknote(result)

func display_banknote(result: Dictionary) -> void:
	var banknote = result["banknote"]
	
	currency_label.text = "Para Birimi: %s" % banknote.get("currency", "-")
	amount_label.text = "Miktar: %d" % banknote.get("amount", 0)
	serial_label.text = "Seri No: %s" % banknote.get("serial_number", "-")
	
	var suspicion = result["suspicion_score"] * 100
	suspicion_bar.value = suspicion
	suspicion_label.text = "Şüphelilik: %d%%" % int(suspicion)
	
	var issues = result["issues"]
	if issues.size() > 0:
		findings_label.text = "Bulgular:\n" + "\n".join(issues)
	else:
		findings_label.text = "Bulgular: Sorun bulunamadı"
	
	if banknote.has("texture"):
		banknote_image.texture = banknote["texture"]

func _on_accept_pressed() -> void:
	var index = banknote_counter.current_index - 1
	banknote_counter.manual_decision(index, "accept")
	process_next()

func _on_reject_pressed() -> void:
	var index = banknote_counter.current_index - 1
	banknote_counter.manual_decision(index, "reject")
	process_next()

func _on_flag_pressed() -> void:
	var index = banknote_counter.current_index - 1
	banknote_counter.manual_decision(index, "flag")
	WarningSystem.issue_procedural_error("Şüpheli banknot ihbar edildi")
	process_next()

func process_next() -> void:
	if banknote_counter.is_batch_complete():
		banknote_counter.complete_batch()
	else:
		var result = banknote_counter.process_next_banknote()
		if result.size() > 0:
			display_banknote(result)

func _on_batch_completed(results: Dictionary) -> void:
	hide_buttons()
	show_summary(results)
	counting_completed.emit(results)

func show_summary(results: Dictionary) -> void:
	total_label.text = "Toplam: %d" % results["total"]
	accepted_label.text = "Kabul: %d" % results["accepted"]
	rejected_label.text = "Red: %d" % results["rejected"]
	flagged_label.text = "İhbar: %d" % results["flagged"]
	summary_panel.visible = true

func _on_continue_pressed() -> void:
	summary_panel.visible = false

func _on_suspicious_flagged(index: int, reason: String) -> void:
	print("Şüpheli banknot #%d: %s" % [index, reason])

func show_buttons() -> void:
	accept_button.visible = true
	reject_button.visible = true
	flag_button.visible = true

func hide_buttons() -> void:
	accept_button.visible = false
	reject_button.visible = false
	flag_button.visible = false
