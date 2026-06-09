extends Node

signal day_started
signal day_ended
signal decision_made(is_correct: bool)
signal game_over

enum GameState {
	MENU,
	PLAYING,
	DAY_END,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_level: int = 1
var current_day: int = 1
var total_score: int = 0
var total_money_earned: int = 0
var total_money_lost: int = 0

var day_correct_decisions: int = 0
var day_wrong_decisions: int = 0
var day_money_earned: int = 0
var day_money_lost: int = 0

func _ready():
	print("GameManager initialized")

func start_game():
	current_level = 1
	current_day = 1
	total_score = 0
	total_money_earned = 0
	total_money_lost = 0
	start_day()

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
	
	var total_decisions = day_correct_decisions + day_wrong_decisions
	var required_correct = level_data.get("required_correct", 0)
	
	return day_correct_decisions >= required_correct

func advance_to_next_day():
	if check_level_completion():
		current_day += 1
		var level_data = LevelManager.get_level_data(current_level)
		var days_in_level = level_data.get("days", 1)
		
		if current_day > days_in_level:
			advance_to_next_level()
		else:
			start_day()
	else:
		print("Level not completed, retrying day...")
		start_day()

func advance_to_next_level():
	current_level += 1
	current_day = 1
	
	if current_level > LevelManager.get_total_levels():
		game_over.emit()
		current_state = GameState.GAME_OVER
	else:
		start_day()

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
