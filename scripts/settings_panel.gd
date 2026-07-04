extends PanelContainer

signal closed

var feedback_label: Label
var credits_label: Label
var music_slider: HSlider
var sfx_slider: HSlider
var tutorial_toggle: CheckButton
var confirm_panel: PanelContainer

func _ready() -> void:
	self_modulate = Color(0.015, 0.02, 0.04, 0.94)
	_build_ui()
	_refresh_controls()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 130)
	margin.add_theme_constant_override("margin_bottom", 190)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := _make_label("Settings", 46, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	music_slider = _add_slider_row(layout, "Music Volume")
	music_slider.value_changed.connect(func(value: float): GameState.set_music_volume(value))

	sfx_slider = _add_slider_row(layout, "SFX Volume")
	sfx_slider.value_changed.connect(func(value: float): GameState.set_sfx_volume(value))

	tutorial_toggle = CheckButton.new()
	tutorial_toggle.text = "Tutorial On"
	tutorial_toggle.custom_minimum_size = Vector2(360, 68)
	tutorial_toggle.add_theme_font_size_override("font_size", 26)
	tutorial_toggle.add_theme_color_override("font_color", Color("#fff2a8"))
	tutorial_toggle.toggled.connect(_on_tutorial_toggled)
	layout.add_child(tutorial_toggle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	layout.add_child(grid)

	_add_action_button(grid, "Save Game", _on_save_pressed)
	_add_action_button(grid, "Load Game", _on_load_pressed)
	_add_action_button(grid, "Reset Save", _show_reset_confirmation)
	_add_action_button(grid, "Credits", _show_credits)

	feedback_label = _make_label("", 26, Color("#f5d66f"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(860, 330)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	credits_label = _make_label("", 20, Color("#e8dfca"))
	credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_label.custom_minimum_size = Vector2(840, 0)
	credits_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(credits_label)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): SoundManager.play_click(); closed.emit())
	layout.add_child(back_button)

	_build_reset_confirmation()


func _add_slider_row(parent: VBoxContainer, text: String) -> HSlider:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.84), Color("#b99245"), 1, 8))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)

	var label := _make_label(text, 26, Color("#fff2a8"))
	label.custom_minimum_size = Vector2(250, 48)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(500, 48)
	row.add_child(slider)
	return slider


func _add_action_button(parent: GridContainer, text: String, callback: Callable) -> void:
	var button := _make_button(text)
	button.pressed.connect(callback)
	parent.add_child(button)


func _refresh_controls() -> void:
	if music_slider:
		music_slider.set_value_no_signal(GameState.music_volume)
	if sfx_slider:
		sfx_slider.set_value_no_signal(GameState.sfx_volume)
	if tutorial_toggle:
		tutorial_toggle.set_pressed_no_signal(not GameState.has_seen_tutorial)


func _on_tutorial_toggled(enabled: bool) -> void:
	SoundManager.play_switch()
	GameState.has_seen_tutorial = not enabled
	GameState.save_game()
	feedback_label.text = "Tutorial on." if enabled else "Tutorial off."


func _on_save_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	feedback_label.text = "Game saved."


func _on_load_pressed() -> void:
	SoundManager.play_click()
	GameState.load_game()
	_refresh_controls()
	feedback_label.text = "Game loaded."


func _show_reset_confirmation() -> void:
	SoundManager.play_click()
	confirm_panel.visible = true
	feedback_label.text = "Confirm reset save?"


func _confirm_reset_save() -> void:
	SoundManager.play_click()
	GameState.reset_save()
	_refresh_controls()
	confirm_panel.visible = false
	feedback_label.text = "Save reset."


func _show_credits() -> void:
	SoundManager.play_click()
	var credits_path := "res://data/ASSET_CREDITS.md"
	if not FileAccess.file_exists(credits_path):
		credits_label.text = "No asset credits file found."
		feedback_label.text = "Credits unavailable."
		return

	var file := FileAccess.open(credits_path, FileAccess.READ)
	if file == null:
		credits_label.text = "Unable to open credits."
		feedback_label.text = "Credits unavailable."
		return

	credits_label.text = file.get_as_text()
	feedback_label.text = "Credits loaded."


func _build_reset_confirmation() -> void:
	confirm_panel = PanelContainer.new()
	confirm_panel.visible = false
	confirm_panel.position = Vector2(150, 760)
	confirm_panel.size = Vector2(780, 290)
	confirm_panel.add_theme_stylebox_override("panel", _make_style(Color(0.025, 0.02, 0.03, 0.98), Color("#f0cf76"), 3, 12))
	add_child(confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	confirm_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	var warning := _make_label("Reset Save?", 34, Color("#f5d66f"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(warning)
	var body := _make_label("This clears local progress and starts fresh.", 24, Color("#fff2d6"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	layout.add_child(row)

	var confirm := _make_button("Confirm")
	confirm.pressed.connect(_confirm_reset_save)
	row.add_child(confirm)

	var cancel := _make_button("Cancel")
	cancel.pressed.connect(func(): SoundManager.play_click(); confirm_panel.visible = false)
	row.add_child(cancel)


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
