extends Node

signal score_changed(new_score: int)
signal money_changed(new_amount: int)
signal accuracy_changed(new_accuracy: float)

var current_score: int = 0
var current_money: int = 0
var total_correct: int = 0
var total_wrong: int = 0
var streak_count: int = 0
var best_streak: int = 0

var score_multiplier: float = 1.0

func _ready():
	GameManager.day_ended.connect(_on_day_ended)

func reset():
	current_score = 0
	current_money = 0
	total_correct = 0
	total_wrong = 0
	streak_count = 0
	best_streak = 0
	score_multiplier = 1.0

func add_correct_decision(base_points: int = 100):
	var points = int(base_points * score_multiplier)
	current_score += points
	total_correct += 1
	streak_count += 1
	
	if streak_count > best_streak:
		best_streak = streak_count
	
	update_multiplier()
	score_changed.emit(current_score)
	
	return points

func add_wrong_decision(penalty: int = 50):
	current_score -= penalty
	total_wrong += 1
	streak_count = 0
	score_multiplier = 1.0
	
	score_changed.emit(current_score)
	return -penalty

func add_money(amount: int):
	current_money += amount
	money_changed.emit(current_money)

func subtract_money(amount: int):
	current_money -= amount
	money_changed.emit(current_money)

func update_multiplier():
	if streak_count >= 10:
		score_multiplier = 2.0
	elif streak_count >= 5:
		score_multiplier = 1.5
	elif streak_count >= 3:
		score_multiplier = 1.2
	else:
		score_multiplier = 1.0

func get_accuracy() -> float:
	var total = total_correct + total_wrong
	if total == 0:
		return 0.0
	return float(total_correct) / float(total)

func get_stats() -> Dictionary:
	return {
		"score": current_score,
		"money": current_money,
		"correct": total_correct,
		"wrong": total_wrong,
		"accuracy": get_accuracy(),
		"streak": streak_count,
		"best_streak": best_streak,
		"multiplier": score_multiplier
	}

func _on_day_ended():
	var day_bonus = 0
	if get_accuracy() >= 0.9:
		day_bonus = 500
	elif get_accuracy() >= 0.7:
		day_bonus = 200
	elif get_accuracy() >= 0.5:
		day_bonus = 100
	
	if day_bonus > 0:
		current_score += day_bonus
		score_changed.emit(current_score)

func calculate_final_score() -> Dictionary:
	var accuracy_bonus = int(get_accuracy() * 1000)
	var streak_bonus = best_streak * 50
	var level_bonus = GameManager.current_level * 200
	
	var final_score = current_score + accuracy_bonus + streak_bonus + level_bonus
	
	return {
		"base_score": current_score,
		"accuracy_bonus": accuracy_bonus,
		"streak_bonus": streak_bonus,
		"level_bonus": level_bonus,
		"final_score": final_score
	}
