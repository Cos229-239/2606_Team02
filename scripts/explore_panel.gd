extends PanelContainer

signal closed

var feedback_label: Label
var location_list: VBoxContainer
var selected_location_id: String = ""
var location_cards: Dictionary = {}

func _ready() -> void:
	self_modulate = Color(0.015, 0.02, 0.04, 0.94)
	_build_ui()
	GameState.resources_changed.connect(_refresh_locations)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 170)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)

	var title := _make_label("Explore", 48, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var description := _make_label("Send fairies beyond the grove to discover resources and hidden magic.", 30, Color("#fff2d6"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(description)

	location_list = VBoxContainer.new()
	location_list.add_theme_constant_override("separation", 18)
	layout.add_child(location_list)

	feedback_label = _make_label("", 28, Color("#f5d66f"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 40)
	layout.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 22)
	layout.add_child(button_row)

	var begin_button := _make_button("Begin Exploration")
	begin_button.pressed.connect(_on_begin_pressed)
	button_row.add_child(begin_button)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): SoundManager.play_click(); closed.emit())
	button_row.add_child(back_button)

	_refresh_locations()


func _refresh_locations() -> void:
	for child in location_list.get_children():
		child.queue_free()
	location_cards.clear()

	for data in GameState.get_exploration_locations():
		var location_id := String(data.get("LocationID", ""))
		var card := _make_location_card(data)
		location_list.add_child(card)
		location_cards[location_id] = card


func _make_location_card(data: Dictionary) -> PanelContainer:
	var location_id := String(data.get("LocationID", ""))
	var unlocked := GameState.is_exploration_unlocked(location_id)
	var is_selected := location_id == selected_location_id and unlocked

	var border_color := Color("#b99245")
	if is_selected:
		border_color = Color("#ffe08a")

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.88), border_color, 3 if is_selected else 2, 10))

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 26)
	card_margin.add_theme_constant_override("margin_right", 26)
	card_margin.add_theme_constant_override("margin_top", 18)
	card_margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(card_margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card_margin.add_child(col)

	var name_color := Color("#fff2a8")
	if not unlocked:
		name_color = Color("#8f8a7c")
	col.add_child(_make_label(String(data.get("Name", "Location")), 32, name_color))

	if unlocked:
		var minutes := int(data.get("DurationSeconds", 0)) / 60
		var reward_min := int(data.get("RewardCoinsMin", 0))
		var reward_max := int(data.get("RewardCoinsMax", 0))
		var reward_text := "%d Coins" % reward_min
		if reward_max != reward_min:
			reward_text = "%d-%d Coins" % [reward_min, reward_max]
		col.add_child(_make_label("Cost: %d Mana   Time: %d min   Reward: %s" % [int(data.get("CostMana", 0)), minutes, reward_text], 24, Color("#e8dfca")))
		var tap_button := _make_small_button("Select" if not is_selected else "Selected")
		tap_button.disabled = is_selected
		tap_button.pressed.connect(func() -> void:
			SoundManager.play_click()
			selected_location_id = location_id
			feedback_label.text = "%s selected." % String(data.get("Name", "Location"))
			_refresh_locations()
		)
		col.add_child(tap_button)
	else:
		col.add_child(_make_label("Locked - reach level %d in Flower Grove and Potion Shop." % int(data.get("UnlockLevel", 0)), 24, Color("#c9a86a")))

	return card


func _on_begin_pressed() -> void:
	SoundManager.play_click()
	if selected_location_id == "":
		feedback_label.text = "Select a location first."
		return
	var result := GameState.start_exploration(selected_location_id)
	feedback_label.text = String(result.get("Message", ""))
	_refresh_locations()


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 78)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
