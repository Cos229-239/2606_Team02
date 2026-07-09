extends PanelContainer

signal closed

var stats_label: Label
var feedback_label: Label
var craft_button: Button
var progress_bar: ProgressBar
var shop_preview: CanvasItem
var recipe_title_label: Label
var recipe_description_label: Label
var requirements_label: Label
var potion_details_label: Label
var last_potion_count: int = 0
var selected_recipe_id: String = "mana_potion"
var recipe_buttons: Dictionary = {}
var upgrade_confirmation_pending: bool = false


func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	last_potion_count = GameState.get_total_potion_count()
	GameState.resources_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	progress_bar = get_node("Root/CraftProgressBar") as ProgressBar
	shop_preview = get_node_or_null("Root/Cauldron") as CanvasItem
	recipe_title_label = get_node_or_null("Root/RecipePanel/RecipeTitle") as Label
	recipe_description_label = get_node_or_null("Root/RecipePanel/RecipeDescription") as Label
	requirements_label = get_node_or_null("Root/RecipePanel/RequirementsLabel") as Label
	potion_details_label = get_node_or_null("Root/RecipePanel/PotionDetailsLabel") as Label
	if recipe_description_label:
		recipe_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_description_label.clip_text = true
		recipe_description_label.size = Vector2(530, 86)
	_build_recipe_selector(get_node("Root/RecipePanel") as Control)

	var buy_button := get_node("Root/ActionRow/BuyButton") as Button
	craft_button = get_node("Root/ActionRow/CraftPotionButton") as Button
	var sell_button := get_node("Root/ActionRow/SellPotionButton") as Button
	var upgrade_button := get_node("Root/ActionRow/UpgradeShopButton") as Button
	var back_button := get_node("Root/ActionRow/BackButton") as Button
	buy_button.tooltip_text = "Buy ingredients"
	craft_button.tooltip_text = "Craft Potion"
	sell_button.tooltip_text = "Sell Potion"
	upgrade_button.tooltip_text = "Upgrade Shop"
	back_button.tooltip_text = "Back"
	buy_button.pressed.connect(_on_buy_pressed)
	craft_button.pressed.connect(_on_craft_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	shop_preview = _add_zoom_background("res://assets/sprites/panels/potion_shop_zoom.png")

	var stats_margin := MarginContainer.new()
	stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_margin.add_theme_constant_override("margin_left", 288)
	stats_margin.add_theme_constant_override("margin_right", 288)
	stats_margin.add_theme_constant_override("margin_top", 150)
	stats_margin.add_theme_constant_override("margin_bottom", 1250)
	add_child(stats_margin)

	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _make_dark_panel_style(0.78))
	stats_margin.add_child(stats_panel)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 24)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats_label.add_theme_constant_override("shadow_offset_x", 2)
	stats_label.add_theme_constant_override("shadow_offset_y", 2)
	stats_panel.add_child(stats_label)

	var progress_margin := MarginContainer.new()
	progress_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_margin.add_theme_constant_override("margin_left", 248)
	progress_margin.add_theme_constant_override("margin_right", 248)
	progress_margin.add_theme_constant_override("margin_top", 1360)
	progress_margin.add_theme_constant_override("margin_bottom", 500)
	add_child(progress_margin)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(584, 34)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_margin.add_child(progress_bar)

	var feedback_margin := MarginContainer.new()
	feedback_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_margin.add_theme_constant_override("margin_left", 80)
	feedback_margin.add_theme_constant_override("margin_right", 80)
	feedback_margin.add_theme_constant_override("margin_top", 1460)
	feedback_margin.add_theme_constant_override("margin_bottom", 340)
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
	button_margin.add_theme_constant_override("margin_left", 24)
	button_margin.add_theme_constant_override("margin_right", 24)
	button_margin.add_theme_constant_override("margin_top", 1642)
	button_margin.add_theme_constant_override("margin_bottom", 118)
	add_child(button_margin)

	var button_panel := PanelContainer.new()
	button_panel.add_theme_stylebox_override("panel", _make_button_bar_style())
	button_margin.add_child(button_panel)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	button_panel.add_child(buttons)

	buttons.add_child(_make_button("Buy", _on_buy_pressed))
	craft_button = _make_button("Craft Potion", _on_craft_pressed)
	buttons.add_child(craft_button)
	buttons.add_child(_make_button("Sell Potion", _on_sell_pressed))
	buttons.add_child(_make_button("Upgrade Shop", _on_upgrade_pressed))
	buttons.add_child(_make_button("Back", _on_back_pressed))
	_build_recipe_selector(self)


func _make_shop_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(920, 520)

	_add_sprite(preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(44, 24), Vector2(826, 430))
	_add_sprite(preview, "res://assets/sprites/buildings/potion_shop_scene.png", Vector2(258, 52), Vector2(390, 390))
	_add_sprite(preview, "res://assets/sprites/characters/fairy_potion_maker.png", Vector2(645, 135), Vector2(102, 144))

	for offset in [Vector2(194, 282), Vector2(670, 278), Vector2(214, 368), Vector2(634, 370)]:
		_add_sprite(preview, "res://assets/sprites/effects/glow_orb.png", offset, Vector2(52, 52), Color("#b879ff"))
	for offset in [Vector2(210, 220), Vector2(682, 218), Vector2(176, 350), Vector2(704, 350)]:
		_add_sprite(preview, "res://assets/sprites/environment/blue_mushroom.png", offset, Vector2(52, 52))

	return preview


func _add_sprite(parent: Node, path: String, top_left: Vector2, sprite_size: Vector2, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + sprite_size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(sprite_size.x / texture.get_width(), sprite_size.y / texture.get_height())
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
	style.content_margin_left = 14
	style.content_margin_right = 14
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
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 88)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff2c6"))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.025, 0.028, 0.035, 0.92), Color("#9e7332")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.14, 0.08, 0.96), Color("#d0a246")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.16, 0.22, 0.10, 0.98), Color("#f3d57a")))
	button.pressed.connect(callback)
	return button


func _build_recipe_selector(parent: Control) -> void:
	var selector := HBoxContainer.new()
	selector.name = "RecipeSelector"
	selector.position = Vector2(374, 16) if parent.name == "RecipePanel" else Vector2(92, 1040)
	selector.size = Vector2(520, 58)
	selector.add_theme_constant_override("separation", 10)
	parent.add_child(selector)

	for recipe in GameState.get_potion_recipes():
		var recipe_id := String(recipe.get("RecipeID", ""))
		var button := Button.new()
		button.text = String(recipe.get("Name", "Potion"))
		button.custom_minimum_size = Vector2(245, 58)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func(): _select_recipe(recipe_id))
		selector.add_child(button)
		recipe_buttons[recipe_id] = button


func _select_recipe(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	upgrade_confirmation_pending = false
	SoundManager.play_click()
	_refresh()


func _refresh() -> void:
	var total_potions := GameState.get_total_potion_count()
	if total_potions > last_potion_count:
		var crafted_name := String(GameState.get_potion_recipe_data(GameState.potion_crafting_recipe_id).get("Name", "Potion"))
		feedback_label.text = "%s crafted!" % crafted_name
		_show_floating_text("%s crafted!" % crafted_name, Vector2(300, 840), Color("#a8ff9b"))
		_pulse_shop_preview()
	last_potion_count = total_potions

	var recipe := GameState.get_potion_recipe_data(selected_recipe_id)
	var recipe_name := String(recipe.get("Name", "Potion"))
	var cost_mana := int(recipe.get("CostMana", 0))
	var cost_spirit := int(recipe.get("CostSpirit", 0))
	var owned := GameState.get_potion_count(selected_recipe_id)

	stats_label.text = (
		"Level %d        Selected: %s        Owned: %d        Total Potions: %d"
		% [
			GameState.potion_shop_level,
			recipe_name,
			owned,
			total_potions
		]
	)
	if recipe_title_label:
		recipe_title_label.text = recipe_name
	if recipe_description_label:
		recipe_description_label.text = String(recipe.get("Description", ""))
	if requirements_label:
		var ingredient_text := GameState.get_potion_ingredient_requirement_text(selected_recipe_id)
		if ingredient_text == "":
			ingredient_text = "None"
		requirements_label.text = "Requirements\n\nMana %d / %d\n\nSpirit Energy %d / %d\n\n%s" % [
			GameState.total_mana,
			cost_mana,
			GameState.sacred_pond_spirit_energy,
			cost_spirit,
			ingredient_text
		]
	if potion_details_label:
		potion_details_label.text = "Craft Time\n%ds\n\nSell Value\n%d\n\nOwned\n%d" % [
			GameState.get_potion_craft_time(selected_recipe_id),
			GameState.get_potion_sell_value(selected_recipe_id),
			owned
		]
	if craft_button:
		craft_button.disabled = GameState.potion_crafting_active or not GameState.can_craft_potion(selected_recipe_id)
	for recipe_id in recipe_buttons.keys():
		var button := recipe_buttons[recipe_id] as Button
		button.disabled = GameState.potion_crafting_active
		button.modulate = Color("#fff2a8") if recipe_id == selected_recipe_id else Color.WHITE
	if progress_bar:
		progress_bar.value = GameState.get_potion_craft_progress() * 100.0
		progress_bar.visible = GameState.potion_crafting_active
		if GameState.potion_crafting_active:
			var active_name := String(GameState.get_potion_recipe_data(GameState.potion_crafting_recipe_id).get("Name", "Potion"))
			progress_bar.tooltip_text = "Crafting %s..." % active_name


func _on_craft_pressed() -> void:
	SoundManager.play_click()
	upgrade_confirmation_pending = false
	var recipe_name := String(GameState.get_potion_recipe_data(selected_recipe_id).get("Name", "Potion"))
	if GameState.start_potion_craft(selected_recipe_id):
		feedback_label.text = "Crafting %s..." % recipe_name
	else:
		feedback_label.text = "Cannot craft %s." % recipe_name


func _on_buy_pressed() -> void:
	SoundManager.play_click()
	upgrade_confirmation_pending = false
	var result: Dictionary = GameState.buy_potion_ingredient_bundle()
	feedback_label.text = String(result.get("Message", ""))
	_refresh()


func _on_sell_pressed() -> void:
	SoundManager.play_click()
	upgrade_confirmation_pending = false
	var recipe := GameState.get_potion_recipe_data(selected_recipe_id)
	var recipe_name := String(recipe.get("Name", "Potion"))
	var sell_value := GameState.get_potion_sell_value(selected_recipe_id)
	if GameState.sell_potion(selected_recipe_id):
		feedback_label.text = "%s sold for %d Coins!" % [recipe_name, sell_value]
		_show_floating_text("%s sold for %d Coins!" % [recipe_name, sell_value], Vector2(260, 840), Color("#f3d57a"))
	else:
		feedback_label.text = "No %s to sell." % recipe_name


func _on_upgrade_pressed() -> void:
	SoundManager.play_click()
	if GameState.total_coins < GameState.potion_shop_upgrade_cost:
		upgrade_confirmation_pending = false
		feedback_label.text = "Not enough Coins."
		return
	if not upgrade_confirmation_pending:
		upgrade_confirmation_pending = true
		feedback_label.text = "Upgrade to Level %d for %d Coins? Tap Upgrade again to confirm." % [
			GameState.potion_shop_level + 1,
			GameState.potion_shop_upgrade_cost
		]
		return
	upgrade_confirmation_pending = false
	if GameState.upgrade_potion_shop():
		feedback_label.text = "Potion Shop upgraded!"
		_pulse_shop_preview()
	else:
		feedback_label.text = "Not enough Coins."


func _on_back_pressed() -> void:
	SoundManager.play_click()
	upgrade_confirmation_pending = false
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


func _pulse_shop_preview() -> void:
	if shop_preview == null:
		var original_panel := modulate
		var panel_tween := create_tween()
		panel_tween.tween_property(self, "modulate", Color("#fff2a8"), 0.10)
		panel_tween.tween_property(self, "modulate", original_panel, 0.25)
		return
	var original := shop_preview.modulate
	var tween := create_tween()
	tween.tween_property(shop_preview, "modulate", Color("#fff2a8"), 0.10)
	tween.tween_property(shop_preview, "modulate", original, 0.25)
