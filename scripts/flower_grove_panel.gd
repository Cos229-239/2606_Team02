extends PanelContainer

signal closed

var stats_label: Label
var stats_right_label: Label
var feedback_label: Label
var stored_mana_value_label: Label
var production_value_label: Label
var collect_button: Button
var unlock_button: Button
var garden_preview: Control
var panel_body: VBoxContainer
var grid_container: GridContainer
var grid_slot_buttons: Array[Button] = []
var dragged_slot_index: int = -1

func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	GameState.flower_grove_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	stats_right_label = get_node_or_null("Root/StatsRightLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	stored_mana_value_label = get_node_or_null("Root/StoredManaPanelValue") as Label
	production_value_label = get_node_or_null("Root/ProductionPanelValue") as Label
	var preview_node := get_node_or_null("Root/GardenPreviewLayer") as Control
	garden_preview = preview_node if preview_node and bool(preview_node.get_meta("runtime_preview", false)) else null
	grid_container = get_node("Root/MergeGridPanel/MergeGrid") as GridContainer
	panel_body = get_node_or_null("Root/PanelBody") as VBoxContainer

	grid_slot_buttons.clear()
	for index in range(GameState.FLOWER_GRID_SLOT_COUNT):
		var slot_button := get_node("Root/MergeGridPanel/MergeGrid/GridSlot%d" % index) as Button
		slot_button.gui_input.connect(func(event: InputEvent) -> void:
			_on_grid_slot_gui_input(index, event)
		)
		slot_button.pressed.connect(func() -> void:
			_on_grid_slot_pressed(index)
		)
		grid_slot_buttons.append(slot_button)

	collect_button = get_node("Root/ActionRow/CollectManaButton") as Button
	var upgrade_button := get_node("Root/ActionRow/UpgradeFlowerButton") as Button
	unlock_button = get_node("Root/ActionRow/UnlockPlotButton") as Button
	var back_button := get_node("Root/ActionRow/BackButton") as Button
	collect_button.pressed.connect(_on_collect_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	unlock_button.pressed.connect(_on_unlock_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_zoom_background("res://assets/sprites/panels/flower_grove_zoom.png")

	_build_merge_grid()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_top", 1210)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)

	var content_panel := PanelContainer.new()
	content_panel.self_modulate = Color(1, 1, 1, 0.92)
	content_panel.add_theme_stylebox_override("panel", _make_dark_panel_style())
	margin.add_child(content_panel)

	panel_body = VBoxContainer.new()
	panel_body.add_theme_constant_override("separation", 10)
	content_panel.add_child(panel_body)

	var title := Label.new()
	title.text = "Flower Grove"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.visible = false
	panel_body.add_child(title)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats_label.add_theme_constant_override("shadow_offset_x", 2)
	stats_label.add_theme_constant_override("shadow_offset_y", 2)
	panel_body.add_child(stats_label)
	stats_right_label = null

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	panel_body.add_child(feedback_label)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 18)
	buttons.add_theme_constant_override("v_separation", 18)
	panel_body.add_child(buttons)

	collect_button = _make_button("Collect Mana", _on_collect_pressed)
	buttons.add_child(collect_button)
	buttons.add_child(_make_button("Upgrade Flower", _on_upgrade_pressed))
	unlock_button = _make_button("Unlock Plot", _on_unlock_pressed)
	buttons.add_child(unlock_button)
	buttons.add_child(_make_button("Back", _on_back_pressed))


func _build_merge_grid() -> void:
	var grid_margin := MarginContainer.new()
	grid_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_margin.add_theme_constant_override("margin_left", 136)
	grid_margin.add_theme_constant_override("margin_right", 136)
	grid_margin.add_theme_constant_override("margin_top", 610)
	grid_margin.add_theme_constant_override("margin_bottom", 800)
	add_child(grid_margin)

	var grid_panel := PanelContainer.new()
	grid_panel.add_theme_stylebox_override("panel", _make_grid_panel_style())
	grid_margin.add_child(grid_panel)

	grid_container = GridContainer.new()
	grid_container.columns = GameState.FLOWER_GRID_COLUMNS
	grid_container.add_theme_constant_override("h_separation", 14)
	grid_container.add_theme_constant_override("v_separation", 14)
	grid_panel.add_child(grid_container)

	for index in range(GameState.FLOWER_GRID_SLOT_COUNT):
		var slot_button := Button.new()
		slot_button.custom_minimum_size = Vector2(248, 110)
		slot_button.add_theme_font_size_override("font_size", 18)
		slot_button.add_theme_color_override("font_color", Color("#fff2a8"))
		slot_button.add_theme_color_override("font_shadow_color", Color.BLACK)
		slot_button.add_theme_constant_override("shadow_offset_x", 2)
		slot_button.add_theme_constant_override("shadow_offset_y", 2)
		slot_button.gui_input.connect(func(event: InputEvent) -> void:
			_on_grid_slot_gui_input(index, event)
		)
		slot_button.pressed.connect(func() -> void:
			_on_grid_slot_pressed(index)
		)
		grid_slot_buttons.append(slot_button)
		grid_container.add_child(slot_button)


func _rebuild_garden_preview() -> void:
	if garden_preview == null:
		return
	for child in garden_preview.get_children():
		child.queue_free()

	_add_sprite(garden_preview, "res://assets/sprites/buildings/flower_grove_scene.png", Vector2(260, 28), Vector2(390, 430))
	_add_sprite(garden_preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(40, 18), Vector2(840, 470))

	for index in range(GameState.flower_grove_max_plots):
		var active := index < GameState.flower_grove_active_plots
		var plot_position := Vector2(104 + (index % 3) * 260, 102 + int(index / 3) * 185)
		if active:
			var flower_path: String = [
				"res://assets/sprites/environment/blue_bloom.png",
				"res://assets/sprites/environment/purple_bloom.png",
				"res://assets/sprites/environment/golden_bloom.png"
			][index % 3]
			_add_sprite(garden_preview, flower_path, plot_position + Vector2(48, -42), Vector2(106, 118))
			_add_sprite(garden_preview, "res://assets/sprites/effects/glow_orb.png", plot_position + Vector2(126, 16), Vector2(32, 32))
		else:
			_add_sprite(garden_preview, "res://assets/sprites/environment/fence_cross.png", plot_position + Vector2(60, 14), Vector2(64, 64))

		var label := Label.new()
		label.text = "Active Plot" if active else "Locked Plot"
		label.position = plot_position + Vector2(12, 98)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#fff2a8") if active else Color("#9b8d9b"))
		garden_preview.add_child(label)


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


func _add_zoom_background(path: String) -> void:
	var background := TextureRect.new()
	background.texture = load(path)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _make_grid_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, 0.52)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _make_slot_style(bg_color: Color, border_color: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_dark_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, 0.78)
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


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 76)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	return button


func _refresh() -> void:
	var unlock_cost_text := "All Unlocked" if GameState.flower_grove_active_plots >= GameState.flower_grove_max_plots else "%d Mana" % GameState.get_flower_unlock_cost()
	var left_stats_text := (
		"Level: %d\nStored Mana: %d / %d\nActive Plots: %d / %d\nUpgrade Cost: %d Mana"
		% [
			GameState.flower_grove_level,
			int(floor(GameState.flower_grove_stored_mana)),
			GameState.flower_grove_max_stored_mana,
			GameState.flower_grove_active_plots,
			GameState.flower_grove_max_plots,
			GameState.get_flower_upgrade_cost()
		]
	)
	var right_stats_text := (
		"Grid Production: +%d/sec\nBase Production: +%d/sec\nFairy Bonus: +%d/sec\nTotal Production: +%d/sec\nUnlock Plot Cost: %s"
		% [
			GameState.get_flower_grid_production_rate(),
			int(GameState.get_flower_base_production_rate()),
			int(GameState.get_flower_fairy_bonus_production()),
			int(GameState.get_flower_production_rate()),
			unlock_cost_text
		]
	)
	stats_label.text = left_stats_text
	if stats_right_label:
		stats_right_label.text = right_stats_text
	else:
		stats_label.text = "%s\n%s" % [left_stats_text, right_stats_text]
	if unlock_button:
		unlock_button.disabled = GameState.flower_grove_active_plots >= GameState.flower_grove_max_plots
	if stored_mana_value_label:
		stored_mana_value_label.text = "%d / %d" % [
			int(floor(GameState.flower_grove_stored_mana)),
			GameState.flower_grove_max_stored_mana
		]
	if production_value_label:
		production_value_label.text = "+%d / sec" % int(GameState.get_flower_production_rate())
	_rebuild_garden_preview()
	_rebuild_flower_grid()


func _rebuild_flower_grid(match_tier: int = GameState.FLOWER_TIER_EMPTY) -> void:
	for index in range(grid_slot_buttons.size()):
		var button := grid_slot_buttons[index]
		var slot := GameState.get_flower_grid_slot(index)
		var tier := int(slot.get("Tier", GameState.FLOWER_TIER_EMPTY))
		var locked := bool(slot.get("Locked", false))
		var tier_data := GameState.get_flower_tier_data(tier)
		var production := int(tier_data.get("ManaProductionRate", 0))
		if button.has_node("PlotTexture"):
			_update_visual_grid_slot(button, tier, locked, tier_data, production, match_tier)
			continue
		if locked:
			button.text = "Locked"
			button.disabled = true
			button.add_theme_stylebox_override("normal", _make_slot_style(Color(0.02, 0.02, 0.025, 0.72), Color("#5a4a32")))
			continue
		button.disabled = false
		if tier == GameState.FLOWER_TIER_EMPTY:
			button.text = "Empty\nTap to plant Seed"
			button.add_theme_stylebox_override("normal", _make_slot_style(Color(0.02, 0.03, 0.025, 0.74), Color("#6f5327")))
		else:
			button.text = "%s\nTier %d\n+%d/sec" % [String(tier_data.get("Name", "Flower")), tier, production]
			var is_match := match_tier > GameState.FLOWER_TIER_EMPTY and tier == match_tier
			var border := Color("#fff2a8") if is_match else Color("#b98c43")
			var bg := Color(0.09, 0.15, 0.08, 0.88) if is_match else Color(0.025, 0.028, 0.035, 0.86)
			button.add_theme_stylebox_override("normal", _make_slot_style(bg, border, 3 if is_match else 2))
		button.add_theme_stylebox_override("hover", _make_slot_style(Color(0.10, 0.14, 0.08, 0.92), Color("#f3d57a"), 3))
		button.add_theme_stylebox_override("pressed", _make_slot_style(Color(0.14, 0.20, 0.10, 0.96), Color("#fff2a8"), 3))


func _update_visual_grid_slot(button: Button, tier: int, locked: bool, tier_data: Dictionary, production: int, match_tier: int) -> void:
	var plot_texture := button.get_node("PlotTexture") as TextureRect
	var slot_text := button.get_node_or_null("SlotText") as Label
	button.text = ""
	button.disabled = locked
	button.modulate = Color(1, 1, 1, 0.58) if locked else Color.WHITE

	if locked:
		plot_texture.texture = load("res://assets/sprites/flower_grove/plot_locked.png")
		if slot_text:
			slot_text.text = "Unlocks\nLater"
			slot_text.add_theme_color_override("font_color", Color("#c6baa1"))
		return

	var sprite_path := String(tier_data.get("Sprite", ""))
	if tier == GameState.FLOWER_TIER_EMPTY or sprite_path.is_empty():
		plot_texture.texture = load("res://assets/sprites/flower_grove/plot_tap_to_plant.png")
	else:
		plot_texture.texture = load(sprite_path)
	if slot_text:
		if tier == GameState.FLOWER_TIER_EMPTY:
			slot_text.text = "Tap to Plant"
			slot_text.add_theme_color_override("font_color", Color("#fff4cf"))
		else:
			var is_match := match_tier > GameState.FLOWER_TIER_EMPTY and tier == match_tier
			slot_text.text = "%s\nTier %d\n+%d/sec" % [String(tier_data.get("Name", "Flower")), tier, production]
			slot_text.add_theme_color_override("font_color", Color("#9fd7ff") if is_match else Color("#fff4cf"))
	if match_tier > GameState.FLOWER_TIER_EMPTY and tier == match_tier:
		button.modulate = Color("#fff2a8")


func _on_grid_slot_pressed(slot_index: int) -> void:
	SoundManager.play_click()
	var result := GameState.plant_seed_in_flower_slot(slot_index)
	if result == 1:
		feedback_label.text = "Seed planted."
		_show_floating_text("Seed planted", Vector2(400, 970), Color("#a8ff9b"))
	elif GameState.is_flower_grid_full():
		feedback_label.text = "Garden is full -- merge to make space."


func _on_grid_slot_gui_input(slot_index: int, event: InputEvent) -> void:
	var slot := GameState.get_flower_grid_slot(slot_index)
	var tier := int(slot.get("Tier", GameState.FLOWER_TIER_EMPTY))
	if bool(slot.get("Locked", false)) or tier == GameState.FLOWER_TIER_EMPTY:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragged_slot_index = slot_index
			_rebuild_flower_grid(tier)
		else:
			_finish_grid_drag()
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragged_slot_index = slot_index
			_rebuild_flower_grid(tier)
		else:
			_finish_grid_drag()


func _finish_grid_drag() -> void:
	if dragged_slot_index < 0:
		return
	var target_slot := _get_grid_slot_at_position(get_global_mouse_position())
	if target_slot >= 0:
		var merge_result := GameState.merge_flower_grid_slots(dragged_slot_index, target_slot)
		if bool(merge_result.get("Success", false)):
			SoundManager.play_merge()
			var reward := int(merge_result.get("Reward", 0))
			feedback_label.text = "%s +%d Mana" % [String(merge_result.get("Message", "Merged!")), reward]
			_show_floating_text("+%d Mana" % reward, Vector2(420, 920), Color("#f3d57a"))
			_pulse_garden_preview()
		else:
			feedback_label.text = String(merge_result.get("Message", "Flowers must match to merge."))
	dragged_slot_index = -1
	_rebuild_flower_grid()


func _get_grid_slot_at_position(global_position: Vector2) -> int:
	for index in range(grid_slot_buttons.size()):
		var button := grid_slot_buttons[index]
		var rect := Rect2(button.global_position, button.size)
		if rect.has_point(global_position):
			return index
	return -1


func _on_collect_pressed() -> void:
	SoundManager.play_collect()
	var collected := GameState.collect_flower_mana()
	if collected > 0:
		feedback_label.text = "+%d Mana" % collected
		_show_floating_text("+%d Mana" % collected, Vector2(420, 840), Color("#f3d57a"))
		_flash_button(collect_button)
	else:
		feedback_label.text = "No mana ready yet."


func _on_upgrade_pressed() -> void:
	SoundManager.play_click()
	if GameState.upgrade_flower_grove():
		feedback_label.text = "Flower Grove upgraded!"
		_show_floating_text("Flower Grove upgraded!", Vector2(300, 840), Color("#a8ff9b"))
		_pulse_garden_preview()
	else:
		feedback_label.text = "Not enough mana."


func _on_unlock_pressed() -> void:
	SoundManager.play_click()
	var result := GameState.unlock_flower_plot()
	if result == 1:
		feedback_label.text = "New flower plot unlocked!"
		_show_floating_text("New flower plot unlocked!", Vector2(260, 840), Color("#a8ff9b"))
		_rebuild_garden_preview()
		_pulse_garden_preview()
	elif result == 0:
		feedback_label.text = "All plots unlocked."
		if unlock_button:
			unlock_button.disabled = true
	else:
		feedback_label.text = "Not enough mana."


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


func _flash_button(button: Button) -> void:
	var original := button.modulate
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color("#fff2a8"), 0.08)
	tween.tween_property(button, "modulate", original, 0.18)


func _pulse_garden_preview() -> void:
	if garden_preview == null:
		if grid_container == null:
			return
		var original_grid := grid_container.modulate
		var grid_tween := create_tween()
		grid_tween.tween_property(grid_container, "modulate", Color("#fff2a8"), 0.10)
		grid_tween.tween_property(grid_container, "modulate", original_grid, 0.25)
		return
	var original := garden_preview.modulate
	var tween := create_tween()
	tween.tween_property(garden_preview, "modulate", Color("#fff2a8"), 0.10)
	tween.tween_property(garden_preview, "modulate", original, 0.25)
