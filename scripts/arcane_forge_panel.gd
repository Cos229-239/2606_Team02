extends Control

signal closed

const UPGRADE_IDS := ["flower_focus", "potion_gilding", "pond_resonance"]

var stats_label: Label
var feedback_label: Label
var upgrades_container: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_panel()
	GameState.resources_changed.connect(_refresh)
	GameState.arcane_forge_changed.connect(_refresh)
	GameState.flower_grove_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_title("Arcane Forge")

	var stats_margin := _make_full_margin(120, 120, 178, 1620)
	add_child(stats_margin)
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _make_panel_style(0.78))
	stats_margin.add_child(stats_panel)
	stats_label = _make_label("", 23, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_panel.add_child(stats_label)

	var center_margin := _make_full_margin(92, 92, 318, 440)
	add_child(center_margin)
	var center := PanelContainer.new()
	center.add_theme_stylebox_override("panel", _make_panel_style(0.70))
	center_margin.add_child(center)
	var pad := _make_margin(24, 24, 24, 24)
	center.add_child(pad)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	pad.add_child(layout)

	var hero := Control.new()
	hero.custom_minimum_size = Vector2(820, 350)
	layout.add_child(hero)
	_add_color_panel(hero, "SparkColumn", Vector2(382, 26), Vector2(56, 238), Color("#3d77a5", 0.24), Color("#8fe6ff"))
	_add_color_panel(hero, "ForgeAnvil", Vector2(284, 224), Vector2(252, 54), Color("#2d2c35", 0.84), Color("#d0a246"))
	_add_color_panel(hero, "UpgradeRune", Vector2(254, 74), Vector2(312, 94), Color("#130f24", 0.58), Color("#b879ff"))
	_add_sprite(hero, "res://assets/sprites/buildings/arcane_forge_home.png", Vector2(258, 20), Vector2(304, 250))
	_add_sprite(hero, "res://assets/sprites/effects/glow_orb.png", Vector2(170, 190), Vector2(84, 84))
	_add_sprite(hero, "res://assets/sprites/effects/glow_orb.png", Vector2(590, 188), Vector2(84, 84))
	_add_sprite(hero, "res://assets/sprites/environment/spirit_stone.png", Vector2(126, 226), Vector2(78, 88))
	_add_sprite(hero, "res://assets/sprites/potion_shop/mana_crystal.png", Vector2(648, 224), Vector2(70, 70))
	var hero_text := _make_label("Spend resources on permanent upgrades that improve existing buildings.", 23, Color("#f3d57a"), HORIZONTAL_ALIGNMENT_CENTER)
	hero_text.position = Vector2(0, 290)
	hero_text.size = Vector2(820, 56)
	hero.add_child(hero_text)

	upgrades_container = VBoxContainer.new()
	upgrades_container.add_theme_constant_override("separation", 12)
	layout.add_child(upgrades_container)

	feedback_label = _make_label("", 26, Color("#f3d57a"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.custom_minimum_size = Vector2(820, 48)
	layout.add_child(feedback_label)

	var bottom := _make_bottom_bar()
	add_child(bottom)
	var back_button := _make_button("Back")
	back_button.pressed.connect(_on_back_pressed)
	bottom.get_node("Row").add_child(back_button)


func _refresh() -> void:
	stats_label.text = "Forge Level %d        Mana %d        Coins %d        Spirit %d" % [
		GameState.forge_level,
		GameState.total_mana,
		GameState.total_coins,
		GameState.sacred_pond_spirit_energy
	]
	for child in upgrades_container.get_children():
		child.queue_free()
	for upgrade_id in UPGRADE_IDS:
		upgrades_container.add_child(_make_upgrade_card(GameState.get_forge_upgrade_data(upgrade_id)))


func _make_upgrade_card(upgrade: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(0.82, Color("#8d6a33")))
	var margin := _make_margin(18, 18, 12, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var rune := _make_upgrade_rune(String(upgrade.get("UpgradeID", "")))
	row.add_child(rune)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 2)
	row.add_child(text_stack)
	text_stack.add_child(_make_label("%s  Level %d / %d" % [String(upgrade.get("Title", "Upgrade")), int(upgrade.get("Level", 0)), int(upgrade.get("MaxLevel", 3))], 22, Color("#fff2c6")))
	text_stack.add_child(_make_label(String(upgrade.get("Description", "")), 17, Color("#e8dfca")))
	text_stack.add_child(_make_label("Cost: %s" % _format_upgrade_cost(upgrade), 18, Color("#f3d57a")))

	var button := _make_button("Forge")
	button.custom_minimum_size = Vector2(150, 64)
	button.disabled = not _can_purchase_upgrade(upgrade)
	if int(upgrade.get("Level", 0)) >= int(upgrade.get("MaxLevel", 3)):
		button.text = "Maxed"
	var upgrade_id := String(upgrade.get("UpgradeID", ""))
	button.pressed.connect(func(): _on_upgrade_pressed(upgrade_id))
	row.add_child(button)
	return card


func _make_upgrade_rune(upgrade_id: String) -> Control:
	var rune := Control.new()
	rune.custom_minimum_size = Vector2(58, 58)
	_add_color_panel(rune, "UpgradeRuneBadge", Vector2(5, 5), Vector2(48, 48), Color("#151426", 0.86), Color("#b879ff"))
	match upgrade_id:
		"flower_focus":
			_add_sprite(rune, "res://assets/sprites/environment/golden_bloom.png", Vector2(12, 12), Vector2(34, 34))
		"potion_gilding":
			_add_sprite(rune, "res://assets/sprites/potion_shop/mana_potion_bottle.png", Vector2(15, 8), Vector2(28, 42))
		"pond_resonance":
			_add_sprite(rune, "res://assets/sprites/environment/spirit_stone.png", Vector2(13, 8), Vector2(32, 42))
	return rune


func _format_upgrade_cost(upgrade: Dictionary) -> String:
	var parts: Array[String] = []
	if int(upgrade.get("CostMana", 0)) > 0:
		parts.append("%d Mana" % int(upgrade.get("CostMana", 0)))
	if int(upgrade.get("CostCoins", 0)) > 0:
		parts.append("%d Coins" % int(upgrade.get("CostCoins", 0)))
	if int(upgrade.get("CostSpirit", 0)) > 0:
		parts.append("%d Spirit" % int(upgrade.get("CostSpirit", 0)))
	return " + ".join(parts)


func _can_purchase_upgrade(upgrade: Dictionary) -> bool:
	if int(upgrade.get("Level", 0)) >= int(upgrade.get("MaxLevel", 3)):
		return false
	return (
		GameState.total_mana >= int(upgrade.get("CostMana", 0))
		and GameState.total_coins >= int(upgrade.get("CostCoins", 0))
		and GameState.sacred_pond_spirit_energy >= int(upgrade.get("CostSpirit", 0))
	)


func _on_upgrade_pressed(upgrade_id: String) -> void:
	var result: Dictionary = GameState.purchase_forge_upgrade(upgrade_id)
	feedback_label.text = String(result.get("Message", ""))
	if bool(result.get("Success", false)):
		_show_floating_text(feedback_label.text, Vector2(320, 850), Color("#a8d8ff"))
	_refresh()


func _on_back_pressed() -> void:
	GameState.save_game()
	closed.emit()


func _add_background() -> void:
	var backing := TextureRect.new()
	backing.texture = load("res://assets/sprites/backgrounds/restored_village_background.png")
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backing.modulate = Color(0.58, 0.60, 0.76, 1.0)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	var shade := ColorRect.new()
	shade.color = Color(0.006, 0.008, 0.020, 0.56)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_title(text: String) -> void:
	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(200, 42)
	title_panel.size = Vector2(680, 118)
	title_panel.add_theme_stylebox_override("panel", _make_panel_style(0.82))
	add_child(title_panel)
	var title := _make_label(text, 46, Color("#f5d66f"), HORIZONTAL_ALIGNMENT_CENTER)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(title)


func _make_bottom_bar() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(94, 1678)
	panel.size = Vector2(892, 138)
	panel.add_theme_stylebox_override("panel", _make_button_bar_style())
	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	return panel


func _make_full_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 88)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#fff2c6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.025, 0.028, 0.035, 0.94), Color("#9e7332")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.14, 0.08, 0.96), Color("#d0a246")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.16, 0.22, 0.10, 0.98), Color("#f3d57a")))
	return button


func _make_panel_style(alpha: float, border: Color = Color("#b98c43")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, alpha)
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style


func _make_button_bar_style() -> StyleBoxFlat:
	var style := _make_panel_style(0.70, Color("#6f5327"))
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
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


func _add_sprite(parent: Node, path: String, top_left: Vector2, sprite_size: Vector2) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + sprite_size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if texture:
		sprite.scale = Vector2(sprite_size.x / texture.get_width(), sprite_size.y / texture.get_height())
	parent.add_child(sprite)
	return sprite


func _add_color_panel(parent: Node, node_name: String, top_left: Vector2, panel_size: Vector2, fill: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = top_left
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _make_flat_style(fill, border, 2, 14))
	parent.add_child(panel)
	return panel


func _make_flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	var label := _make_label(text, 34, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = start_position
	label.size = Vector2(440, 50)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -85), 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)
