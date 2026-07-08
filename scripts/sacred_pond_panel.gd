extends PanelContainer

signal closed
signal decorate_requested

var stats_label: Label
var feedback_label: Label
var pond_preview: CanvasItem
var decoration_preview_layer: Control

const PANEL_BUTTONS := {
	"Back": "res://assets/sprites/ui/panel_back.png",
	"Decorate": "res://assets/sprites/ui/panel_decorate.png",
	"Restore": "res://assets/sprites/ui/panel_restore.png",
	"Upgrades": "res://assets/sprites/ui/panel_upgrades.png",
}

func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	_build_decoration_preview_layer()
	GameState.sacred_pond_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	pond_preview = get_node_or_null("Root/PondBackground") as CanvasItem

	var restore_button := get_node("Root/ActionRow/RestoreButton") as TextureButton
	var decorate_button := get_node("Root/ActionRow/DecorateButton") as TextureButton
	var upgrades_button := get_node("Root/ActionRow/UpgradesButton") as TextureButton
	var back_button := get_node("Root/ActionRow/BackButton") as TextureButton
	restore_button.pressed.connect(_on_restore_pressed)
	decorate_button.pressed.connect(_on_decorate_pressed)
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pond_preview = _add_zoom_background("res://assets/sprites/panels/sacred_pond_zoom.png")

	var stats_margin := MarginContainer.new()
	stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_margin.add_theme_constant_override("margin_left", 74)
	stats_margin.add_theme_constant_override("margin_right", 74)
	stats_margin.add_theme_constant_override("margin_top", 1324)
	stats_margin.add_theme_constant_override("margin_bottom", 340)
	add_child(stats_margin)

	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _make_dark_panel_style(0.72))
	stats_margin.add_child(stats_panel)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 21)
	stats_label.add_theme_color_override("font_color", Color("#fff4c6"))
	stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats_label.add_theme_constant_override("shadow_offset_x", 2)
	stats_label.add_theme_constant_override("shadow_offset_y", 2)
	stats_panel.add_child(stats_label)

	var feedback_margin := MarginContainer.new()
	feedback_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_margin.add_theme_constant_override("margin_left", 96)
	feedback_margin.add_theme_constant_override("margin_right", 96)
	feedback_margin.add_theme_constant_override("margin_top", 1562)
	feedback_margin.add_theme_constant_override("margin_bottom", 266)
	add_child(feedback_margin)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	feedback_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 2)
	feedback_margin.add_child(feedback_label)

	var button_margin := MarginContainer.new()
	button_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	button_margin.add_theme_constant_override("margin_left", 36)
	button_margin.add_theme_constant_override("margin_right", 36)
	button_margin.add_theme_constant_override("margin_top", 1608)
	button_margin.add_theme_constant_override("margin_bottom", 44)
	add_child(button_margin)

	var button_panel := PanelContainer.new()
	button_panel.add_theme_stylebox_override("panel", _make_button_bar_style())
	button_margin.add_child(button_panel)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	button_panel.add_child(buttons)
	buttons.add_child(_make_panel_nav_button("Restore", _on_restore_pressed))
	buttons.add_child(_make_panel_nav_button("Decorate", _on_decorate_pressed))
	buttons.add_child(_make_panel_nav_button("Upgrades", _on_upgrades_pressed))
	buttons.add_child(_make_panel_nav_button("Back", _on_back_pressed))


func _make_panel_nav_button(button_name: String, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.name = "%sPanelButton" % button_name
	button.texture_normal = load(PANEL_BUTTONS[button_name])
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.custom_minimum_size = Vector2(238, 238)
	button.size = Vector2(238, 238)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): button.modulate = Color(1.12, 1.08, 0.95, 1.0))
	button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
	button.button_down.connect(func(): button.modulate = Color(0.86, 0.80, 0.68, 1.0))
	button.button_up.connect(func(): button.modulate = Color.WHITE)
	return button


func _build_pond_preview() -> void:
	_add_sprite(pond_preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(72, 42), Vector2(776, 556))
	_add_sprite(pond_preview, "res://assets/sprites/buildings/sacred_pond_scene.png", Vector2(250, 58), Vector2(420, 380))
	_add_sprite(pond_preview, "res://assets/sprites/environment/waterfall_small.png", Vector2(545, 74), Vector2(150, 90))
	_add_sprite(pond_preview, "res://assets/sprites/environment/bloom_lilypad.png", Vector2(168, 350), Vector2(160, 110))

	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_gold.png", Vector2(310, 190), Vector2(118, 96))
	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_blue.png", Vector2(470, 238), Vector2(112, 88))
	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_pink.png", Vector2(558, 326), Vector2(116, 88))

	for offset in [Vector2(120, 72), Vector2(760, 96), Vector2(110, 530), Vector2(744, 520)]:
		_add_sprite(pond_preview, "res://assets/sprites/environment/moon_lantern.png", offset, Vector2(52, 88))
	for offset in [Vector2(408, 76), Vector2(702, 318), Vector2(202, 390)]:
		_add_sprite(pond_preview, "res://assets/sprites/effects/glow_orb.png", offset, Vector2(54, 54))


func _add_sprite(parent: Node, path: String, top_left: Vector2, size: Vector2) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture:
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	parent.add_child(sprite)
	return sprite


func _add_zoom_background(path: String) -> TextureRect:
	var background := TextureRect.new()
	background.texture = load(path)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	return background


func _add_swimming_koi() -> void:
	var koi_specs := [
		{
			"path": "res://assets/sprites/characters/koi_gold.png",
			"start": Vector2(285, 690),
			"end": Vector2(640, 600),
			"size": Vector2(110, 78),
			"duration": 5.2
		},
		{
			"path": "res://assets/sprites/characters/koi_blue.png",
			"start": Vector2(710, 830),
			"end": Vector2(430, 755),
			"size": Vector2(102, 72),
			"duration": 6.0
		},
		{
			"path": "res://assets/sprites/characters/koi_pink.png",
			"start": Vector2(380, 1010),
			"end": Vector2(760, 1085),
			"size": Vector2(106, 74),
			"duration": 6.6
		}
	]

	for spec in koi_specs:
		var koi := _add_sprite(self, spec["path"], Vector2.ZERO, spec["size"])
		koi.z_index = 3
		koi.modulate = Color(1.0, 1.0, 1.0, 0.88)
		_animate_koi_loop(koi, spec["start"], spec["end"], float(spec["duration"]))


func _animate_koi_loop(koi: Sprite2D, start_position: Vector2, end_position: Vector2, duration: float) -> void:
	koi.position = start_position
	koi.rotation = (end_position - start_position).angle()
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(koi, "position", end_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (end_position - start_position).angle() + 0.10, duration * 0.5)
	tween.tween_property(koi, "position", start_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (start_position - end_position).angle() - 0.10, duration * 0.5)


func _make_dark_panel_style(alpha: float = 0.78) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, alpha)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _make_button_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.025, 0.68)
	style.border_color = Color("#6f5327")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _refresh() -> void:
	stats_label.text = (
		"Water Purity: %d%%    Spirit Energy: %d    Pond Beauty: %d\nRestore Cost: %d Mana    Base Restore Amount: +%d%%    Fairy Restore Bonus: +%d%%\nDecoration Bonus: +%d%%    Total Restore Amount: +%d%%\nActive Pond Bonus: %s\nNext Reward: %s"
		% [
			GameState.sacred_pond_water_purity,
			GameState.sacred_pond_spirit_energy,
			GameState.pond_beauty,
			GameState.sacred_pond_restore_cost,
			GameState.get_sacred_pond_base_restore_amount(),
			GameState.get_sacred_pond_fairy_restore_bonus(),
			GameState.get_pond_decoration_restore_bonus(),
			GameState.get_sacred_pond_total_restore_amount(),
			GameState.get_active_pond_bonus_text(),
			GameState.get_next_pond_reward_text()
		]
	)
	_refresh_decoration_preview()


func _build_decoration_preview_layer() -> void:
	decoration_preview_layer = Control.new()
	decoration_preview_layer.name = "Pond Decoration Preview"
	decoration_preview_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decoration_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Root"):
		get_node("Root").add_child(decoration_preview_layer)
	else:
		add_child(decoration_preview_layer)


func _refresh_decoration_preview() -> void:
	if decoration_preview_layer == null:
		return
	for child in decoration_preview_layer.get_children():
		child.queue_free()
	for decoration in GameState.pond_decorations:
		if not bool(decoration.get("IsPlaced", false)):
			continue
		var decoration_name := String(decoration.get("DecorationName", ""))
		var marker_size := _pond_decoration_preview_size(decoration_name)
		var marker := _add_sprite(
			decoration_preview_layer,
			_pond_decoration_sprite_path(decoration_name),
			GameState.get_pond_decoration_position(decoration) - marker_size * 0.5,
			marker_size
		)
		marker.z_index = 4
		marker.modulate.a = 0.94


func _pond_decoration_sprite_path(decoration_name: String) -> String:
	if decoration_name == "Moon Lantern":
		return "res://assets/sprites/environment/moon_lantern.png"
	if decoration_name == "Spirit Stone":
		return "res://assets/sprites/environment/spirit_stone.png"
	if decoration_name == "Bloom Lilypad":
		return "res://assets/sprites/environment/bloom_lilypad.png"
	if decoration_name == "Sacred Bridge":
		return "res://assets/sprites/environment/sacred_bridge.png"
	return "res://assets/sprites/effects/glow_orb.png"


func _pond_decoration_preview_size(decoration_name: String) -> Vector2:
	if decoration_name == "Moon Lantern":
		return Vector2(110, 136)
	if decoration_name == "Spirit Stone":
		return Vector2(120, 120)
	if decoration_name == "Bloom Lilypad":
		return Vector2(128, 94)
	if decoration_name == "Sacred Bridge":
		return Vector2(154, 100)
	return Vector2(108, 108)


func _on_restore_pressed() -> void:
	SoundManager.play_click()
	var restore_amount := GameState.get_sacred_pond_total_restore_amount()
	if GameState.restore_sacred_pond():
		feedback_label.text = "Water Purity +%d%%" % restore_amount
		_show_floating_text("Water Purity +%d%%" % restore_amount, Vector2(330, 830), Color("#80d6ff"))
		_flash_panel()
	else:
		feedback_label.text = "Not enough Mana"
		_show_floating_text("Not enough Mana", Vector2(330, 830), Color("#ff9f8a"))


func _on_decorate_pressed() -> void:
	SoundManager.play_click()
	decorate_requested.emit()


func _on_upgrades_pressed() -> void:
	SoundManager.play_click()
	feedback_label.text = "Pond upgrades coming soon."
	_show_floating_text("Pond upgrades coming soon", Vector2(250, 1450), Color("#f3d57a"))


func _on_remove_pressed() -> void:
	SoundManager.play_click()
	feedback_label.text = "Open Decorate to remove pond decorations."
	decorate_requested.emit()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = start_position
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -90), 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)


func _flash_panel() -> void:
	if pond_preview == null:
		return
	var original := pond_preview.modulate
	var tween := create_tween()
	tween.tween_property(pond_preview, "modulate", Color("#9ee8ff"), 0.12)
	tween.tween_property(pond_preview, "modulate", original, 0.28)
