extends Control

signal day_complete
signal retry_requested

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var score_label: Label = $Panel/VBox/StatsContainer/ScoreLabel
@onready var accuracy_label: Label = $Panel/VBox/StatsContainer/AccuracyLabel
@onready var correct_label: Label = $Panel/VBox/StatsContainer/CorrectLabel
@onready var wrong_label: Label = $Panel/VBox/StatsContainer/WrongLabel
@onready var money_label: Label = $Panel/VBox/StatsContainer/MoneyLabel
@onready var streak_label: Label = $Panel/VBox/StatsContainer/StreakLabel
@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var next_button: Button = $Panel/VBox/ButtonContainer/NextButton
@onready var retry_button: Button = $Panel/VBox/ButtonContainer/RetryButton

var level_completed: bool = false

func _ready():
	GameManager.day_ended.connect(_on_day_ended)
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	visible = false

func _on_day_ended():
	show_report()
	visible = true

func show_report():
	var stats = ScoringSystem.get_stats()
	var final_scores = ScoringSystem.calculate_final_score()
	
	title_label.text = "Gun %d Raporu - Seviye %d" % [GameManager.current_day, GameManager.current_level]
	score_label.text = "Gunluk Skor: %d" % final_scores["base_score"]
	accuracy_label.text = "Dogruluk: %d%%" % (stats["accuracy"] * 100)
	correct_label.text = "Dogru Kararlar: %d" % stats["correct"]
	wrong_label.text = "Yanlis Kararlar: %d" % stats["wrong"]
	money_label.text = "Kasa: $%d" % stats["money"]
	streak_label.text = "En iyi seri: %d" % stats["best_streak"]
	
	level_completed = GameManager.check_level_completion()
	
	if level_completed:
		result_label.text = "SEVIYE TAMAMLANDI!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
		next_button.text = "Sonraki Gun"
		next_button.visible = true
		
		if GameManager.current_level >= LevelManager.get_total_levels():
			next_button.text = "Oyunu Bitir"
	else:
		result_label.text = "Seviye tamamlanamadi. Tekrar dene!"
		result_label.add_theme_color_override("font_color", Color.RED)
		next_button.visible = false
	
	retry_button.visible = not level_completed

func _on_next_pressed():
	visible = false
	GameManager.advance_to_next_day()
	day_complete.emit()

func _on_retry_pressed():
	visible = false
	retry_requested.emit()

func show_game_over():
	title_label.text = "Oyun Bitti!"
	var final_scores = ScoringSystem.calculate_final_score()
	score_label.text = "Toplam Skor: %d" % final_scores["final_score"]
	accuracy_label.text = "Genel Dogruluk: %d%%" % (ScoringSystem.get_accuracy() * 100)
	result_label.text = "Tebrikler! Tum seviyeleri tamamladiniz!"
	result_label.add_theme_color_override("font_color", Color.GOLD)
	next_button.text = "Ana Menu"
	next_button.visible = true
	retry_button.visible = false
	visible = true
