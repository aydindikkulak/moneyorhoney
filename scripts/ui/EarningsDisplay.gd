extends Control

@onready var total_label: Label = $MarginContainer/VBoxContainer/TotalLabel
@onready var daily_label: Label = $MarginContainer/VBoxContainer/DailyLabel
@onready var commission_label: Label = $MarginContainer/VBoxContainer/CommissionLabel
@onready var weekly_label: Label = $MarginContainer/VBoxContainer/WeeklyLabel

func _ready():
	EarningsSystem.earnings_changed.connect(_on_earnings_changed)
	WeekCycleSystem.day_started.connect(_on_day_started)
	WeekCycleSystem.week_started.connect(_on_week_started)
	update_display()

func update_display():
	total_label.text = "Toplam Kazanç: $%d" % EarningsSystem.get_total_earnings()
	daily_label.text = "Bugün: $%d" % EarningsSystem.get_daily_earnings()
	commission_label.text = "Komisyon Kesintisi: -$%d" % EarningsSystem.get_total_commission_deducted()
	weekly_label.text = "Bu Hafta: $%d" % EarningsSystem.get_weekly_earnings()

func _on_earnings_changed(_new_amount: int):
	update_display()

func _on_day_started(_day_number: int):
	update_display()

func _on_week_started(_week_number: int):
	update_display()
