extends PanelContainer

signal closed
signal open_building_requested(building_name: String)

func _ready() -> void:
	self_modulate = Color(0.015, 0.02, 0.04, 0.94)
	_build_ui()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 125)
	margin.add_theme_constant_override("margin_bottom", 185)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := _make_label("Buildings", 46, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var unlocked := _make_label("Unlocked", 30, Color("#fff2a8"))
	layout.add_child(unlocked)

	var building_list := VBoxContainer.new()
	building_list.add_theme_constant_override("separation", 14)
	layout.add_child(building_list)
	_add_building_entry(building_list, "Flower Grove", "Level %d" % GameState.flower_grove_level, "Collect and upgrade mana flowers.")
	_add_building_entry(building_list, "Sacred Koi Pond", "Level %d" % GameState.sacred_pond_level, "Restore water purity and unlock pond rewards.")
	_add_building_entry(building_list, "Fairy House", "Level %d" % GameState.fairy_house_level, "Assign fairies to support the grove.")
	_add_building_entry(building_list, "Potion Shop", "Level %d" % GameState.potion_shop_level, "Craft Mana Potions and sell them for Coins.")
	_add_building_entry(building_list, "Ancient Tree", "Landmark", "Restoration landmark and grove story placeholder.")
	_add_building_entry(building_list, "Market Stall", "Level %d" % GameState.market_stall_level, "Fulfill trades, complete orders, and expand storage.")
	_add_building_entry(building_list, "Arcane Forge", "Level %d" % GameState.arcane_forge_level, "Craft gear, enhance it with crystals, and upgrade the forge.")

	var locked := _make_label("Locked", 30, Color("#fff2a8"))
	layout.add_child(locked)
	for text in ["No extra buildings unlocked yet."]:
		layout.add_child(_make_locked_entry(text))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 20)
	layout.add_child(spacer)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): closed.emit())
	layout.add_child(back_button)


func _add_building_entry(parent: VBoxContainer, building_name: String, level_text: String, description: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.9), Color("#b99245"), 2, 10))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	text_box.add_child(_make_label(building_name, 28, Color("#fff2a8")))
	text_box.add_child(_make_label(level_text, 22, Color("#f5d66f")))
	var desc := _make_label(description, 22, Color("#e8dfca"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(desc)

	var open_button := _make_button("Open")
	open_button.custom_minimum_size = Vector2(160, 70)
	open_button.pressed.connect(func(): open_building_requested.emit(building_name))
	row.add_child(open_button)


func _make_locked_entry(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.02, 0.025, 0.035, 0.72), Color("#5a4a2b"), 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	margin.add_child(_make_label(text, 24, Color("#aaa18d")))
	return panel


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 74)
	button.add_theme_font_size_override("font_size", 24)
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
