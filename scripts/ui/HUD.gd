extends Control

signal combo_displayed(combo_count: int)
signal achievement_displayed(achievement_name: String)

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var money_label: Label = $TopBar/MoneyLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var streak_label: Label = $TopBar/StreakLabel
@onready var accuracy_label: Label = $TopBar/AccuracyLabel
@onready var multiplier_label: Label = $TopBar/MultiplierLabel
@onready var combo_label: Label = $TopBar/ComboLabel
@onready var customers_served_label: Label = $TopBar/CustomersServedLabel

@onready var decision_feedback: Label = $DecisionFeedback
@onready var combo_popup: Label = $ComboPopup
@onready var achievement_popup: PanelContainer = $AchievementPopup
@onready var achievement_name_label: Label = $AchievementPopup/VBox/AchievementName
@onready var achievement_desc_label: Label = $AchievementPopup/VBox/AchievementDesc

var time_remaining: float = 60.0
var timer_active: bool = false
var decision_start_time: float = 0.0

func _ready():
	ScoringSystem.score_changed.connect(_on_score_changed)
	ScoringSystem.money_changed.connect(_on_money_changed)
	ScoringSystem.combo_activated.connect(_on_combo_activated)
	ScoringSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	GameManager.day_started.connect(_on_day_started)
	
	update_all()
	combo_popup.visible = false
	achievement_popup.visible = false

func _process(delta):
	if timer_active and time_remaining > 0:
		time_remaining -= delta
		update_timer()
		if time_remaining <= 0:
			timer_active = false
			_on_time_expired()

func update_all():
	var stats = ScoringSystem.get_stats()
	score_label.text = "Skor: %d" % stats["score"]
	money_label.text = "Kasa: $%d" % stats["money"]
	level_label.text = "Seviye: %d" % GameManager.current_level
	day_label.text = "Gun: %d" % GameManager.current_day
	streak_label.text = "Seri: %d" % stats["streak"]
	accuracy_label.text = "Dogruluk: %d%%" % (stats["accuracy"] * 100)
	customers_served_label.text = "Musteri: %d/%d" % [stats["total_served"], stats["total_served"] + stats["wrong"]]
	
	if stats["multiplier"] > 1.0:
		multiplier_label.text = "x%.1f" % stats["multiplier"]
		multiplier_label.visible = true
	else:
		multiplier_label.visible = false
	
	if stats["combo"] >= 2:
		combo_label.text = "COMBO x%d" % stats["combo"]
		combo_label.visible = true
	else:
		combo_label.visible = false

func update_timer():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "Sure: %02d:%02d" % [minutes, seconds]
	
	if time_remaining < 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining < 20:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func start_timer(seconds: int):
	time_remaining = seconds
	timer_active = true
	update_timer()

func stop_timer():
	timer_active = false

func start_decision_timer():
	decision_start_time = Time.get_ticks_msec() / 1000.0

func get_decision_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - decision_start_time

func _on_score_changed(new_score: int):
	score_label.text = "Skor: %d" % new_score

func _on_money_changed(new_amount: int):
	money_label.text = "Kasa: $%d" % new_amount

func _on_combo_activated(combo_count: int):
	if combo_count >= 2:
		combo_label.text = "COMBO x%d" % combo_count
		combo_label.visible = true
		_show_combo_popup(combo_count)
	else:
		combo_label.visible = false

func _on_achievement_unlocked(achievement_id: String):
	var achievements = ScoringSystem.get_achievements()
	if achievements.has(achievement_id):
		var achievement = achievements[achievement_id]
		_show_achievement_popup(achievement["name"], achievement["description"])

func _on_day_started():
	var level = GameManager.current_level
	var time_per_customer = LevelManager.get_time_per_customer(level)
	start_timer(time_per_customer)
	update_all()

func _on_time_expired():
	print("Sure doldu!")

func show_decision_feedback(is_correct: bool, points: int = 0):
	if decision_feedback:
		if is_correct:
			decision_feedback.text = "DOĞRU! +%d" % points
			decision_feedback.add_theme_color_override("font_color", Color.GREEN)
		else:
			decision_feedback.text = "YANLIŞ!"
			decision_feedback.add_theme_color_override("font_color", Color.RED)
		
		decision_feedback.visible = true
		_create_timer_and_hide(decision_feedback, 1.5)

func _create_timer_and_hide(node: Control, delay: float):
	await get_tree().create_timer(delay).timeout
	node.visible = false

func _show_combo_popup(combo_count: int):
	combo_popup.text = "COMBO x%d!" % combo_count
	combo_popup.visible = true
	combo_displayed.emit(combo_count)
	_create_timer_and_hide(combo_popup, 1.0)

func _show_achievement_popup(name: String, description: String):
	achievement_name_label.text = name
	achievement_desc_label.text = description
	achievement_popup.visible = true
	achievement_displayed.emit(name)
	_create_timer_and_hide(achievement_popup, 3.0)

func show_tool_feedback(tool_name: String, findings: Dictionary):
	var feedback_text = tool_name + ": "
	if findings.has("detail"):
		feedback_text += findings["detail"]
	elif findings.has("uv_response"):
		if findings["uv_response"]:
			feedback_text += "Normal UV yaniti"
		else:
			feedback_text += "UV yaniti YOK!"
	elif findings.has("weight_anomaly"):
		if findings["weight_anomaly"]:
			feedback_text += "Agirlik sapmasi!"
		else:
			feedback_text += "Normal agirlik"
	
	decision_feedback.text = feedback_text
	decision_feedback.visible = true
	await get_tree().create_timer(2.0).timeout
	decision_feedback.visible = false
