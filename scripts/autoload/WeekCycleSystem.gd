extends Node

signal week_started(week_number: int)
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal week_ended(week_number: int)
signal shop_opened
signal shop_closed

const DAYS_PER_WEEK = 5

var current_week: int = 1
var current_day: int = 1
var total_days_played: int = 0

func _ready():
	print("WeekCycleSystem initialized")

func start_new_game():
	current_week = 1
	current_day = 1
	total_days_played = 0
	week_started.emit(current_week)
	start_day()

func start_day():
	print("Week %d - Day %d started" % [current_week, current_day])
	day_started.emit(current_day)

func end_day():
	print("Week %d - Day %d ended" % [current_week, current_day])
	day_ended.emit(current_day)
	total_days_played += 1
	
	if current_day >= DAYS_PER_WEEK:
		end_week()
	else:
		advance_to_next_day()

func advance_to_next_day():
	current_day += 1
	start_day()

func end_week():
	print("Week %d ended" % current_week)
	week_ended.emit(current_week)
	open_shop()

func open_shop():
	print("Shop opened for week %d" % current_week)
	shop_opened.emit()

func close_shop():
	print("Shop closed")
	shop_closed.emit()
	advance_to_next_week()

func advance_to_next_week():
	current_week += 1
	current_day = 1
	print("Advancing to week %d" % current_week)
	week_started.emit(current_week)
	start_day()

func get_current_week() -> int:
	return current_week

func get_current_day() -> int:
	return current_day

func get_days_remaining_in_week() -> int:
	return DAYS_PER_WEEK - current_day

func is_week_end() -> bool:
	return current_day >= DAYS_PER_WEEK

func get_week_progress() -> float:
	return float(current_day) / float(DAYS_PER_WEEK)
