extends PanelContainer

signal closed

var feedback_label: Label
var begin_button: Button

func _ready() -> void:
	self_modulate = Color(0.015, 0.02, 0.04, 0.94)
	_build_ui()


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

	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.88), Color("#b99245"), 2, 10))
	layout.add_child(list_panel)

	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 30)
	list_margin.add_theme_constant_override("margin_right", 30)
	list_margin.add_theme_constant_override("margin_top", 26)
	list_margin.add_theme_constant_override("margin_bottom", 26)
	list_panel.add_child(list_margin)

	var locked_list := VBoxContainer.new()
	locked_list.add_theme_constant_override("separation", 18)
	list_margin.add_child(locked_list)
	for location in ["Forest Trail: Locked", "Moonlit Clearing: Locked", "Crystal Hollow: Locked"]:
		locked_list.add_child(_make_label(location, 32, Color("#d8d2c3")))

	feedback_label = _make_label("", 28, Color("#f5d66f"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 220)
	layout.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 22)
	layout.add_child(button_row)

	begin_button = _make_button("Begin Exploration")
	begin_button.pressed.connect(_on_begin_pressed)
	button_row.add_child(begin_button)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): SoundManager.play_click(); closed.emit())
	button_row.add_child(back_button)


func _on_begin_pressed() -> void:
	SoundManager.play_click()
	feedback_label.text = "Exploration coming soon."
	_flash_button(begin_button)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
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


func _flash_button(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color("#f5d66f"), 0.08)
	tween.tween_property(button, "modulate", Color.WHITE, 0.18)


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
