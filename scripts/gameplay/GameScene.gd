extends Control

const CustomerAI = preload("res://scripts/gameplay/CustomerAI.gd")
const CurrencyInspector = preload("res://scripts/gameplay/CurrencyInspector.gd")
const ToolSystem = preload("res://scripts/gameplay/ToolSystem.gd")
const DocumentVerifier = preload("res://scripts/gameplay/DocumentVerifier.gd")

@onready var customer_name_label: Label = $CustomerArea/VBoxContainer/CustomerNameLabel
@onready var customer_sprite: TextureRect = $CustomerArea/VBoxContainer/CustomerSprite
@onready var mood_label: Label = $CustomerArea/VBoxContainer/MoodLabel
@onready var purpose_label: Label = $CustomerArea/VBoxContainer/PurposeLabel
@onready var source_label: Label = $CustomerArea/VBoxContainer/SourceLabel
@onready var amount_label: Label = $CustomerArea/VBoxContainer/AmountLabel
@onready var response_label: Label = $CustomerArea/VBoxContainer/ResponseLabel
@onready var ask_source_btn: Button = $CustomerArea/VBoxContainer/DialogContainer/AskSourceButton
@onready var ask_purpose_btn: Button = $CustomerArea/VBoxContainer/DialogContainer/AskPurposeButton
@onready var ask_frequency_btn: Button = $CustomerArea/VBoxContainer/DialogContainer/AskFrequencyButton

@onready var document_panel: PanelContainer = $DocumentPanel
@onready var doc_title_label: Label = $DocumentPanel/VBoxContainer/DocTitleLabel
@onready var doc_content_label: Label = $DocumentPanel/VBoxContainer/DocContentLabel
@onready var doc_texture_rect: TextureRect = $DocumentPanel/VBoxContainer/DocTextureRect

@onready var banknote_title: Label = $InspectionArea/VBoxContainer/BanknoteTitle
@onready var banknote_display: ColorRect = $InspectionArea/VBoxContainer/BanknoteDisplay
@onready var uv_overlay: ColorRect = $InspectionArea/VBoxContainer/BanknoteDisplay/UVOverlay
@onready var serial_label: Label = $InspectionArea/VBoxContainer/SerialLabel
@onready var findings_list: Label = $InspectionArea/VBoxContainer/FindingsContainer/FindingsList
@onready var suspicion_bar: ProgressBar = $InspectionArea/VBoxContainer/SuspicionBar
@onready var suspicion_label: Label = $InspectionArea/VBoxContainer/SuspicionLabel

@onready var magnifier_btn: Button = $ToolPanel/HBoxContainer/MagnifierButton
@onready var uv_lamp_btn: Button = $ToolPanel/HBoxContainer/UVLampButton
@onready var scale_btn: Button = $ToolPanel/HBoxContainer/ScaleButton
@onready var microscope_btn: Button = $ToolPanel/HBoxContainer/MicroscopeButton

@onready var visual_check_btn: Button = $DecisionPanel/VBoxContainer/VisualCheckButton
@onready var accept_btn: Button = $DecisionPanel/VBoxContainer/AcceptButton
@onready var reject_btn: Button = $DecisionPanel/VBoxContainer/RejectButton
@onready var customer_count_label: Label = $DecisionPanel/VBoxContainer/CustomerCountLabel

@onready var day_end_report: Control = $DayEndReport
@onready var level_intro_panel: Control = $LevelIntroPanel
@onready var level_name_label: Label = $LevelIntroPanel/Panel/VBox/LevelNameLabel
@onready var description_label: Label = $LevelIntroPanel/Panel/VBox/DescriptionLabel
@onready var info_label: Label = $LevelIntroPanel/Panel/VBox/InfoLabel
@onready var start_day_btn: Button = $LevelIntroPanel/Panel/VBox/StartDayButton

var customer_ai
var currency_inspector
var tool_system
var document_verifier

var current_customer_index: int = 0
var total_customers: int = 0
var customers_data: Array = []
var is_processing_customer: bool = false

func _ready():
	customer_ai = CustomerAI.new()
	add_child(customer_ai)
	
	currency_inspector = CurrencyInspector.new()
	add_child(currency_inspector)
	
	tool_system = ToolSystem.new()
	add_child(tool_system)
	
	document_verifier = DocumentVerifier.new()
	add_child(document_verifier)
	
	_connect_signals()
	_setup_ui()
	
	GameManager.start_game()
	_show_level_intro()

func _connect_signals():
	ask_source_btn.pressed.connect(_on_ask_source)
	ask_purpose_btn.pressed.connect(_on_ask_purpose)
	ask_frequency_btn.pressed.connect(_on_ask_frequency)
	
	visual_check_btn.pressed.connect(_on_visual_check)
	accept_btn.pressed.connect(_on_accept)
	reject_btn.pressed.connect(_on_reject)
	
	magnifier_btn.pressed.connect(_on_magnifier)
	uv_lamp_btn.pressed.connect(_on_uv_lamp)
	scale_btn.pressed.connect(_on_scale)
	microscope_btn.pressed.connect(_on_microscope)
	
	start_day_btn.pressed.connect(_on_start_day)
	
	day_end_report.day_complete.connect(_on_day_complete)
	day_end_report.retry_requested.connect(_on_retry_day)

func _on_customer_arrived(customer_data: Dictionary):
	_display_customer(customer_data)

func _setup_ui():
	var level = GameManager.current_level
	tool_system.setup_tools(level)
	
	var tools = LevelManager.get_available_tools(level)
	magnifier_btn.visible = "magnifier" in tools
	uv_lamp_btn.visible = "uv_lamp" in tools
	scale_btn.visible = "scale" in tools
	microscope_btn.visible = "microscope" in tools
	
	# Load tool icons
	_load_tool_icon(magnifier_btn, "magnifier")
	_load_tool_icon(uv_lamp_btn, "uv_lamp")
	_load_tool_icon(scale_btn, "scale")
	_load_tool_icon(microscope_btn, "microscope")
	
	document_panel.visible = LevelManager.has_documents(level)

func _load_tool_icon(button: Button, tool_name: String):
	var texture = CurrencyDatabase.load_tool_texture(tool_name)
	if texture:
		var icon_image = texture.get_image()
		if icon_image:
			icon_image.resize(24, 24, Image.INTERPOLATE_NEAREST)
			var resized_texture = ImageTexture.create_from_image(icon_image)
			button.icon = resized_texture
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _show_level_intro():
	var level_data = LevelManager.get_level_data(GameManager.current_level)
	level_name_label.text = "Seviye %d: %s" % [GameManager.current_level, level_data.get("name", "")]
	description_label.text = level_data.get("description", "")
	
	var currencies = level_data.get("currencies", [])
	var tools = level_data.get("tools", [])
	var info_text = "Para birimleri: " + ", ".join(currencies)
	if tools.size() > 0:
		info_text += "\nAletler: " + ", ".join(tools)
	if level_data.get("has_documents", false):
		info_text += "\nBelge kontrolu aktif"
	if level_data.get("has_money_laundering", false):
		info_text += "\nKara para tespiti aktif"
	info_label.text = info_text
	
	level_intro_panel.visible = true

func _on_start_day():
	level_intro_panel.visible = false
	_start_day()

func _start_day():
	current_customer_index = 0
	total_customers = LevelManager.get_customer_count(GameManager.current_level)
	_generate_customers()
	_next_customer()

func _generate_customers():
	customers_data.clear()
	var level = GameManager.current_level
	var fake_count = LevelManager.get_fake_count(level)
	var customer_count = LevelManager.get_customer_count(level)
	
	for i in range(customer_count):
		var customer_type = -1
		if i < fake_count:
			customer_type = 2 if randf() > 0.3 else 3
		var customer = customer_ai.generate_customer(level, customer_type)
		customers_data.append(customer)

func _next_customer():
	if current_customer_index >= total_customers:
		_end_day()
		return
	
	is_processing_customer = true
	var customer = customers_data[current_customer_index]
	_display_customer(customer)
	current_customer_index += 1
	customer_count_label.text = "Musteri: %d/%d" % [current_customer_index, total_customers]

func _display_customer(customer: Dictionary):
	customer_name_label.text = "Musteri: %s" % customer.get("name", "")
	mood_label.text = "Ruh Hali: %s" % customer.get("mood", "normal")
	purpose_label.text = "Islem Amaci: %s" % customer.get("purpose", "")
	source_label.text = "Kaynak: %s" % customer.get("source", "")
	amount_label.text = "Miktar: %s %d" % [customer.get("currency", ""), customer.get("amount", 0)]
	response_label.text = ""
	
	# Load customer NPC sprite
	var npc_type = _get_npc_type_from_mood(customer.get("mood", "normal"))
	var npc_variant = customer.get("sprite_index", 0) % 3
	var npc_texture = CurrencyDatabase.load_npc_texture(npc_type, npc_variant)
	if npc_texture:
		customer_sprite.texture = npc_texture
	
	var banknote = customer.get("banknote", {})
	var currency = banknote.get("currency", "")
	var denomination = banknote.get("denomination", 0)
	var serial = banknote.get("serial_number", "")
	var is_fake = banknote.get("is_fake", false)
	
	banknote_title.text = "%s %d" % [currency, denomination]
	serial_label.text = "Seri No: %s" % serial
	
	# Load banknote sprite
	var banknote_texture = CurrencyDatabase.load_banknote_texture(currency, denomination, is_fake)
	if banknote_texture:
		var banknote_sprite_node = banknote_display.get_node_or_null("BanknoteSprite")
		if banknote_sprite_node:
			banknote_sprite_node.texture = banknote_texture
	
	findings_list.text = ""
	suspicion_bar.value = 0
	suspicion_label.text = "Suphe: 0%"
	
	currency_inspector.start_inspection(customer)
	
	var documents = customer.get("documents", [])
	if documents.size() > 0 and LevelManager.has_documents(GameManager.current_level):
		_display_documents(documents, customer)
		document_panel.visible = true
	else:
		document_panel.visible = false

func _display_documents(documents: Array, customer: Dictionary):
	var doc_text = ""
	for doc in documents:
		doc_text += "Tip: %s\n" % doc.get("type", "")
		doc_text += "Isim: %s\n" % doc.get("name", "")
		doc_text += "Miktar: %s %d\n" % [doc.get("currency", ""), doc.get("amount", 0)]
		doc_text += "Tarih: %s\n" % doc.get("date", "")
		if doc.has("note"):
			doc_text += "Not: %s\n" % doc.get("note", "")
		doc_text += "\n"
	doc_content_label.text = doc_text
	
	# Load document texture (show first document)
	if documents.size() > 0:
		var first_doc = documents[0]
		var doc_type = first_doc.get("type", "invoice")
		var variant = randi() % 3
		var doc_texture = CurrencyDatabase.load_document_texture(doc_type, variant)
		if doc_texture:
			doc_texture_rect.texture = doc_texture

func _on_ask_source():
	var response = customer_ai.respond_to_question("source")
	response_label.text = "Kaynak: " + response

func _on_ask_purpose():
	var response = customer_ai.respond_to_question("purpose")
	response_label.text = "Islem Amaci: " + response

func _on_ask_frequency():
	var response = customer_ai.respond_to_question("frequency")
	response_label.text = "Siklik: " + response

func _on_visual_check():
	var findings = currency_inspector.perform_visual_check()
	_display_findings(findings)

func _on_magnifier():
	var result = currency_inspector.use_tool_on_banknote(1)
	_display_findings(result)
	uv_overlay.visible = false

func _on_uv_lamp():
	var result = currency_inspector.use_tool_on_banknote(2)
	_display_findings(result)
	uv_overlay.visible = true
	await get_tree().create_timer(2.0).timeout
	uv_overlay.visible = false

func _on_scale():
	var result = currency_inspector.use_tool_on_banknote(3)
	_display_findings(result)

func _on_microscope():
	var result = currency_inspector.use_tool_on_banknote(4)
	_display_findings(result)

func _display_findings(findings: Dictionary):
	var text = ""
	
	# Görsel kontrol sonuçları
	if findings.has("color_issue"):
		if findings["color_issue"]:
			text += "[!] Renk tonu farkli\n"
		else:
			text += "[OK] Renk normal\n"
	if findings.has("size_issue"):
		if findings["size_issue"]:
			text += "[!] Boyut sapmasi var\n"
		else:
			text += "[OK] Boyut normal\n"
	if findings.has("serial_valid"):
		if not findings["serial_valid"]:
			text += "[!] Seri numarasi gecersiz\n"
		else:
			text += "[OK] Seri numarasi gecerli\n"
	if findings.has("uv_response"):
		if not findings["uv_response"]:
			text += "[!] UV yaniti yok\n"
		else:
			text += "[OK] UV yaniti normal\n"
	if findings.has("weight_anomaly"):
		if findings["weight_anomaly"]:
			text += "[!] Agirlik sapmasi var\n"
		else:
			text += "[OK] Agirlik normal\n"
	if findings.has("micro_printing"):
		if not findings["micro_printing"]:
			text += "[!] Mikro yazilar eksik\n"
		else:
			text += "[OK] Mikro yazilar mevcut\n"
	
	# Belge kontrol sonuçları
	if not currency_inspector.document_findings.is_empty():
		text += "\n--- BELGE KONTROLU ---\n"
		if currency_inspector.document_findings.get("all_valid", true):
			text += "[OK] Belgeler gecerli\n"
		else:
			var issues = currency_inspector.document_findings.get("issues", [])
			for issue in issues:
				text += "[!] " + issue + "\n"
	
	# Kara para kontrol sonuçları
	if not currency_inspector.laundering_findings.is_empty():
		var risk_score = currency_inspector.laundering_findings.get("risk_score", 0.0)
		if risk_score > 0.3:
			text += "\n--- KARA PARA RISKI ---\n"
			var indicators = currency_inspector.laundering_findings.get("indicators", [])
			for indicator in indicators:
				text += "[!] " + indicator + "\n"
	
	findings_list.text = text
	
	var suspicion = currency_inspector.get_suspicion_level()
	suspicion_bar.value = suspicion * 100
	suspicion_label.text = "Suphe: %d%%" % int(suspicion * 100)

func _get_npc_type_from_mood(mood: String) -> String:
	match mood:
		"normal":
			return "normal"
		"distracted":
			return "careless"
		"nervous":
			return "suspicious"
		"confident":
			return "professional"
		_:
			return "normal"

func _on_accept():
	if not is_processing_customer:
		return
	
	var decision = currency_inspector.make_decision()
	var is_fake = decision.get("is_fake", false)
	var is_money_laundering = decision.get("is_money_laundering", false)
	
	var is_correct = not is_fake and not is_money_laundering
	var amount = customer_ai.current_customer.get("amount", 0)
	
	if is_correct:
		ScoringSystem.add_correct_decision()
		ScoringSystem.add_money(amount)
		GameManager.make_decision(true, amount)
	else:
		ScoringSystem.add_wrong_decision()
		GameManager.make_decision(false, amount)
	
	_show_decision_feedback(true)
	is_processing_customer = false
	
	await get_tree().create_timer(1.5).timeout
	_next_customer()

func _on_reject():
	if not is_processing_customer:
		return
	
	var decision = currency_inspector.make_decision()
	var is_fake = decision.get("is_fake", false)
	var is_money_laundering = decision.get("is_money_laundering", false)
	
	var is_correct = is_fake or is_money_laundering
	var amount = customer_ai.current_customer.get("amount", 0)
	
	if is_correct:
		ScoringSystem.add_correct_decision(150)
		GameManager.make_decision(true, 0)
	else:
		ScoringSystem.add_wrong_decision()
		ScoringSystem.subtract_money(amount)
		GameManager.make_decision(false, amount)
	
	_show_decision_feedback(false)
	is_processing_customer = false
	
	await get_tree().create_timer(1.5).timeout
	_next_customer()

func _show_decision_feedback(was_accepted: bool):
	var hud = $HUD
	if hud and hud.has_method("show_decision_feedback"):
		var decision = currency_inspector.make_decision()
		var is_fake = decision.get("is_fake", false)
		var is_money_laundering = decision.get("is_money_laundering", false)
		var should_reject = is_fake or is_money_laundering
		
		var is_correct = (was_accepted and not should_reject) or (not was_accepted and should_reject)
		hud.show_decision_feedback(is_correct)

func _end_day():
	GameManager.end_day()
	day_end_report.visible = true

func _on_day_complete():
	day_end_report.visible = false
	if GameManager.current_state == GameManager.GameState.GAME_OVER:
		day_end_report.show_game_over()
	else:
		_show_level_intro()

func _on_retry_day():
	day_end_report.visible = false
	_start_day()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_magnifier()
			KEY_2:
				_on_uv_lamp()
			KEY_3:
				_on_scale()
			KEY_4:
				_on_microscope()
			KEY_SPACE:
				_on_accept()
			KEY_ESCAPE:
				_on_reject()
