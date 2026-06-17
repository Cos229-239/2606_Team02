extends PanelContainer

signal closed

var stats_label: Label
var feedback_label: Label
var fairy_cards_container: VBoxContainer

func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	GameState.flower_grove_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	GameState.fairy_house_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	fairy_cards_container = get_node("Root/FairyCardsScroll/FairyCardsContainer") as VBoxContainer

	var upgrade_button := get_node("Root/ActionRow/UpgradeHouseButton") as Button
	var back_button := get_node("Root/ActionRow/BackButton") as Button
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_zoom_background("res://assets/sprites/panels/fairy_house_zoom.png")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_top", 930)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)

	var content_panel := PanelContainer.new()
	content_panel.self_modulate = Color(1, 1, 1, 0.92)
	content_panel.add_theme_stylebox_override("panel", _make_dark_panel_style())
	margin.add_child(content_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	content_panel.add_child(layout)

	var title := Label.new()
	title.text = "Fairy House"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.visible = false
	layout.add_child(title)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stats_label.add_theme_constant_override("shadow_offset_x", 2)
	stats_label.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(stats_label)

	var workers_title := Label.new()
	workers_title.text = "Fairy Workers"
	workers_title.add_theme_font_size_override("font_size", 24)
	workers_title.add_theme_color_override("font_color", Color("#f3d57a"))
	workers_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	workers_title.add_theme_constant_override("shadow_offset_x", 2)
	workers_title.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(workers_title)

	fairy_cards_container = VBoxContainer.new()
	fairy_cards_container.add_theme_constant_override("separation", 14)
	layout.add_child(fairy_cards_container)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 24)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	layout.add_child(feedback_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	layout.add_child(buttons)
	buttons.add_child(_make_button("Upgrade House", _on_upgrade_pressed))
	buttons.add_child(_make_button("Back", _on_back_pressed))


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 76)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	return button


func _make_cottage_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(920, 330)

	_add_sprite(preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(92, 12), Vector2(736, 292))
	_add_sprite(preview, "res://assets/sprites/buildings/fairy_house_scene.png", Vector2(330, 38), Vector2(300, 254))
	_add_sprite(preview, "res://assets/sprites/characters/fairy_luna.png", Vector2(210, 104), Vector2(86, 140))
	_add_sprite(preview, "res://assets/sprites/characters/fairy_pond_keeper.png", Vector2(624, 96), Vector2(86, 136))
	_add_sprite(preview, "res://assets/sprites/effects/glow_orb.png", Vector2(632, 130), Vector2(54, 54))

	for offset in [Vector2(224, 235), Vector2(296, 246), Vector2(370, 257), Vector2(446, 268)]:
		_add_sprite(preview, "res://assets/sprites/environment/path_straight.png", offset, Vector2(58, 58))
	for offset in [Vector2(202, 142), Vector2(665, 160), Vector2(245, 238), Vector2(632, 238)]:
		_add_sprite(preview, "res://assets/sprites/environment/purple_mushroom_cluster.png", offset, Vector2(46, 46))
	for index in range(6):
		_add_sprite(preview, "res://assets/sprites/environment/fence_post.png", Vector2(235 + index * 82, 250), Vector2(24, 54))

	return preview


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


func _make_dark_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, 0.78)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _refresh() -> void:
	stats_label.text = (
		"Level %d\nResidents: %d / %d\nWorkers Active: %d"
		% [
			GameState.fairy_house_level,
			GameState.fairy_residents,
			GameState.fairy_max_residents,
			GameState.fairy_workers_active
		]
	)
	_rebuild_fairy_cards()


func _rebuild_fairy_cards() -> void:
	for child in fairy_cards_container.get_children():
		child.queue_free()

	for fairy in GameState.fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		fairy_cards_container.add_child(_make_fairy_card(fairy))


func _make_fairy_card(fairy: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.self_modulate = Color(0.03, 0.035, 0.06, 0.88)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var assigned_area := String(fairy.get("AssignedArea", GameState.FAIRY_AREA_UNASSIGNED))
	var fairy_name := String(fairy.get("FairyName", "Fairy"))
	var details := Label.new()
	details.text = (
		"%s\nLevel %d | %s\nAssigned Area: %s\nBonus: %s"
		% [
			fairy_name,
			int(fairy.get("FairyLevel", 1)),
			String(fairy.get("FairyRole", "Helper")),
			assigned_area,
			GameState.get_fairy_bonus_text(fairy)
		]
	)
	details.add_theme_font_size_override("font_size", 24)
	details.add_theme_color_override("font_color", Color.WHITE)
	details.add_theme_color_override("font_shadow_color", Color.BLACK)
	details.add_theme_constant_override("shadow_offset_x", 2)
	details.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(details)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	layout.add_child(buttons)
	buttons.add_child(_make_assignment_button("Assign to Flower Grove", fairy_name, GameState.FAIRY_AREA_FLOWER_GROVE, assigned_area))
	buttons.add_child(_make_assignment_button("Assign to Sacred Pond", fairy_name, GameState.FAIRY_AREA_SACRED_POND, assigned_area))
	buttons.add_child(_make_assignment_button("Unassign", fairy_name, GameState.FAIRY_AREA_UNASSIGNED, assigned_area))

	return card


func _make_assignment_button(text: String, fairy_name: String, area: String, assigned_area: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.disabled = area == assigned_area
	button.pressed.connect(func() -> void:
		feedback_label.text = GameState.assign_fairy_to_area(fairy_name, area)
		_refresh()
	)
	return button


func _on_upgrade_pressed() -> void:
	feedback_label.text = "House upgrades will be added later."


func _on_back_pressed() -> void:
	GameState.save_game()
	closed.emit()
