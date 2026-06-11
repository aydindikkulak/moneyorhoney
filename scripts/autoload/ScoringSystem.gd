extends Node

signal score_changed(new_score: int)
signal accuracy_changed(new_accuracy: float)
signal achievement_unlocked(achievement_id: String)
signal combo_activated(combo_count: int)

var current_score: int = 0
var total_correct: int = 0
var total_wrong: int = 0
var streak_count: int = 0
var best_streak: int = 0
var combo_count: int = 0
var max_combo: int = 0

var score_multiplier: float = 1.0
var combo_multiplier: float = 1.0

var total_customers_served: int = 0
var total_fake_detected: int = 0
var total_money_laundering_caught: int = 0
var perfect_days: int = 0
var fastest_decision_time: float = 999.0
var total_decision_time: float = 0.0

var achievements: Dictionary = {}

func _ready():
	GameManager.day_ended.connect(_on_day_ended)
	_init_achievements()

func _init_achievements():
	achievements = {
		"first_day": {"name": "İlk Gün", "description": "İlk günü tamamla", "unlocked": false},
		"perfect_day": {"name": "Mükemmel Gün", "description": "Hiç hata yapmadan günü bitir", "unlocked": false},
		"streak_5": {"name": "Seri Katil", "description": "5 doğru karar üst üste", "unlocked": false},
		"streak_10": {"name": "Durdurulamaz", "description": "10 doğru karar üst üste", "unlocked": false},
		"combo_3": {"name": "Combo Master", "description": "3x combo elde et", "unlocked": false},
		"fake_hunter": {"name": "Sahte Avcısı", "description": "10 sahte para yakala", "unlocked": false},
		"money_laundering_expert": {"name": "Kara Para Uzmanı", "description": "5 kara para aklama vakası yakala", "unlocked": false},
		"speed_demon": {"name": "Hız Şeytanı", "description": "2 saniyeden hızlı karar ver", "unlocked": false},
		"level_5": {"name": "Uzman Veznedar", "description": "5. seviyeye ulaş", "unlocked": false}
	}

func reset():
	current_score = 0
	total_correct = 0
	total_wrong = 0
	streak_count = 0
	best_streak = 0
	combo_count = 0
	max_combo = 0
	score_multiplier = 1.0
	combo_multiplier = 1.0
	total_customers_served = 0
	total_fake_detected = 0
	total_money_laundering_caught = 0
	perfect_days = 0
	fastest_decision_time = 999.0
	total_decision_time = 0.0
	_init_achievements()

func add_correct_decision(base_points: int = 100, decision_time: float = 0.0):
	# Hız bonusu
	var speed_bonus = _calculate_speed_bonus(decision_time)
	
	# Toplam puan
	var points = int((base_points + speed_bonus) * score_multiplier * combo_multiplier)
	current_score += points
	total_correct += 1
	total_customers_served += 1
	streak_count += 1
	combo_count += 1
	
	# İstatistikler
	if decision_time > 0:
		total_decision_time += decision_time
		if decision_time < fastest_decision_time:
			fastest_decision_time = decision_time
			_check_achievement("speed_demon")
	
	if streak_count > best_streak:
		best_streak = streak_count
		if best_streak >= 5:
			_check_achievement("streak_5")
		if best_streak >= 10:
			_check_achievement("streak_10")
	
	if combo_count > max_combo:
		max_combo = combo_count
		if max_combo >= 3:
			_check_achievement("combo_3")
	
	update_multiplier()
	combo_activated.emit(combo_count)
	score_changed.emit(current_score)
	
	return {
		"points": points,
		"base": base_points,
		"speed_bonus": speed_bonus,
		"multiplier": score_multiplier * combo_multiplier,
		"combo": combo_count
	}

func add_wrong_decision(penalty: int = 50):
	current_score -= penalty
	total_wrong += 1
	total_customers_served += 1
	streak_count = 0
	combo_count = 0
	score_multiplier = 1.0
	combo_multiplier = 1.0
	
	combo_activated.emit(0)
	score_changed.emit(current_score)
	return -penalty

func add_fake_detected(points: int = 150):
	total_fake_detected += 1
	current_score += int(points * score_multiplier)
	
	if total_fake_detected >= 10:
		_check_achievement("fake_hunter")
	
	score_changed.emit(current_score)
	return int(points * score_multiplier)

func add_money_laundering_caught(points: int = 200):
	total_money_laundering_caught += 1
	current_score += int(points * score_multiplier)
	
	if total_money_laundering_caught >= 5:
		_check_achievement("money_laundering_expert")
	
	score_changed.emit(current_score)
	return int(points * score_multiplier)

func _calculate_speed_bonus(decision_time: float) -> int:
	if decision_time <= 0:
		return 0
	if decision_time < 2.0:
		return 50
	elif decision_time < 5.0:
		return 30
	elif decision_time < 10.0:
		return 15
	return 0

func update_multiplier():
	# Streak multiplier
	if streak_count >= 10:
		score_multiplier = 2.0
	elif streak_count >= 5:
		score_multiplier = 1.5
	elif streak_count >= 3:
		score_multiplier = 1.2
	else:
		score_multiplier = 1.0
	
	# Combo multiplier
	if combo_count >= 5:
		combo_multiplier = 2.5
	elif combo_count >= 3:
		combo_multiplier = 2.0
	elif combo_count >= 2:
		combo_multiplier = 1.5
	else:
		combo_multiplier = 1.0

func get_accuracy() -> float:
	var total = total_correct + total_wrong
	if total == 0:
		return 0.0
	return float(total_correct) / float(total)

func get_average_decision_time() -> float:
	if total_customers_served == 0:
		return 0.0
	return total_decision_time / float(total_customers_served)

func get_stats() -> Dictionary:
	return {
		"score": current_score,
		"correct": total_correct,
		"wrong": total_wrong,
		"accuracy": get_accuracy(),
		"streak": streak_count,
		"best_streak": best_streak,
		"combo": combo_count,
		"max_combo": max_combo,
		"multiplier": score_multiplier * combo_multiplier,
		"total_served": total_customers_served,
		"fake_detected": total_fake_detected,
		"laundering_caught": total_money_laundering_caught,
		"avg_decision_time": get_average_decision_time()
	}

func _on_day_ended():
	var day_bonus = 0
	var accuracy = get_accuracy()
	
	if accuracy >= 0.95:
		day_bonus = 500
		perfect_days += 1
		_check_achievement("perfect_day")
	elif accuracy >= 0.85:
		day_bonus = 300
	elif accuracy >= 0.7:
		day_bonus = 150
	elif accuracy >= 0.5:
		day_bonus = 50
	
	# Gün bonusları
	var level_bonus = GameManager.current_level * 100
	day_bonus += level_bonus
	
	if day_bonus > 0:
		current_score += day_bonus
		score_changed.emit(current_score)
	
	# Başarı kontrolü
	if GameManager.current_day == 1:
		_check_achievement("first_day")
	if GameManager.current_level >= 5:
		_check_achievement("level_5")

func calculate_final_score() -> Dictionary:
	var accuracy_bonus = int(get_accuracy() * 1000)
	var streak_bonus = best_streak * 50
	var combo_bonus = max_combo * 75
	var level_bonus = GameManager.current_level * 200
	var speed_bonus = int(max(0, (30.0 - get_average_decision_time()) * 10))
	
	var final_score = current_score + accuracy_bonus + streak_bonus + combo_bonus + level_bonus + speed_bonus
	
	return {
		"base_score": current_score,
		"accuracy_bonus": accuracy_bonus,
		"streak_bonus": streak_bonus,
		"combo_bonus": combo_bonus,
		"level_bonus": level_bonus,
		"speed_bonus": speed_bonus,
		"final_score": final_score,
		"achievements_unlocked": achievements.values().filter(func(a): return a.unlocked).size()
	}

func _check_achievement(achievement_id: String):
	if achievements.has(achievement_id) and not achievements[achievement_id].unlocked:
		achievements[achievement_id].unlocked = true
		achievement_unlocked.emit(achievement_id)
		print("Başarı kazanıldı: ", achievements[achievement_id].name)

func get_achievements() -> Dictionary:
	return achievements

func get_unlocked_achievements_count() -> int:
	return achievements.values().filter(func(a): return a.unlocked).size()
