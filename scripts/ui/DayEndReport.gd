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
@onready var combo_label: Label = $Panel/VBox/StatsContainer/ComboLabel
@onready var fake_detected_label: Label = $Panel/VBox/StatsContainer/FakeDetectedLabel
@onready var laundering_label: Label = $Panel/VBox/StatsContainer/LaunderingLabel
@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var bonuses_label: Label = $Panel/VBox/BonusesLabel
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
	combo_label.text = "En yuksek combo: x%d" % stats["max_combo"]
	fake_detected_label.text = "Sahte para yakalanan: %d" % stats["fake_detected"]
	laundering_label.text = "Kara para yakalanan: %d" % stats["laundering_caught"]
	
	# Bonuslar
	var bonus_text = ""
	if final_scores["accuracy_bonus"] > 0:
		bonus_text += "Dogruluk bonusu: +%d\n" % final_scores["accuracy_bonus"]
	if final_scores["streak_bonus"] > 0:
		bonus_text += "Seri bonusu: +%d\n" % final_scores["streak_bonus"]
	if final_scores["combo_bonus"] > 0:
		bonus_text += "Combo bonusu: +%d\n" % final_scores["combo_bonus"]
	if final_scores["level_bonus"] > 0:
		bonus_text += "Seviye bonusu: +%d\n" % final_scores["level_bonus"]
	if final_scores["speed_bonus"] > 0:
		bonus_text += "Hiz bonusu: +%d\n" % final_scores["speed_bonus"]
	bonuses_label.text = bonus_text
	
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
	var stats = ScoringSystem.get_stats()
	
	score_label.text = "Toplam Skor: %d" % final_scores["final_score"]
	accuracy_label.text = "Genel Dogruluk: %d%%" % (stats["accuracy"] * 100)
	correct_label.text = "Toplam Dogru: %d" % stats["correct"]
	wrong_label.text = "Toplam Yanlis: %d" % stats["wrong"]
	money_label.text = "Toplam Kasa: $%d" % stats["money"]
	streak_label.text = "En iyi seri: %d" % stats["best_streak"]
	combo_label.text = "En yuksek combo: x%d" % stats["max_combo"]
	fake_detected_label.text = "Toplam sahte para: %d" % stats["fake_detected"]
	laundering_label.text = "Toplam kara para: %d" % stats["laundering_caught"]
	
	var bonus_text = "Final Bonuslari:\n"
	bonus_text += "Dogruluk: +%d\n" % final_scores["accuracy_bonus"]
	bonus_text += "Seri: +%d\n" % final_scores["streak_bonus"]
	bonus_text += "Combo: +%d\n" % final_scores["combo_bonus"]
	bonus_text += "Seviye: +%d\n" % final_scores["level_bonus"]
	bonus_text += "Hiz: +%d\n" % final_scores["speed_bonus"]
	bonus_text += "\nBasarilar: %d/%d" % [final_scores["achievements_unlocked"], 9]
	bonuses_label.text = bonus_text
	
	result_label.text = "Tebrikler! Tum seviyeleri tamamladiniz!"
	result_label.add_theme_color_override("font_color", Color.GOLD)
	next_button.text = "Ana Menu"
	next_button.visible = true
	retry_button.visible = false
	visible = true
