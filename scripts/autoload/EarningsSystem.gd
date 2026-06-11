extends Node

signal bank_vault_changed(new_amount: int)
signal teller_earnings_changed(new_amount: int)
signal commission_deducted(amount: int)
signal daily_salary_paid(amount: int)
signal bonus_earned(amount: int, reason: String)

const COMMISSION_RATE = 0.10
const BASE_DAILY_SALARY = 50
const CORRECT_REJECT_BONUS = 25
const CORRECT_ACCEPT_TIP_RATE = 0.02

var bank_vault: int = 0
var teller_earnings: int = 0

var daily_bank_total: int = 0
var daily_teller_total: int = 0
var daily_commission: int = 0
var daily_bonuses: int = 0

var weekly_bank_total: int = 0
var weekly_teller_total: int = 0

func _ready():
	WeekCycleSystem.day_ended.connect(_on_day_ended)
	WeekCycleSystem.week_ended.connect(_on_week_ended)
	print("EarningsSystem initialized")

func start_new_game():
	bank_vault = 0
	teller_earnings = 0
	daily_bank_total = 0
	daily_teller_total = 0
	daily_commission = 0
	daily_bonuses = 0
	weekly_bank_total = 0
	weekly_teller_total = 0

func process_accept_correct(amount: int) -> Dictionary:
	var commission = int(amount * COMMISSION_RATE)
	var tip = int(amount * CORRECT_ACCEPT_TIP_RATE)
	var bank_deposit = amount - commission

	bank_vault += bank_deposit
	teller_earnings += tip

	daily_bank_total += bank_deposit
	daily_teller_total += tip
	daily_commission += commission
	weekly_bank_total += bank_deposit

	bank_vault_changed.emit(bank_vault)
	teller_earnings_changed.emit(teller_earnings)
	commission_deducted.emit(commission)

	return {
		"gross": amount,
		"bank_deposit": bank_deposit,
		"commission": commission,
		"tip": tip
	}

func process_accept_wrong(amount: int) -> Dictionary:
	var penalty = amount
	bank_vault = max(0, bank_vault - penalty)
	teller_earnings = max(0, teller_earnings - int(penalty * 0.1))

	daily_bank_total -= penalty
	daily_teller_total -= int(penalty * 0.1)

	bank_vault_changed.emit(bank_vault)
	teller_earnings_changed.emit(teller_earnings)

	return {
		"gross": amount,
		"penalty": penalty
	}

func process_reject_correct():
	teller_earnings += CORRECT_REJECT_BONUS
	daily_teller_total += CORRECT_REJECT_BONUS
	daily_bonuses += CORRECT_REJECT_BONUS
	teller_earnings_changed.emit(teller_earnings)
	bonus_earned.emit(CORRECT_REJECT_BONUS, "Sahte para reddedildi")

func process_reject_wrong(amount: int) -> Dictionary:
	var penalty = 50
	teller_earnings = max(0, teller_earnings - penalty)
	daily_teller_total -= penalty

	teller_earnings_changed.emit(teller_earnings)

	return {
		"penalty": penalty
	}

func pay_daily_salary() -> int:
	var salary = BASE_DAILY_SALARY
	teller_earnings += salary
	daily_teller_total += salary
	teller_earnings_changed.emit(teller_earnings)
	daily_salary_paid.emit(salary)
	return salary

func get_bank_vault() -> int:
	return bank_vault

func get_teller_earnings() -> int:
	return teller_earnings

func get_daily_bank_total() -> int:
	return daily_bank_total

func get_daily_teller_total() -> int:
	return daily_teller_total

func get_daily_commission() -> int:
	return daily_commission

func get_weekly_bank_total() -> int:
	return weekly_bank_total

func get_weekly_teller_total() -> int:
	return weekly_teller_total

func get_daily_report() -> Dictionary:
	return {
		"bank_total": daily_bank_total,
		"teller_total": daily_teller_total,
		"commission": daily_commission,
		"bonuses": daily_bonuses,
		"salary": BASE_DAILY_SALARY
	}

func _on_day_ended(_day_number: int):
	pay_daily_salary()
	daily_bank_total = 0
	daily_teller_total = 0
	daily_commission = 0
	daily_bonuses = 0

func _on_week_ended(_week_number: int):
	weekly_bank_total = 0
	weekly_teller_total = 0
