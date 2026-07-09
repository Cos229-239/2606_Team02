extends Control

signal closed

const ANCIENT_TREE_PANEL_ART := "res://assets/sprites/panels/ancient_tree_zoom.jpg"

var stats_label: Label
var feedback_label: Label
var progress_bar: ProgressBar
var next_reward_label: Label
var rewards_container: VBoxContainer
var restore_button: Button
var restoration_value_label: Label
var tree_level_value_label: Label
var restore_cost_value_label: Label
var mana_value_label: Label
var hero_tree: Sprite2D
var hero_glow: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_panel()
	GameState.resources_changed.connect(_refresh)
	GameState.ancient_tree_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_title("Ancient Tree", "Restore the grove heart")

	var stats_margin := _make_full_margin(74, 74, 178, 1590)
	add_child(stats_margin)
	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 12)
	stats_margin.add_child(stats_row)
	var restoration_chip := _make_stat_chip("Restoration", Color("#aeea84"))
	restoration_value_label = restoration_chip.find_child("Value", true, false) as Label
	stats_row.add_child(restoration_chip)
	var level_chip := _make_stat_chip("Tree Level", Color("#fff2a8"))
	tree_level_value_label = level_chip.find_child("Value", true, false) as Label
	stats_row.add_child(level_chip)
	var cost_chip := _make_stat_chip("Restore Cost", Color("#75d8ff"))
	restore_cost_value_label = cost_chip.find_child("Value", true, false) as Label
	stats_row.add_child(cost_chip)
	var mana_chip := _make_stat_chip("Mana", Color("#75d8ff"))
	mana_value_label = mana_chip.find_child("Value", true, false) as Label
	stats_row.add_child(mana_chip)

	var center_margin := _make_full_margin(70, 70, 300, 424)
	add_child(center_margin)
	var center := PanelContainer.new()
	center.add_theme_stylebox_override("panel", _make_panel_style(0.76))
	center_margin.add_child(center)
	var pad := _make_margin(22, 22, 22, 22)
	center.add_child(pad)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	pad.add_child(layout)

	var hero := Control.new()
	hero.custom_minimum_size = Vector2(896, 548)
	layout.add_child(hero)
	_add_color_panel(hero, "TreeCanopyShade", Vector2(86, 44), Vector2(724, 350), Color("#07130d", 0.46), Color("#2f6840", 0.58))
	hero_glow = _add_color_panel(hero, "TreeHalo", Vector2(214, 24), Vector2(468, 354), Color("#315f42", 0.24), Color("#87e6a2"))
	var root_sigil := _add_color_panel(hero, "RootSigil", Vector2(288, 342), Vector2(320, 112), Color("#1e3321", 0.82), Color("#d0a34f"))
	root_sigil.rotation = -0.01
	var vine := _add_color_panel(hero, "RewardVine", Vector2(86, 438), Vector2(724, 22), Color("#203f23", 0.78), Color("#76b65d"))
	vine.rotation = 0.005
	_add_sprite(hero, "res://assets/sprites/environment/purple_bloom.png", Vector2(138, 330), Vector2(86, 86))
	_add_sprite(hero, "res://assets/sprites/environment/bush_flowers.png", Vector2(662, 334), Vector2(104, 86))
	_add_sprite(hero, "res://assets/sprites/effects/glow_orb.png", Vector2(414, 260), Vector2(70, 70))
	hero_tree = _add_sprite(hero, "res://assets/sprites/buildings/ancient_tree_landmark.png", Vector2(236, -10), Vector2(424, 418))

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(154, 476)
	progress_bar.size = Vector2(588, 30)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	hero.add_child(progress_bar)

	next_reward_label = _make_label("Restore the grove heart to unlock tier rewards.", 24, Color("#f3d57a"), HORIZONTAL_ALIGNMENT_CENTER)
	next_reward_label.name = "NextRewardLabel"
	next_reward_label.position = Vector2(0, 510)
	next_reward_label.size = Vector2(896, 38)
	hero.add_child(next_reward_label)

	rewards_container = VBoxContainer.new()
	rewards_container.add_theme_constant_override("separation", 8)
	layout.add_child(rewards_container)

	feedback_label = _make_label("", 24, Color("#f3d57a"), HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.custom_minimum_size = Vector2(896, 40)
	layout.add_child(feedback_label)

	var bottom := _make_bottom_bar()
	add_child(bottom)
	restore_button = _make_button("Restore")
	restore_button.name = "RestoreButton"
	restore_button.pressed.connect(_on_restore_pressed)
	bottom.get_node("Row").add_child(restore_button)
	var back_button := _make_button("Back")
	back_button.pressed.connect(_on_back_pressed)
	bottom.get_node("Row").add_child(back_button)


func _refresh() -> void:
	if stats_label:
		stats_label.text = "Grove Restoration %d%%        Tree Level %d        Restore Cost %d Mana        Mana %d" % [
			GameState.grove_restoration,
			GameState.ancient_tree_level,
			GameState.ancient_tree_restore_cost,
			GameState.total_mana
		]
	restoration_value_label.text = "%d%%" % GameState.grove_restoration
	tree_level_value_label.text = str(GameState.ancient_tree_level)
	restore_cost_value_label.text = "%d" % GameState.ancient_tree_restore_cost
	mana_value_label.text = "%d" % GameState.total_mana
	progress_bar.value = GameState.grove_restoration
	restore_button.disabled = GameState.grove_restoration >= 100 or GameState.total_mana < GameState.ancient_tree_restore_cost
	restore_button.text = "Fully Restored" if GameState.grove_restoration >= 100 else "Restore"
	var restoration_alpha: float = 0.22 + clampf(float(GameState.grove_restoration) / 100.0, 0.0, 1.0) * 0.26
	if hero_glow:
		hero_glow.modulate = Color(1.0, 1.0, 1.0, minf(1.0, 0.62 + restoration_alpha))
	if hero_tree:
		hero_tree.modulate = Color(minf(1.0, 0.72 + restoration_alpha), minf(1.0, 0.82 + restoration_alpha), minf(1.0, 0.70 + restoration_alpha), 1.0)
	if next_reward_label:
		next_reward_label.text = GameState.get_next_ancient_tree_reward_text()
	for child in rewards_container.get_children():
		child.queue_free()
	for level in [2, 3, 4, 5]:
		rewards_container.add_child(_make_reward_card(level))


func _make_reward_card(level: int) -> PanelContainer:
	var reward := GameState.get_ancient_tree_reward_data(level)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(0.82, Color("#8d6a33")))
	var margin := _make_margin(18, 18, 12, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	var sigil := _make_reward_sigil(level)
	row.add_child(sigil)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_stack)
	var title_color := Color("#fff2c6") if GameState.ancient_tree_level >= level else Color("#c7b98e")
	text_stack.add_child(_make_label("Level %d: %s" % [level, String(reward.get("Title", "Reward"))], 22, title_color))
	text_stack.add_child(_make_label("Reward: %d Mana, %d Coins" % [int(reward.get("RewardMana", 0)), int(reward.get("RewardCoins", 0))], 18, Color("#f3d57a")))
	text_stack.add_child(_make_label(_get_reward_status_text(level), 16, _get_reward_status_color(level)))
	var button := _make_button("Claim")
	button.custom_minimum_size = Vector2(150, 64)
	button.disabled = GameState.ancient_tree_level < level or GameState.ancient_tree_claimed_rewards.has(level)
	button.text = "Claimed" if GameState.ancient_tree_claimed_rewards.has(level) else "Claim"
	button.pressed.connect(func(): _on_claim_pressed(level))
	row.add_child(button)
	return card


func _make_reward_sigil(level: int) -> Control:
	var sigil := Control.new()
	sigil.custom_minimum_size = Vector2(54, 54)
	var fill := Color("#244d2e", 0.82)
	if GameState.ancient_tree_claimed_rewards.has(level):
		fill = Color("#5d4a20", 0.88)
	_add_color_panel(sigil, "RewardVineSigil", Vector2(4, 4), Vector2(46, 46), fill, Color("#f3d57a"))
	var label := _make_label(str(level), 22, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(4, 10)
	label.size = Vector2(46, 30)
	sigil.add_child(label)
	return sigil


func _get_reward_status_text(level: int) -> String:
	if GameState.ancient_tree_claimed_rewards.has(level):
		return "Reward claimed"
	if GameState.ancient_tree_level >= level:
		return "Ready to claim"
	var target := 25
	if level == 3:
		target = 50
	elif level == 4:
		target = 75
	elif level == 5:
		target = 100
	return "Unlocks at %d%% restoration" % target


func _get_reward_status_color(level: int) -> Color:
	if GameState.ancient_tree_claimed_rewards.has(level):
		return Color("#9ecf8f")
	if GameState.ancient_tree_level >= level:
		return Color("#f5d66f")
	return Color("#a99f86")


func _on_restore_pressed() -> void:
	SoundManager.play_click()
	var result: Dictionary = GameState.restore_ancient_tree()
	feedback_label.text = String(result.get("Message", ""))
	if bool(result.get("Success", false)):
		_show_floating_text(feedback_label.text, Vector2(320, 760), Color("#a8ff9b"))
	_refresh()


func _on_claim_pressed(level: int) -> void:
	SoundManager.play_collect()
	var result: Dictionary = GameState.claim_ancient_tree_reward(level)
	feedback_label.text = String(result.get("Message", ""))
	if bool(result.get("Success", false)):
		_show_floating_text(feedback_label.text, Vector2(330, 900), Color("#f3d57a"))
	_refresh()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _add_background() -> void:
	var backing := TextureRect.new()
	backing.texture = load(ANCIENT_TREE_PANEL_ART)
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.014, 0.010, 0.22)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_title(text: String, subtitle: String = "") -> void:
	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(170, 38)
	title_panel.size = Vector2(740, 126)
	title_panel.add_theme_stylebox_override("panel", _make_panel_style(0.82))
	add_child(title_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -2)
	title_panel.add_child(stack)
	var title := _make_label(text, 46, Color("#f5d66f"), HORIZONTAL_ALIGNMENT_CENTER)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(title)
	if subtitle != "":
		var subtitle_label := _make_label(subtitle, 22, Color("#bfe8c4"), HORIZONTAL_ALIGNMENT_CENTER)
		stack.add_child(subtitle_label)


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


func _make_stat_chip(title: String, value_color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(226, 88)
	chip.add_theme_stylebox_override("panel", _make_panel_style(0.80, Color("#8d6a33")))
	var margin := _make_margin(12, 12, 8, 8)
	chip.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(stack)
	var title_label := _make_label(title, 16, Color("#cbbf9a"), HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(title_label)
	var value := _make_label("0", 28, value_color, HORIZONTAL_ALIGNMENT_CENTER)
	value.name = "Value"
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(value)
	return chip


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
