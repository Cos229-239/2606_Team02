extends Control

var continue_button: Button
var confirm_panel: PanelContainer
var feedback_label: Label


func _ready() -> void:
	_build_menu()
	GameState.save_status_changed.connect(_show_feedback)
	_refresh_buttons()


func _build_menu() -> void:
	var background := _add_sprite(
		"res://assets/sprites/backgrounds/main_menu_bg.png",
		Vector2(0, 0),
		Vector2(1080, 1920)
	)
	background.z_index = -10

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
	buttons.position = Vector2(300, 770)
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
	button.add_theme_color_override("font_color", Color("#fff2d6"))
	button.add_theme_color_override("font_hover_color", Color("#fff2d6"))
	button.add_theme_color_override("font_pressed_color", Color("#fff2d6"))
	button.add_theme_color_override("font_disabled_color", Color("#fff2d6", 0.45))
	button.add_theme_color_override("font_shadow_color", Color.BLACK)
	button.add_theme_constant_override("shadow_offset_x", 3)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.add_theme_stylebox_override("normal", _make_menu_button_style(false))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(false, true))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(false, true))
	button.add_theme_stylebox_override("disabled", _make_menu_button_style(true))
	button.pressed.connect(callback)
	return button


func _make_menu_button_style(disabled: bool, hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var alpha_mult := 0.5 if disabled else 1.0
	style.bg_color = Color("#1a1410", (0.78 if hover else 0.72) * alpha_mult)
	style.border_color = Color("#f3d57a", 0.55 * alpha_mult)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style


func _refresh_buttons() -> void:
	if continue_button:
		continue_button.disabled = not GameState.save_exists()


func _on_play_pressed() -> void:
	SoundManager.play_click()
	if not GameState.save_exists() and not GameState.show_tutorial_after_reset:
		GameState.reset_to_defaults()
	_go_to_start_scene()


func _on_continue_pressed() -> void:
	SoundManager.play_click()
	GameState.load_game()
	_go_to_start_scene()


func _go_to_start_scene() -> void:
	if GameState.has_completed_onboarding:
		get_tree().change_scene_to_file("res://scenes/MainVillage.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/AbandonedNook.tscn")


func _on_reset_pressed() -> void:
	SoundManager.play_click()
	_show_reset_confirmation()


func _show_reset_confirmation() -> void:
	if confirm_panel:
		confirm_panel.queue_free()

	confirm_panel = PanelContainer.new()
	confirm_panel.position = Vector2(160, 980)
	confirm_panel.size = Vector2(760, 310)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color("#0a0e16", 0.92)
	confirm_style.border_color = Color("#f3d57a", 0.55)
	confirm_style.set_border_width_all(2)
	confirm_style.corner_radius_top_left = 16
	confirm_style.corner_radius_top_right = 16
	confirm_style.corner_radius_bottom_left = 16
	confirm_style.corner_radius_bottom_right = 16
	confirm_panel.add_theme_stylebox_override("panel", confirm_style)
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
	label.text = "Reset Save?\nThis clears local progress."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	layout.add_child(label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	layout.add_child(row)
	row.add_child(_make_button("Confirm Reset", _confirm_reset))
	row.add_child(_make_button("Cancel", _cancel_reset))
	for btn in row.get_children():
		btn.custom_minimum_size = Vector2(330, 80)
		btn.add_theme_font_size_override("font_size", 26)


func _confirm_reset() -> void:
	GameState.reset_save()
	_cancel_reset()
	_refresh_buttons()


func _cancel_reset() -> void:
	if confirm_panel:
		confirm_panel.queue_free()
		confirm_panel = null


func _on_quit_pressed() -> void:
	SoundManager.play_click()
	get_tree().quit()


func _show_feedback(message: String) -> void:
	if feedback_label:
		feedback_label.text = message


func _add_sprite(path: String, top_left: Vector2, sprite_size: Vector2, sprite_rotation: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + sprite_size * 0.5
	sprite.rotation = sprite_rotation
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(sprite_size.x / texture.get_width(), sprite_size.y / texture.get_height())
	add_child(sprite)
	return sprite
