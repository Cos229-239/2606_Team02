extends Control

signal closed

const BG_PATH := "res://assets/sprites/arcane_forge/arcane_forge_background.png"
const UPGRADE_IDS := ["flower_focus", "potion_gilding", "pond_resonance"]
const TAB_CARDS := {
	"Craft": "res://assets/sprites/arcane_forge/forge_craft_card.png",
	"Gear": "res://assets/sprites/arcane_forge/forge_gear_card.png",
	"Upgrades": "res://assets/sprites/arcane_forge/forge_upgrades_card.png",
	"Enhance": "res://assets/sprites/arcane_forge/forge_enhance_card.png",
	"Back": "res://assets/sprites/arcane_forge/forge_back_card.png"
}

var active_tab := "Upgrades"
var stats_label: Label
var title_label: Label
var mode_label: Label
var feedback_label: Label
var content_stack: VBoxContainer
var card_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_panel()
	GameState.resources_changed.connect(_refresh)
	GameState.arcane_forge_changed.connect(_refresh)
	GameState.flower_grove_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_top_bar()
	_add_title_header()
	_add_mode_panel()
	_add_bottom_tabs()


func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = load(BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.14)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_top_bar() -> void:
	var margin := _make_full_margin(72, 72, 24, 1785)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.014, 0.020, 0.78), Color("#bd8d43"), 2, 12))
	margin.add_child(panel)
	stats_label = _make_label("", 24, Color("#fff1bc"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)


func _add_title_header() -> void:
	var margin := _make_full_margin(126, 126, 112, 1558)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.010, 0.012, 0.018, 0.64), Color("#bd8d43"), 2, 14))
	margin.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	panel.add_child(stack)
	title_label = _make_label("Arcane Forge", 58, Color("#ffd77b"), HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(title_label)
	mode_label = _make_label("", 25, Color("#d9f1ff"), HORIZONTAL_ALIGNMENT_CENTER)
	mode_label.name = "ForgeLevelLabel"
	stack.add_child(mode_label)


func _add_mode_panel() -> void:
	var margin := _make_full_margin(95, 95, 1045, 405)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.016, 0.018, 0.026, 0.84), Color("#b98c43"), 2, 14))
	margin.add_child(panel)
	var pad := _make_margin(24, 24, 20, 20)
	panel.add_child(pad)
	content_stack = VBoxContainer.new()
	content_stack.add_theme_constant_override("separation", 12)
	pad.add_child(content_stack)


func _add_bottom_tabs() -> void:
	var margin := _make_full_margin(85, 85, 1638, 24)
	add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	for tab_name in ["Craft", "Gear", "Upgrades", "Enhance", "Back"]:
		var card := _make_tab_card(tab_name)
		card_buttons[tab_name] = card
		row.add_child(card)


func _make_tab_card(tab_name: String) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(158, 218)
	var texture := TextureRect.new()
	texture.texture = load(String(TAB_CARDS[tab_name]))
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture)
	var border := PanelContainer.new()
	border.name = "ActiveBorder"
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_theme_stylebox_override("panel", _make_panel_style(Color.TRANSPARENT, Color("#49cfff"), 4, 12))
	card.add_child(border)
	var button := Button.new()
	button.text = ""
	button.tooltip_text = tab_name
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if tab_name == "Back":
			_on_back_pressed()
		else:
			active_tab = tab_name
			_refresh()
	)
	card.add_child(button)
	return card


func _refresh() -> void:
	stats_label.text = "Forge Level %d     Mana %d     Coins %d     Spirit %d" % [
		GameState.forge_level,
		GameState.total_mana,
		GameState.total_coins,
		GameState.sacred_pond_spirit_energy
	]
	mode_label.text = "Forge Level %d" % GameState.forge_level
	_clear_content()

	match active_tab:
		"Craft":
			_add_description("Crafting is routed through permanent forge projects. Use Upgrades to spend Mana, Coins, and Spirit on stronger village systems.")
		"Gear":
			_add_description("Gear workbench: Flower Focus %d, Potion Gilding %d, Pond Resonance %d." % [
				GameState.forge_flower_focus_level,
				GameState.forge_potion_gilding_level,
				GameState.forge_pond_resonance_level
			])
		"Enhance":
			_add_description("Enhance existing buildings with forged upgrades. Each completed project raises the Forge Level and improves another building.")
		_:
			_add_description("Spend resources on permanent upgrades that improve existing buildings.")
			for upgrade_id in UPGRADE_IDS:
				content_stack.add_child(_make_upgrade_card(GameState.get_forge_upgrade_data(upgrade_id)))

	feedback_label = _make_label("", 24, Color("#82d9ff"), HORIZONTAL_ALIGNMENT_CENTER)
	content_stack.add_child(feedback_label)

	for tab_name in card_buttons.keys():
		var border := (card_buttons[tab_name] as Control).get_node("ActiveBorder") as PanelContainer
		border.visible = tab_name == active_tab


func _add_description(text: String) -> void:
	var label := _make_label(text, 24, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_stack.add_child(label)


func _make_upgrade_card(upgrade: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var upgrade_id := String(upgrade.get("UpgradeID", ""))
	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	var is_maxed := level >= max_level
	var can_forge := _can_purchase_upgrade(upgrade)
	card.name = "ForgeUpgradeCard_%s" % upgrade_id
	card.add_theme_stylebox_override("panel", _make_upgrade_card_style(can_forge, is_maxed))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	_add_upgrade_icon(row, upgrade_id)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	text_stack.add_child(header)
	var title := _make_label("%s  Level %d / %d" % [String(upgrade.get("Title", "Upgrade")), level, max_level], 19, Color("#fff2c6"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_status_pill(_get_upgrade_state_text(can_forge, is_maxed), can_forge, is_maxed, upgrade_id))

	var effect := _make_label("Effect: %s" % String(upgrade.get("Description", "")), 15, Color("#e8dfca"))
	effect.name = "ForgeUpgradeEffect_%s" % upgrade_id
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(effect)
	text_stack.add_child(_make_label("Needs: %s" % _format_upgrade_cost(upgrade), 15, Color("#f3d57a")))

	var status_label := _make_label(_format_upgrade_status(upgrade), 15, _get_status_color(can_forge, is_maxed))
	status_label.name = "ForgeUpgradeStatus_%s" % upgrade_id
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(status_label)

	var button := _make_button(_get_upgrade_button_text(can_forge, is_maxed))
	button.name = "ForgeButton_%s" % upgrade_id
	button.custom_minimum_size = Vector2(118, 54)
	button.disabled = not can_forge
	button.pressed.connect(func() -> void: _on_upgrade_pressed(upgrade_id))
	row.add_child(button)
	return card


func _add_upgrade_icon(parent: Node, upgrade_id: String) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(52, 52)
	holder.clip_contents = true
	parent.add_child(holder)
	match upgrade_id:
		"flower_focus":
			_add_icon_texture(holder, "res://assets/sprites/environment/golden_bloom.png")
		"potion_gilding":
			_add_icon_texture(holder, "res://assets/sprites/potion_shop/mana_potion_bottle.png")
		"pond_resonance":
			_add_icon_texture(holder, "res://assets/sprites/environment/spirit_stone.png")


func _format_upgrade_cost(upgrade: Dictionary) -> String:
	var parts: Array[String] = []
	if int(upgrade.get("CostMana", 0)) > 0:
		parts.append("%d Mana" % int(upgrade.get("CostMana", 0)))
	if int(upgrade.get("CostCoins", 0)) > 0:
		parts.append("%d Coins" % int(upgrade.get("CostCoins", 0)))
	if int(upgrade.get("CostSpirit", 0)) > 0:
		parts.append("%d Spirit" % int(upgrade.get("CostSpirit", 0)))
	return " + ".join(parts)


func _format_upgrade_status(upgrade: Dictionary) -> String:
	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	if level >= max_level:
		return "Max level reached."
	var missing: Array[String] = []
	var missing_mana: int = max(0, int(upgrade.get("CostMana", 0)) - GameState.total_mana)
	var missing_coins: int = max(0, int(upgrade.get("CostCoins", 0)) - GameState.total_coins)
	var missing_spirit: int = max(0, int(upgrade.get("CostSpirit", 0)) - GameState.sacred_pond_spirit_energy)
	if missing_mana > 0:
		missing.append("%d Mana" % missing_mana)
	if missing_coins > 0:
		missing.append("%d Coins" % missing_coins)
	if missing_spirit > 0:
		missing.append("%d Spirit" % missing_spirit)
	if missing.is_empty():
		return "Ready to forge."
	return "Need %s." % " + ".join(missing)


func _can_purchase_upgrade(upgrade: Dictionary) -> bool:
	if int(upgrade.get("Level", 0)) >= int(upgrade.get("MaxLevel", 3)):
		return false
	return GameState.total_mana >= int(upgrade.get("CostMana", 0)) and GameState.total_coins >= int(upgrade.get("CostCoins", 0)) and GameState.sacred_pond_spirit_energy >= int(upgrade.get("CostSpirit", 0))


func _get_upgrade_state_text(can_forge: bool, is_maxed: bool) -> String:
	if is_maxed:
		return "Maxed"
	return "Ready" if can_forge else "Missing"


func _get_upgrade_button_text(can_forge: bool, is_maxed: bool) -> String:
	if is_maxed:
		return "Maxed"
	return "Forge" if can_forge else "Need More"


func _get_status_color(can_forge: bool, is_maxed: bool) -> Color:
	if is_maxed:
		return Color("#d9f1ff")
	return Color("#82d9ff") if can_forge else Color("#ffb6a0")


func _make_status_pill(text: String, ready: bool, maxed: bool, upgrade_id: String) -> Label:
	var pill := _make_label(text, 14, Color("#102018") if ready else Color("#fff2d6"), HORIZONTAL_ALIGNMENT_CENTER)
	pill.name = "ForgeUpgradePill_%s" % upgrade_id
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.custom_minimum_size = Vector2(96, 34)
	pill.add_theme_stylebox_override(
		"normal",
		_make_panel_style(
			_get_pill_background(ready, maxed),
			_get_pill_border(ready, maxed),
			2,
			8
		)
	)
	return pill


func _get_pill_background(ready: bool, maxed: bool) -> Color:
	if maxed:
		return Color("#243447", 0.94)
	return Color("#82d9ff", 0.94) if ready else Color("#4a2730", 0.94)


func _get_pill_border(ready: bool, maxed: bool) -> Color:
	if maxed:
		return Color("#d9f1ff")
	return Color("#f5d66f") if ready else Color("#ff9c7d")


func _make_upgrade_card_style(ready: bool, maxed: bool) -> StyleBoxFlat:
	if maxed:
		return _make_panel_style(Color(0.026, 0.030, 0.038, 0.90), Color("#7ea6c7"), 2, 10)
	return _make_panel_style(
		Color(0.026, 0.046, 0.058, 0.92) if ready else Color(0.018, 0.020, 0.030, 0.88),
		Color("#82d9ff") if ready else Color("#8d6a33"),
		3 if ready else 2,
		10
	)


func _on_upgrade_pressed(upgrade_id: String) -> void:
	SoundManager.play_click()
	var result: Dictionary = GameState.purchase_forge_upgrade(upgrade_id)
	if feedback_label:
		feedback_label.text = String(result.get("Message", ""))
	_refresh()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _clear_content() -> void:
	for child in content_stack.get_children():
		child.queue_free()


func _add_texture(parent: Node, path: String, top_left: Vector2, texture_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(path)
	texture_rect.position = top_left
	texture_rect.size = texture_size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_icon_texture(parent: Node, path: String) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(path)
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


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
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#fff2c6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.025, 0.028, 0.035, 0.94), Color("#9e7332"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.060, 0.080, 0.105, 0.98), Color("#59c7ff"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.10, 0.13, 0.16, 0.98), Color("#d9f1ff"), 3, 8))
	return button


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
