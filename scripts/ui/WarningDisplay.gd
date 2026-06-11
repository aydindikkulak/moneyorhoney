extends Control

@onready var warning_container: VBoxContainer = $MarginContainer/VBoxContainer/WarningContainer
@onready var warning_count_label: Label = $MarginContainer/VBoxContainer/WarningCountLabel

var warning_icons: Array = []

func _ready():
	WarningSystem.warning_issued.connect(_on_warning_issued)
	WarningSystem.warning_count_changed.connect(_on_warning_count_changed)
	_setup_warning_icons()
	update_display()

func _setup_warning_icons():
	for icon in warning_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	warning_icons.clear()
	
	for i in range(WarningSystem.MAX_WARNINGS):
		var icon = _create_warning_icon(i)
		warning_container.add_child(icon)
		warning_icons.append(icon)

func _create_warning_icon(index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(40, 40)
	
	var label = Label.new()
	label.text = "⚠"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.GRAY)
	label.name = "WarningIcon"
	
	panel.add_child(label)
	return panel

func update_display():
	var count = WarningSystem.get_warning_count()
	warning_count_label.text = "Uyarılar: %d/%d" % [count, WarningSystem.MAX_WARNINGS]
	
	for i in range(warning_icons.size()):
		var icon = warning_icons[i]
		var label = icon.get_node("WarningIcon")
		if i < count:
			label.add_theme_color_override("font_color", Color.RED)
		else:
			label.add_theme_color_override("font_color", Color.GRAY)

func _on_warning_issued(warning_type: String, reason: String):
	_show_warning_popup(warning_type, reason)
	update_display()

func _on_warning_count_changed(count: int):
	update_display()

func _show_warning_popup(warning_type: String, reason: String):
	var popup = _create_warning_popup(warning_type, reason)
	add_child(popup)
	
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(popup):
		popup.queue_free()

func _create_warning_popup(warning_type: String, reason: String) -> PanelContainer:
	var popup = PanelContainer.new()
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position = Vector2(400, 100)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "UYARI: " + warning_type
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	var reason_label = Label.new()
	reason_label.text = reason
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.add_theme_font_size_override("font_size", 14)
	reason_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(reason_label)
	
	return popup
