extends Control

signal closed

const ANCIENT_TREE_PANEL_ART := "res://assets/sprites/panels/ancient_tree_clean.jpg"
const WATER_BUTTON_ART := "res://assets/sprites/ui/ancient_tree_water_button.png"
const GOLD := Color("#f5d66f")
const SOFT_GOLD := Color("#fff2c6")
const BLUE := Color("#58d9ff")
const GREEN := Color("#8fe36e")

var reputation_value_label: Label
var orders_value_label: Label
var coins_value_label: Label
var mana_value_label: Label
var potions_value_label: Label
var growth_value_label: Label
var growth_caption_label: Label
var next_reward_label: Label
var feedback_label: Label
var water_button: TextureButton
var upgrade_button: Button
var growth_ring: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_screen()
	GameState.resources_changed.connect(_refresh)
	GameState.ancient_tree_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	GameState.market_stall_changed.connect(_refresh)
	_refresh()


func _build_screen() -> void:
	_add_background()
	_add_top_resource_bar()
	_add_back_button()
	_add_title()
	_add_growth_badge()
	_add_action_buttons()
	_add_bottom_navigation()
	_add_feedback()


func _refresh() -> void:
	reputation_value_label.text = str(GameState.market_reputation)
	orders_value_label.text = str(GameState.market_orders_completed)
	coins_value_label.text = str(GameState.total_coins)
	mana_value_label.text = str(GameState.total_mana)
	potions_value_label.text = str(GameState.mana_potion_count)

	var growth := GameState.grove_restoration
	growth_value_label.text = "%d%%" % growth
	growth_caption_label.text = "GROWTH"
	next_reward_label.text = GameState.get_next_ancient_tree_reward_text()

	water_button.disabled = growth >= 100 or GameState.total_mana < GameState.ancient_tree_restore_cost
	water_button.modulate = Color(1.0, 1.0, 1.0, 0.88) if water_button.disabled else Color.WHITE

	var reward_level := _get_next_claimable_reward_level()
	upgrade_button.disabled = reward_level == 0
	upgrade_button.text = "UPGRADED" if growth >= 100 and reward_level == 0 else "UPGRADE"

	if growth_ring:
		var alpha := 0.74 + clampf(float(growth) / 100.0, 0.0, 1.0) * 0.22
		growth_ring.modulate = Color(1.0, 1.0, 1.0, alpha)


func _add_background() -> void:
	var backing := TextureRect.new()
	backing.texture = load(ANCIENT_TREE_PANEL_ART)
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.12)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_top_resource_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(34, 24)
	bar.size = Vector2(1012, 96)
	bar.add_theme_stylebox_override("panel", _make_frame_style(Color(0.01, 0.012, 0.018, 0.88), Color("#c18a3a"), 3, 4))
	add_child(bar)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	reputation_value_label = _add_resource_chip(row, "R", "Reputation", Color("#4d77ff"))
	orders_value_label = _add_resource_chip(row, "O", "Orders", Color("#d8aa62"))
	coins_value_label = _add_resource_chip(row, "C", "Coins", Color("#e6b63e"))
	mana_value_label = _add_resource_chip(row, "M", "Mana", Color("#2fbdff"))
	potions_value_label = _add_resource_chip(row, "P", "Potions", Color("#d3484b"))


func _add_resource_chip(parent: Node, icon_text: String, title: String, icon_color: Color) -> Label:
	var chip := HBoxContainer.new()
	chip.custom_minimum_size = Vector2(190, 72)
	chip.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override("separation", 6)
	parent.add_child(chip)

	var icon := _make_icon_badge(icon_text, icon_color, Vector2(38, 38), 19)
	chip.add_child(icon)

	var label := _make_label("%s " % title, 20, SOFT_GOLD)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)

	var value := _make_label("0", 20, SOFT_GOLD)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(value)
	return value


func _add_back_button() -> void:
	var button := Button.new()
	button.name = "AncientTreeBackButton"
	button.position = Vector2(74, 170)
	button.size = Vector2(158, 128)
	button.text = "<\nBACK"
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_frame_style(Color("#08111d", 0.82), Color("#c18a3a"), 3, 68))
	button.add_theme_stylebox_override("hover", _make_frame_style(Color("#102b43", 0.92), Color("#f5d66f"), 3, 68))
	button.add_theme_stylebox_override("pressed", _make_frame_style(Color("#174a63", 0.96), Color("#ffffff"), 3, 68))
	button.pressed.connect(_on_back_pressed)
	add_child(button)


func _add_title() -> void:
	var title := _make_label("ANCIENT TREE", 66, SOFT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(256, 168)
	title.size = Vector2(620, 82)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	_add_rule(Vector2(276, 286), Vector2(528, 3))
	_add_rule(Vector2(586, 286), Vector2(220, 3))
	var gem := _make_icon_badge("D", Color("#2fd8d4"), Vector2(34, 34), 15)
	gem.position = Vector2(523, 270)
	add_child(gem)


func _add_growth_badge() -> void:
	growth_ring = PanelContainer.new()
	growth_ring.position = Vector2(410, 1168)
	growth_ring.size = Vector2(260, 230)
	growth_ring.add_theme_stylebox_override("panel", _make_frame_style(Color("#021e1e", 0.88), Color("#d4a34e"), 4, 112))
	add_child(growth_ring)

	var inner := PanelContainer.new()
	inner.position = Vector2(22, 16)
	inner.size = Vector2(216, 198)
	inner.add_theme_stylebox_override("panel", _make_frame_style(Color("#032a28", 0.86), Color("#38d6c9"), 2, 96))
	growth_ring.add_child(inner)

	growth_value_label = _make_label("0%", 64, SOFT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	growth_value_label.position = Vector2(410, 1222)
	growth_value_label.size = Vector2(260, 74)
	growth_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(growth_value_label)

	growth_caption_label = _make_label("GROWTH", 24, SOFT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	growth_caption_label.position = Vector2(0, 1270)
	growth_caption_label.size = Vector2(1080, 38)
	add_child(growth_caption_label)

	next_reward_label = _make_label("", 21, Color("#d7f7d2"), HORIZONTAL_ALIGNMENT_CENTER)
	next_reward_label.position = Vector2(250, 1340)
	next_reward_label.size = Vector2(580, 48)
	add_child(next_reward_label)


func _add_action_buttons() -> void:
	upgrade_button = _make_action_button("UPGRADE", Color("#063c21"), Color("#40a85a"))
	upgrade_button.name = "UpgradeButton"
	upgrade_button.position = Vector2(82, 1438)
	upgrade_button.size = Vector2(438, 112)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	add_child(upgrade_button)

	water_button = _make_water_image_button()
	water_button.name = "RestoreButton"
	water_button.position = Vector2(560, 1438)
	water_button.size = Vector2(438, 112)
	water_button.pressed.connect(_on_water_pressed)
	add_child(water_button)


func _add_bottom_navigation() -> void:
	var labels := ["Trade", "Orders", "Upgrades", "Storage", "Back"]
	var icons := ["T", "O", "U", "S", "<"]
	var x := 56
	for index in range(labels.size()):
		var button := _make_nav_button(labels[index], icons[index])
		button.position = Vector2(x + index * 202, 1666)
		button.size = Vector2(172, 160)
		var nav_label: String = labels[index]
		if labels[index] == "Back":
			button.pressed.connect(_on_back_pressed)
		else:
			button.pressed.connect(func() -> void: _on_nav_pressed(nav_label))
		add_child(button)


func _add_feedback() -> void:
	feedback_label = _make_label("", 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.position = Vector2(150, 1562)
	feedback_label.size = Vector2(780, 58)
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(feedback_label)


func _make_action_button(text: String, bg: Color, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 38)
	button.add_theme_color_override("font_color", SOFT_GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#9a9078"))
	button.add_theme_constant_override("h_separation", 14)
	button.add_theme_stylebox_override("normal", _make_frame_style(Color(bg.r, bg.g, bg.b, 0.92), Color("#c18a3a"), 3, 4))
	button.add_theme_stylebox_override("hover", _make_frame_style(Color(accent.r, accent.g, accent.b, 0.72), Color("#f5d66f"), 3, 4))
	button.add_theme_stylebox_override("pressed", _make_frame_style(Color(accent.r, accent.g, accent.b, 0.92), Color("#ffffff"), 3, 4))
	button.add_theme_stylebox_override("disabled", _make_frame_style(Color(0.02, 0.02, 0.025, 0.82), Color("#6f5327"), 3, 4))
	return button


func _make_water_image_button() -> TextureButton:
	var button := TextureButton.new()
	var texture := load(WATER_BUTTON_ART)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.tooltip_text = "Water Ancient Tree"
	return button


func _make_nav_button(text: String, icon_text: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [icon_text, text]
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", SOFT_GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_frame_style(Color(0.012, 0.014, 0.022, 0.90), Color("#9e7332"), 2, 4))
	button.add_theme_stylebox_override("hover", _make_frame_style(Color(0.07, 0.10, 0.13, 0.94), Color("#f5d66f"), 2, 4))
	button.add_theme_stylebox_override("pressed", _make_frame_style(Color(0.12, 0.16, 0.18, 0.98), Color("#ffffff"), 2, 4))
	return button


func _add_button_icon(button: Button, icon_text: String, icon_color: Color) -> void:
	var icon := _make_icon_badge(icon_text, icon_color, Vector2(66, 66), 30)
	icon.position = Vector2(48, 22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)


func _make_icon_badge(text: String, color: Color, badge_size: Vector2, font_size: int) -> Label:
	var badge := Label.new()
	badge.text = text
	badge.custom_minimum_size = badge_size
	badge.size = badge_size
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", font_size)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_shadow_color", Color.BLACK)
	badge.add_theme_constant_override("shadow_offset_x", 2)
	badge.add_theme_constant_override("shadow_offset_y", 2)
	badge.add_theme_stylebox_override("normal", _make_frame_style(Color(color.r, color.g, color.b, 0.82), Color("#f5d66f"), 2, int(badge_size.x * 0.5)))
	return badge


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _make_frame_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _add_rule(position: Vector2, size: Vector2) -> void:
	var rule := ColorRect.new()
	rule.position = position
	rule.size = size
	rule.color = Color("#d0a34f", 0.78)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)


func _on_water_pressed() -> void:
	SoundManager.play_click()
	var result: Dictionary = GameState.restore_ancient_tree()
	feedback_label.text = String(result.get("Message", ""))
	if bool(result.get("Success", false)):
		_show_floating_text("+ Growth", Vector2(330, 1240), GREEN)
	_refresh()


func _on_upgrade_pressed() -> void:
	SoundManager.play_click()
	var reward_level := _get_next_claimable_reward_level()
	if reward_level == 0:
		feedback_label.text = GameState.get_next_ancient_tree_reward_text()
		return
	var result: Dictionary = GameState.claim_ancient_tree_reward(reward_level)
	feedback_label.text = String(result.get("Message", ""))
	if bool(result.get("Success", false)):
		SoundManager.play_collect()
		_show_floating_text("Reward claimed", Vector2(318, 1240), GOLD)
	_refresh()


func _on_nav_pressed(label: String) -> void:
	SoundManager.play_click()
	feedback_label.text = "%s is available from the village." % label


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _get_next_claimable_reward_level() -> int:
	for level in [2, 3, 4, 5]:
		if GameState.ancient_tree_level >= level and not GameState.ancient_tree_claimed_rewards.has(level):
			return level
	return 0


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	var label := _make_label(text, 34, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = start_position
	label.size = Vector2(440, 50)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -85), 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)
