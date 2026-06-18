extends PanelContainer

signal closed

const BG_PATH := "res://assets/sprites/market_stall/market_stall_background.png"
const TITLE_PATH := "res://assets/sprites/market_stall/market_stall_title.png"
const ROW_PANEL_PATH := "res://assets/sprites/market_stall/market_order_row_panel.png"
const ORDER_BOARD_PATH := "res://assets/sprites/market_stall/market_order_board.png"
const SHOPKEEPER_PATH := "res://assets/sprites/market_stall/market_shopkeeper.png"

const TAB_CARDS := {
	"Trade": "res://assets/sprites/market_stall/market_trade_card.png",
	"Orders": "res://assets/sprites/market_stall/market_orders_card.png",
	"Upgrades": "res://assets/sprites/market_stall/market_upgrades_card.png",
	"Storage": "res://assets/sprites/market_stall/market_storage_card.png",
	"Back": "res://assets/sprites/market_stall/market_back_card.png"
}

var active_tab := "Trade"
var stats_label: Label
var mode_title_label: Label
var mode_description_label: Label
var feedback_label: Label
var action_button: Button
var card_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build_panel()
	var state := _game_state()
	state.resources_changed.connect(_refresh)
	state.market_stall_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_top_resource_bar()
	_add_title_sign()
	_add_market_art()
	_add_mode_panel()
	_add_bottom_tabs()


func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = load(BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.20)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _add_top_resource_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 1760)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.030, 0.018, 0.014, 0.80), Color("#d8a35a"), 2, 12))
	margin.add_child(panel)

	stats_label = _make_label("", 28, Color("#fff1bf"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)


func _add_title_sign() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)

	_add_texture(layer, TITLE_PATH, Vector2(74, 96), Vector2(930, 230))

	var title := _make_label("Market Stall", 62, Color("#ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(175, 144)
	title.size = Vector2(730, 82)
	layer.add_child(title)

	mode_title_label = _make_label("", 30, Color("#f8ffce"), HORIZONTAL_ALIGNMENT_CENTER)
	mode_title_label.name = "MarketLevelLabel"
	mode_title_label.position = Vector2(318, 246)
	mode_title_label.size = Vector2(444, 46)
	layer.add_child(mode_title_label)


func _add_market_art() -> void:
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	_add_texture(art, ORDER_BOARD_PATH, Vector2(82, 430), Vector2(440, 570))
	_add_texture(art, SHOPKEEPER_PATH, Vector2(575, 450), Vector2(405, 540))


func _add_mode_panel() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 86)
	margin.add_theme_constant_override("margin_right", 86)
	margin.add_theme_constant_override("margin_top", 1080)
	margin.add_theme_constant_override("margin_bottom", 505)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.045, 0.027, 0.020, 0.86), Color("#c9954e"), 2, 14))
	margin.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(content_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	content_margin.add_child(layout)

	var banner := TextureRect.new()
	banner.texture = load(ROW_PANEL_PATH)
	banner.custom_minimum_size = Vector2(820, 118)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(banner)

	mode_description_label = _make_label("", 27, Color("#fff0c2"), HORIZONTAL_ALIGNMENT_CENTER)
	mode_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(mode_description_label)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(420, 72)
	action_button.add_theme_font_size_override("font_size", 28)
	action_button.add_theme_color_override("font_color", Color("#fff3b8"))
	action_button.add_theme_color_override("font_hover_color", Color.WHITE)
	action_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.095, 0.052, 0.032, 0.94), Color("#c9954e"), 2, 10))
	action_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.140, 0.082, 0.046, 0.98), Color("#ffe28f"), 3, 10))
	action_button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.18, 0.10, 0.06, 0.98), Color("#fff5bd"), 3, 10))
	action_button.pressed.connect(_on_action_pressed)
	layout.add_child(action_button)

	feedback_label = _make_label("", 24, Color("#99e8ac"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(feedback_label)


func _add_bottom_tabs() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 1540)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	for tab_name in ["Trade", "Orders", "Upgrades", "Storage", "Back"]:
		var card := _make_tab_card(tab_name)
		card_buttons[tab_name] = card
		row.add_child(card)


func _make_tab_card(tab_name: String) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(196, 300)

	var texture := TextureRect.new()
	texture.texture = load(String(TAB_CARDS[tab_name]))
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture)

	var active_border := PanelContainer.new()
	active_border.name = "ActiveBorder"
	active_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_border.add_theme_stylebox_override("panel", _make_panel_style(Color.TRANSPARENT, Color("#78e071"), 4, 12))
	card.add_child(active_border)

	var button := Button.new()
	button.text = ""
	button.tooltip_text = tab_name
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if tab_name == "Back":
			_on_back_pressed()
		else:
			_set_active_tab(tab_name)
	)
	card.add_child(button)
	return card


func _set_active_tab(tab_name: String) -> void:
	active_tab = tab_name
	feedback_label.text = ""
	_refresh()


func _refresh() -> void:
	var state := _game_state()
	stats_label.text = (
		"Mana %d     Coins %d     Reputation %d     Orders %d/%d     Storage %d"
		% [
			state.total_mana,
			state.total_coins,
			state.market_reputation,
			state.market_orders_completed,
			state.get_market_order_target(),
			state.market_storage_capacity
		]
	)
	mode_title_label.text = "Market Level %d" % state.market_stall_level

	match active_tab:
		"Trade":
			mode_description_label.text = "Trade gathered Mana for village Coins. Cost: %d Mana. Reward: %d Coins and +%d reputation." % [state.get_market_trade_mana_cost(), state.get_market_trade_coin_reward(), state.market_stall_level + 1]
			action_button.text = "Fulfill Trade"
			action_button.disabled = state.total_mana < state.get_market_trade_mana_cost()
		"Orders":
			mode_description_label.text = "Orders completed: %d/%d. The stall reputation grows as you fulfill trades for the village." % [state.market_orders_completed, state.get_market_order_target()]
			action_button.text = "Review Orders"
			action_button.disabled = true
		"Upgrades":
			mode_description_label.text = "Upgrade the stall to improve trade rewards and order goals. Cost: %d Coins." % state.get_market_upgrade_cost_coins()
			action_button.text = "Upgrade Stall"
			action_button.disabled = state.total_coins < state.get_market_upgrade_cost_coins()
		"Storage":
			mode_description_label.text = "Expand market storage for future goods and larger order chains. Cost: %d Coins. Current capacity: %d." % [state.get_market_storage_upgrade_cost_coins(), state.market_storage_capacity]
			action_button.text = "Expand Storage"
			action_button.disabled = state.total_coins < state.get_market_storage_upgrade_cost_coins()

	for tab_name in card_buttons.keys():
		var border := (card_buttons[tab_name] as Control).get_node("ActiveBorder") as PanelContainer
		border.visible = tab_name == active_tab


func _on_action_pressed() -> void:
	var state := _game_state()
	var success := false
	match active_tab:
		"Trade":
			success = state.fulfill_market_trade()
			feedback_label.text = "Trade fulfilled!" if success else "Not enough Mana."
		"Upgrades":
			success = state.upgrade_market_stall()
			feedback_label.text = "Market upgraded!" if success else "Need more Coins."
		"Storage":
			success = state.upgrade_market_storage()
			feedback_label.text = "Storage expanded!" if success else "Need more Coins."
	_refresh()


func _on_back_pressed() -> void:
	_game_state().save_game()
	closed.emit()


func _add_texture(parent: Node, path: String, top_left: Vector2, texture_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(path)
	texture_rect.position = top_left
	texture_rect.size = texture_size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _game_state() -> Node:
	return get_node("/root/GameState")
