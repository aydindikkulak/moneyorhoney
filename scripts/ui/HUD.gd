extends Control

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var money_label: Label = $TopBar/MoneyLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var streak_label: Label = $TopBar/StreakLabel
@onready var accuracy_label: Label = $TopBar/AccuracyLabel
@onready var multiplier_label: Label = $TopBar/MultiplierLabel

var time_remaining: int = 60
var timer_active: bool = false

func _ready():
	ScoringSystem.score_changed.connect(_on_score_changed)
	ScoringSystem.money_changed.connect(_on_money_changed)
	GameManager.day_started.connect(_on_day_started)
	
	update_all()

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
	
	if stats["multiplier"] > 1.0:
		multiplier_label.text = "x%.1f" % stats["multiplier"]
		multiplier_label.visible = true
	else:
		multiplier_label.visible = false

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

func _on_score_changed(new_score: int):
	score_label.text = "Skor: %d" % new_score

func _on_money_changed(new_amount: int):
	money_label.text = "Kasa: $%d" % new_amount

func _on_day_started():
	var level = GameManager.current_level
	var time_per_customer = LevelManager.get_time_per_customer(level)
	start_timer(time_per_customer)
	update_all()

func _on_time_expired():
	print("Sure doldu!")

func show_decision_feedback(is_correct: bool):
	var feedback_label = $DecisionFeedback
	if feedback_label:
		if is_correct:
			feedback_label.text = "DOG RU!"
			feedback_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			feedback_label.text = "YANLIS!"
			feedback_label.add_theme_color_override("font_color", Color.RED)
		
		feedback_label.visible = true
		await get_tree().create_timer(1.5).timeout
		feedback_label.visible = false
