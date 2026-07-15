extends Control

var continue_button: Button
var reset_overlay: ColorRect
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

	_build_reset_confirmation()


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
	reset_overlay.visible = true
	feedback_label.text = "Reset needs confirmation."


func _confirm_reset() -> void:
	GameState.reset_save()
	_hide_reset_confirmation("Save reset.")
	_refresh_buttons()


func _cancel_reset() -> void:
	_hide_reset_confirmation("Reset cancelled.")


func _hide_reset_confirmation(message: String) -> void:
	if reset_overlay:
		reset_overlay.visible = false
	if feedback_label:
		feedback_label.text = message


func _build_reset_confirmation() -> void:
	reset_overlay = ColorRect.new()
	reset_overlay.name = "ResetConfirmationOverlay"
	reset_overlay.visible = false
	reset_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reset_overlay.color = Color(0.0, 0.0, 0.0, 0.58)
	add_child(reset_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	reset_overlay.add_child(center)

	confirm_panel = PanelContainer.new()
	confirm_panel.name = "ResetConfirmationPanel"
	confirm_panel.custom_minimum_size = Vector2(820, 360)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color("#0a0e16", 0.96)
	confirm_style.border_color = Color("#f3d57a", 0.68)
	confirm_style.set_border_width_all(3)
	confirm_style.corner_radius_top_left = 16
	confirm_style.corner_radius_top_right = 16
	confirm_style.corner_radius_bottom_left = 16
	confirm_style.corner_radius_bottom_right = 16
	confirm_panel.add_theme_stylebox_override("panel", confirm_style)
	center.add_child(confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	confirm_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Reset Save?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(title)

	var body := Label.new()
	body.text = "This clears local progress and restarts the tutorial. This cannot be undone."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(720, 92)
	body.add_theme_font_size_override("font_size", 24)
	body.add_theme_color_override("font_color", Color("#fff2d6"))
	body.add_theme_color_override("font_shadow_color", Color.BLACK)
	body.add_theme_constant_override("shadow_offset_x", 2)
	body.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	layout.add_child(row)

	var confirm := _make_button("Reset Save", _confirm_reset)
	confirm.name = "ConfirmResetButton"
	confirm.custom_minimum_size = Vector2(330, 80)
	confirm.add_theme_font_size_override("font_size", 26)
	row.add_child(confirm)

	var cancel := _make_button("Cancel", _cancel_reset)
	cancel.name = "CancelResetButton"
	cancel.custom_minimum_size = Vector2(330, 80)
	cancel.add_theme_font_size_override("font_size", 26)
	row.add_child(cancel)


func _on_quit_pressed() -> void:
	SoundManager.play_click()
	get_tree().quit()


func _show_feedback(message: String) -> void:
	if feedback_label:
		feedback_label.text = message


func _add_sprite(path: String, top_left: Vector2, sprite_size: Vector2, sprite_rotation: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := _load_texture(path)
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


func _load_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture:
		return texture

	var image := Image.new()
	if image.load(path) == OK:
		return ImageTexture.create_from_image(image)

	push_warning("Texture failed to load: %s" % path)
	return null
