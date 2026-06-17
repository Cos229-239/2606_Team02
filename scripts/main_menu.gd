extends Control

var continue_button: Button
var confirm_panel: PanelContainer
var feedback_label: Label


func _ready() -> void:
	_build_menu()
	GameState.save_status_changed.connect(_show_feedback)
	_refresh_buttons()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = Color("#061511")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var glow := Polygon2D.new()
	glow.color = Color("#113f35", 0.72)
	glow.polygon = PackedVector2Array([
		Vector2(120, 360), Vector2(960, 280), Vector2(1010, 1520), Vector2(90, 1620)
	])
	add_child(glow)

	var title := Label.new()
	title.text = "Mystic Grove"
	title.position = Vector2(130, 330)
	title.size = Vector2(820, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Restore the magic of the grove."
	subtitle.position = Vector2(150, 430)
	subtitle.size = Vector2(780, 96)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	add_child(subtitle)

	var buttons := VBoxContainer.new()
	buttons.position = Vector2(300, 640)
	buttons.add_theme_constant_override("separation", 24)
	add_child(buttons)

	buttons.add_child(_make_button("Play", _on_play_pressed))
	continue_button = _make_button("Continue", _on_continue_pressed)
	buttons.add_child(continue_button)
	buttons.add_child(_make_button("Reset Save", _on_reset_pressed))
	buttons.add_child(_make_button("Quit", _on_quit_pressed))

	feedback_label = Label.new()
	feedback_label.position = Vector2(150, 1200)
	feedback_label.size = Vector2(780, 70)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	feedback_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(feedback_label)

	var version := Label.new()
	version.text = "Build: Demo Build 01"
	version.position = Vector2(36, 1828)
	version.size = Vector2(420, 48)
	version.add_theme_font_size_override("font_size", 22)
	version.add_theme_color_override("font_color", Color("#fff2a8"))
	version.add_theme_color_override("font_shadow_color", Color.BLACK)
	version.add_theme_constant_override("shadow_offset_x", 2)
	version.add_theme_constant_override("shadow_offset_y", 2)
	add_child(version)


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(480, 90)
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(callback)
	return button


func _refresh_buttons() -> void:
	if continue_button:
		continue_button.disabled = not GameState.save_exists()


func _on_play_pressed() -> void:
	if not GameState.save_exists():
		GameState.reset_to_defaults()
	_go_to_start_scene()


func _on_continue_pressed() -> void:
	GameState.load_game()
	_go_to_start_scene()


func _go_to_start_scene() -> void:
	if GameState.has_completed_onboarding:
		get_tree().change_scene_to_file("res://scenes/MainVillage.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/AbandonedNook.tscn")


func _on_reset_pressed() -> void:
	_show_reset_confirmation()


func _show_reset_confirmation() -> void:
	if confirm_panel:
		confirm_panel.queue_free()

	confirm_panel = PanelContainer.new()
	confirm_panel.position = Vector2(160, 980)
	confirm_panel.size = Vector2(760, 310)
	confirm_panel.self_modulate = Color(0.015, 0.02, 0.045, 0.96)
	add_child(confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	confirm_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var label := Label.new()
	label.text = "Reset Save?\nThis clears local playtest progress."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	layout.add_child(label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	layout.add_child(row)
	row.add_child(_make_button("Confirm Reset", _confirm_reset))
	row.add_child(_make_button("Cancel", _cancel_reset))


func _confirm_reset() -> void:
	GameState.reset_save()
	_cancel_reset()
	_refresh_buttons()


func _cancel_reset() -> void:
	if confirm_panel:
		confirm_panel.queue_free()
		confirm_panel = null


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_feedback(message: String) -> void:
	if feedback_label:
		feedback_label.text = message
