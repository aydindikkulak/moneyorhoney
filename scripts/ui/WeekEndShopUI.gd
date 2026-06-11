extends Control

signal shop_closed

@onready var balance_label: Label = $MarginContainer/VBoxContainer/BalanceLabel
@onready var items_grid: GridContainer = $MarginContainer/VBoxContainer/ItemsContainer/ItemsGrid
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var shop_item_cards: Array = []

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	ShopManager.shop_opened.connect(_on_shop_opened)
	ShopManager.item_purchased.connect(_on_item_purchased)
	EarningsSystem.earnings_changed.connect(_on_earnings_changed)
	hide()

func _on_shop_opened():
	show()
	refresh_shop()

func refresh_shop():
	update_balance()
	populate_items()

func update_balance():
	var balance = EarningsSystem.get_total_earnings()
	balance_label.text = "Bakiye: $%d" % balance

func populate_items():
	for card in shop_item_cards:
		if is_instance_valid(card):
			card.queue_free()
	shop_item_cards.clear()
	
	var available_items = ShopManager.get_available_items()
	
	for item_data in available_items:
		var card = create_item_card(item_data)
		items_grid.add_child(card)
		shop_item_cards.append(card)

func create_item_card(item_data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 220)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	var icon_texture: Texture2D = null
	if item_data.has("icon"):
		icon_texture = load(item_data["icon"]) if ResourceLoader.exists(item_data["icon"]) else null
	
	if icon_texture:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = 1
		icon_rect.stretch_mode = 5
		vbox.add_child(icon_rect)
	
	var name_label = Label.new()
	name_label.text = item_data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var price_label = Label.new()
	price_label.text = "$%d" % item_data["price"]
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(price_label)
	
	var buy_button = Button.new()
	buy_button.text = "SATIN AL"
	buy_button.custom_minimum_size = Vector2(0, 40)
	buy_button.disabled = not ShopManager.can_afford(item_data["price"])
	buy_button.pressed.connect(_on_buy_pressed.bind(item_data["id"]))
	vbox.add_child(buy_button)
	
	return card

func _on_buy_pressed(item_id: String):
	var result = ShopManager.purchase_item(item_id)
	if result["success"]:
		update_balance()
		populate_items()

func _on_item_purchased(item_id: String):
	print("Purchased: ", item_id)

func _on_earnings_changed(_new_amount: int):
	update_balance()

func _on_continue_pressed():
	ShopManager.close_shop()
	hide()
	shop_closed.emit()
