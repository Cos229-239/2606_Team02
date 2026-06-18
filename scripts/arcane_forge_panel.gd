extends PanelContainer

signal closed

const BG_PATH := "res://assets/sprites/arcane_forge/arcane_forge_background.png"
const FRAME_PATH := "res://assets/sprites/arcane_forge/forge_wide_frame.png"
const FAIRY_PATH := "res://assets/sprites/arcane_forge/forge_fairy_workbench.png"
const ANVIL_PATH := "res://assets/sprites/arcane_forge/forge_anvil_focus.png"

const TAB_CARDS := {
	"Craft": "res://assets/sprites/arcane_forge/forge_craft_card.png",
	"Gear": "res://assets/sprites/arcane_forge/forge_gear_card.png",
	"Upgrades": "res://assets/sprites/arcane_forge/forge_upgrades_card.png",
	"Enhance": "res://assets/sprites/arcane_forge/forge_enhance_card.png",
	"Back": "res://assets/sprites/arcane_forge/forge_back_card.png"
}

var active_tab := "Craft"
var stats_label: Label
var mode_title_label: Label
var mode_description_label: Label
var feedback_label: Label
var action_button: Button
var card_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build_panel()
	var state := _game_state()
	state.resources_changed.connect(_refresh)
	state.arcane_forge_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_top_resource_bar()
	_add_title_plaque()
	_add_focus_art()
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

	var vignette := ColorRect.new()
	vignette.color = Color(0.0, 0.0, 0.0, 0.18)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _add_top_resource_bar() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 1760)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.014, 0.020, 0.78), Color("#bd8d43"), 2, 12))
	margin.add_child(panel)

	stats_label = _make_label("", 28, Color("#fff1bc"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)


func _add_title_plaque() -> void:
	var plaque := Control.new()
	plaque.set_anchors_preset(Control.PRESET_FULL_RECT)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plaque)

	_add_texture(plaque, FRAME_PATH, Vector2(94, 96), Vector2(892, 230))

	var title := _make_label("Arcane Forge", 68, Color("#ffd77b"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(150, 146)
	title.size = Vector2(780, 88)
	plaque.add_child(title)

	var level := _make_label("", 30, Color("#d9f1ff"), HORIZONTAL_ALIGNMENT_CENTER)
	level.name = "ForgeLevelLabel"
	level.position = Vector2(330, 246)
	level.size = Vector2(420, 46)
	plaque.add_child(level)
	mode_title_label = level


func _add_focus_art() -> void:
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	_add_texture(art, ANVIL_PATH, Vector2(165, 565), Vector2(600, 600))
	_add_texture(art, FAIRY_PATH, Vector2(648, 690), Vector2(330, 330))


func _add_mode_panel() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 92)
	margin.add_theme_constant_override("margin_right", 92)
	margin.add_theme_constant_override("margin_top", 1250)
	margin.add_theme_constant_override("margin_bottom", 418)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.016, 0.018, 0.026, 0.84), Color("#b98c43"), 2, 14))
	margin.add_child(panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(content_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	content_margin.add_child(layout)

	mode_description_label = _make_label("", 28, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER)
	mode_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(mode_description_label)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(420, 74)
	action_button.add_theme_font_size_override("font_size", 28)
	action_button.add_theme_color_override("font_color", Color("#fff3b8"))
	action_button.add_theme_color_override("font_hover_color", Color.WHITE)
	action_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.030, 0.036, 0.050, 0.94), Color("#b98c43"), 2, 10))
	action_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.060, 0.080, 0.105, 0.98), Color("#59c7ff"), 3, 10))
	action_button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.10, 0.13, 0.16, 0.98), Color("#d9f1ff"), 3, 10))
	action_button.pressed.connect(_on_action_pressed)
	layout.add_child(action_button)

	feedback_label = _make_label("", 24, Color("#82d9ff"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(feedback_label)


func _add_bottom_tabs() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 1570)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	for tab_name in ["Craft", "Gear", "Upgrades", "Enhance", "Back"]:
		var card := _make_tab_card(tab_name)
		card_buttons[tab_name] = card
		row.add_child(card)


func _make_tab_card(tab_name: String) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(196, 300)

	var texture := TextureRect.new()
	texture.texture = load(String(TAB_CARDS[tab_name]))
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture)

	var active_border := PanelContainer.new()
	active_border.name = "ActiveBorder"
	active_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_border.add_theme_stylebox_override("panel", _make_panel_style(Color.TRANSPARENT, Color("#49cfff"), 4, 12))
	card.add_child(active_border)

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
			_set_active_tab(tab_name)
	)
	card.add_child(button)
	return card


func _set_active_tab(tab_name: String) -> void:
	active_tab = tab_name
	feedback_label.text = ""
	_refresh()


func _refresh() -> void:
	var state := _game_state()
	stats_label.text = (
		"Mana %d     Coins %d     Crystals %d     Gear %d     Power +%d"
		% [
			state.total_mana,
			state.total_coins,
			state.arcane_crystal_count,
			state.forge_gear_count,
			state.forge_enhancement_power
		]
	)
	mode_title_label.text = "Forge Level %d" % state.arcane_forge_level

	match active_tab:
		"Craft":
			mode_description_label.text = "Craft gear infused with arcane crystals. Cost: %d Mana. Crystal yield: +%d." % [state.get_forge_craft_mana_cost(), state.get_forge_crystal_yield()]
			action_button.text = "Craft Gear"
			action_button.disabled = state.total_mana < state.get_forge_craft_mana_cost()
		"Gear":
			mode_description_label.text = "Inventory: %d crafted gear. Enhancement power adds +%d to future grove work." % [state.forge_gear_count, state.forge_enhancement_power]
			action_button.text = "View Gear"
			action_button.disabled = true
		"Upgrades":
			mode_description_label.text = "Upgrade the forge to lower craft costs and increase crystal yield. Cost: %d Mana + %d Coins." % [state.get_forge_upgrade_cost_mana(), state.get_forge_upgrade_cost_coins()]
			action_button.text = "Upgrade Forge"
			action_button.disabled = state.total_mana < state.get_forge_upgrade_cost_mana() or state.total_coins < state.get_forge_upgrade_cost_coins()
		"Enhance":
			mode_description_label.text = "Enhance crafted gear with crystals. Cost: %d Crystals. Requires at least one crafted gear." % state.get_forge_enhance_crystal_cost()
			action_button.text = "Enhance Gear"
			action_button.disabled = state.forge_gear_count <= 0 or state.arcane_crystal_count < state.get_forge_enhance_crystal_cost()

	for tab_name in card_buttons.keys():
		var border := (card_buttons[tab_name] as Control).get_node("ActiveBorder") as PanelContainer
		border.visible = tab_name == active_tab


func _on_action_pressed() -> void:
	var state := _game_state()
	var success := false
	match active_tab:
		"Craft":
			success = state.craft_forge_gear()
			feedback_label.text = "Gear crafted!" if success else "Not enough Mana."
		"Upgrades":
			success = state.upgrade_arcane_forge()
			feedback_label.text = "Forge upgraded!" if success else "Need more Mana or Coins."
		"Enhance":
			success = state.enhance_forge_gear()
			feedback_label.text = "Gear enhanced!" if success else "Need gear and crystals."
	_refresh()


func _on_back_pressed() -> void:
	_game_state().save_game()
	closed.emit()


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


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
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
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _game_state() -> Node:
	return get_node("/root/GameState")
