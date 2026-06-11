extends Node

enum GameState { MENU, PLAYING, DAY_END, WEEK_END, SHOP, GAME_OVER }

var current_state: GameState = GameState.MENU

var current_level: int = 1
var current_day: int = 1
var current_week: int = 1
var total_score: int = 0
var total_money_earned: int = 0
var total_money_lost: int = 0

var day_correct_decisions: int = 0
var day_wrong_decisions: int = 0
var day_money_earned: int = 0
var day_money_lost: int = 0

signal game_started
signal day_started
signal day_ended
signal week_started
signal week_ended
signal shop_opened
signal shop_closed
signal decision_made(is_correct: bool)
signal game_over

func _ready():
	print("GameManager initialized")

func start_game():
	current_level = 1
	current_week = 1
	current_day = 1
	total_score = 0
	total_money_earned = 0
	total_money_lost = 0
	
	WeekCycleSystem.start_new_game()
	EarningsSystem.start_new_game()
	WarningSystem.start_new_game()
	
	game_started.emit()

func start_day():
	current_state = GameState.PLAYING
	day_correct_decisions = 0
	day_wrong_decisions = 0
	day_money_earned = 0
	day_money_lost = 0
	day_started.emit()
	print("Day ", current_day, " started - Level ", current_level)

func end_day():
	current_state = GameState.DAY_END
	calculate_day_results()
	day_ended.emit()
	print("Day ", current_day, " ended")

func calculate_day_results():
	var accuracy = 0.0
	var total_decisions = day_correct_decisions + day_wrong_decisions
	if total_decisions > 0:
		accuracy = float(day_correct_decisions) / float(total_decisions)
	
	var day_score = day_correct_decisions * 100
	var penalty = day_wrong_decisions * 50
	day_score -= penalty
	
	total_score += day_score
	total_money_earned += day_money_earned
	total_money_lost += day_money_lost
	
	print("Day Results: Score=", day_score, " Accuracy=", accuracy * 100, "%")

func make_decision(is_correct: bool, amount: int = 0):
	if is_correct:
		day_correct_decisions += 1
		day_money_earned += amount
		total_score += 100
	else:
		day_wrong_decisions += 1
		day_money_lost += amount
		total_score -= 50
	
	decision_made.emit(is_correct)

func check_level_completion() -> bool:
	var level_data = LevelManager.get_level_data(current_level)
	if level_data.is_empty():
		return false
	
	# Seviye tamamlanması için haftalık döngünün bitmesi gerekiyor
	# (shop açılması = hafta sonu = seviye tamamlanma zamanı)
	# Ayrıca doğruluk oranı da yeterli olmalı
	var accuracy = get_accuracy()
	var required_accuracy = level_data.get("required_accuracy", 0.75)
	
	return WeekCycleSystem.is_week_end() and accuracy >= required_accuracy

func advance_to_next_day():
	# Haftalık döngü WeekCycleSystem tarafından yönetiliyor
	# Bu fonksiyon sadece bir sonraki günü başlatır
	start_day()

func advance_to_next_level():
	current_level += 1
	current_week = 1
	current_day = 1
	
	if current_level > LevelManager.get_total_levels():
		game_over.emit()
		current_state = GameState.GAME_OVER
	else:
		WeekCycleSystem.start_new_game()
		start_day()

func on_week_ended():
	# Hafta sonu geldi - shop aç
	current_state = GameState.SHOP
	shop_opened.emit()

func on_shop_closed():
	# Shop kapandı - seviye atla
	advance_to_next_level()

func get_accuracy() -> float:
	var total = day_correct_decisions + day_wrong_decisions
	if total == 0:
		return 0.0
	return float(day_correct_decisions) / float(total)

func reset_game():
	current_state = GameState.MENU
	current_level = 1
	current_day = 1
	total_score = 0
	total_money_earned = 0
	total_money_lost = 0
