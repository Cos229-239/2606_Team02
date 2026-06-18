extends SceneTree

const SCENE_PATH := "res://ui/FairyHousePanel.tscn"
const SCRIPT_PATH := "res://scripts/fairy_house_panel.gd"

const TEX_BG := "res://assets/sprites/fairy_house/fairy_house_interior.png"
const TEX_TITLE := "res://assets/sprites/fairy_house/title_plaque.png"
const TEX_BUTTON_WORKERS := "res://assets/sprites/fairy_house/button_workers.png"
const TEX_BUTTON_TASKS := "res://assets/sprites/fairy_house/button_tasks.png"
const TEX_BUTTON_UPGRADES := "res://assets/sprites/fairy_house/button_upgrades.png"
const TEX_BUTTON_BACK := "res://assets/sprites/fairy_house/button_back.png"
const TEX_LUNA := "res://assets/sprites/fairy_house/fairy_luna_gatherer.png"
const TEX_PIP := "res://assets/sprites/fairy_house/fairy_pip_pond_keeper.png"
const TEX_NIM := "res://assets/sprites/fairy_house/fairy_nim_sleeping.png"
const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")


func _initialize() -> void:
	var root := PanelContainer.new()
	root.name = "FairyHousePanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.script = load(SCRIPT_PATH)

	var scene_root := Control.new()
	scene_root.name = "Root"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scene_root)
	scene_root.owner = root

	_add_color(scene_root, "DarkBackground", Vector2.ZERO, DESIGN_SIZE, Color("#09050a"))
	_add_texture_rect(scene_root, "FairyHouseBackground", TEX_BG, Vector2.ZERO, DESIGN_SIZE)
	_add_color(scene_root, "SoftVignette", Vector2.ZERO, DESIGN_SIZE, Color(0, 0, 0, 0.18))

	_add_sprite(scene_root, "TitlePlaque", TEX_TITLE, Vector2(174, 24), Vector2(732, 188))
	_add_color(scene_root, "StatsPanelBackground", Vector2(88, 190), Vector2(904, 106), Color(0.012, 0.018, 0.04, 0.80), Color("#b88b36"), 2, 14)
	_add_label(scene_root, "StatsLabel", "Residents  3 / 3        Workers Active  2        Resting  1        House Level  1", Vector2(112, 204), Vector2(856, 78), 23, TEXT_LIGHT)

	_add_scene_fairies(scene_root)

	_add_label(scene_root, "WorkersTitle", "Fairy Workers", Vector2(90, 1098), Vector2(900, 48), 32, GOLD)

	var scroll := ScrollContainer.new()
	scroll.name = "FairyCardsScroll"
	scroll.position = Vector2(72, 1152)
	scroll.size = Vector2(936, 350)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scene_root.add_child(scroll)
	scroll.owner = root

	var cards := HBoxContainer.new()
	cards.name = "FairyCardsContainer"
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 15)
	scroll.add_child(cards)
	cards.owner = root
	_add_editor_preview_cards(cards)

	_add_label(scene_root, "FeedbackLabel", "", Vector2(110, 1510), Vector2(860, 48), 25, GOLD)
	_add_action_row(scene_root)

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Could not pack FairyHousePanel scene.")
		quit(1)
		return
	result = ResourceSaver.save(packed, SCENE_PATH)
	if result != OK:
		push_error("Could not save FairyHousePanel scene.")
		quit(1)
		return
	print("Editable FairyHousePanel scene saved.")
	quit()


func _add_color(parent: Node, node_name: String, pos: Vector2, node_size: Vector2, color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0, radius: int = 0) -> Node:
	if border_width > 0:
		var panel := PanelContainer.new()
		panel.name = node_name
		panel.position = pos
		panel.size = node_size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _make_panel_style(color, border_color, border_width, radius))
		parent.add_child(panel)
		panel.owner = _get_owner(parent)
		return panel

	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = pos
	rect.size = node_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.owner = _get_owner(parent)
	return rect


func _add_texture_rect(parent: Node, node_name: String, path: String, pos: Vector2, node_size: Vector2, stretch_mode := TextureRect.STRETCH_KEEP_ASPECT_COVERED) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = load(path)
	rect.position = pos
	rect.size = node_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch_mode
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.owner = _get_owner(parent)
	return rect


func _add_sprite(parent: Node, node_name: String, path: String, pos: Vector2, node_size: Vector2) -> Sprite2D:
	var texture := load(path) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = pos + node_size * 0.5
	if texture:
		sprite.scale = Vector2(node_size.x / texture.get_width(), node_size.y / texture.get_height())
	parent.add_child(sprite)
	sprite.owner = _get_owner(parent)
	return sprite


func _add_label(parent: Node, node_name: String, text: String, pos: Vector2, node_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.size = node_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.owner = _get_owner(parent)
	return label


func _add_action_row(parent: Node) -> void:
	var bar := PanelContainer.new()
	bar.name = "ActionBarBackground"
	bar.position = Vector2(32, 1632)
	bar.size = Vector2(1016, 174)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.015, 0.018, 0.025, 0.68), Color("#6f5327"), 1, 16))
	parent.add_child(bar)
	bar.owner = _get_owner(parent)

	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(54, 1654)
	row.size = Vector2(972, 130)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	row.owner = _get_owner(parent)

	var workers := _add_art_button(row, "WorkersButton", TEX_BUTTON_WORKERS, Vector2(238, 112), "Workers")
	var tasks := _add_art_button(row, "TasksButton", TEX_BUTTON_TASKS, Vector2(218, 112), "Tasks")
	var upgrade := _add_art_button(row, "UpgradeHouseButton", TEX_BUTTON_UPGRADES, Vector2(250, 112), "Upgrade House")
	var back := _add_art_button(row, "BackButton", TEX_BUTTON_BACK, Vector2(218, 112), "Back")
	workers.owner = _get_owner(parent)
	tasks.owner = _get_owner(parent)
	upgrade.owner = _get_owner(parent)
	back.owner = _get_owner(parent)


func _add_editor_preview_cards(parent: Node) -> void:
	_add_editor_preview_card(parent, "EditorPreviewLunaCard", TEX_LUNA, "Luna", "Gatherer", "Sacred Koi Pond", "+2 Restore")
	_add_editor_preview_card(parent, "EditorPreviewPipCard", TEX_PIP, "Pip", "Pond Keeper", "Sacred Koi Pond", "+1 Restore")
	_add_editor_preview_card(parent, "EditorPreviewNimCard", TEX_NIM, "Nim", "Helper", "Unassigned", "No active bonus")


func _add_editor_preview_card(parent: Node, node_name: String, portrait_path: String, fairy_name: String, role: String, working_area: String, bonus: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.custom_minimum_size = Vector2(286, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.015, 0.018, 0.028, 0.78), Color("#b98c43"), 2, 18))
	parent.add_child(card)
	card.owner = _get_owner(parent)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	margin.owner = _get_owner(parent)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	layout.owner = _get_owner(parent)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.custom_minimum_size = Vector2(258, 238)
	content_row.add_theme_constant_override("separation", 12)
	layout.add_child(content_row)
	content_row.owner = _get_owner(parent)

	var portrait := Control.new()
	portrait.name = "PortraitFrame"
	portrait.custom_minimum_size = Vector2(96, 220)
	portrait.clip_contents = true
	content_row.add_child(portrait)
	portrait.owner = _get_owner(parent)

	var texture := load(portrait_path) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = "Portrait"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = Vector2(48, 112)
	if texture:
		var frame_size := Vector2(96, 220)
		var scale_factor: float = min(frame_size.x / texture.get_width(), frame_size.y / texture.get_height()) * (1.65 if fairy_name == "Nim" else 1.18)
		sprite.scale = Vector2.ONE * scale_factor
	portrait.add_child(sprite)
	sprite.owner = _get_owner(parent)

	var details := Label.new()
	details.name = "Details"
	details.text = "%s\n%s\nLevel 1\n\nWorking:\n%s\n\n%s" % [fairy_name, role, working_area, bonus]
	details.custom_minimum_size = Vector2(148, 220)
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", TEXT_LIGHT)
	details.add_theme_color_override("font_shadow_color", Color.BLACK)
	details.add_theme_constant_override("shadow_offset_x", 2)
	details.add_theme_constant_override("shadow_offset_y", 2)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_row.add_child(details)
	details.owner = _get_owner(parent)

	var button_row := HBoxContainer.new()
	button_row.name = "AssignmentPreviewButtons"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 6)
	layout.add_child(button_row)
	button_row.owner = _get_owner(parent)

	for label_text in ["Flower", "Pond", "Rest"]:
		var button := Button.new()
		button.name = "%sPreviewButton" % label_text
		button.text = label_text
		button.custom_minimum_size = Vector2(72, 38)
		button.add_theme_font_size_override("font_size", 14)
		button_row.add_child(button)
		button.owner = _get_owner(parent)

	return card


func _add_button(parent: Node, node_name: String, text: String, node_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = node_size
	button.size = node_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.01, 0.016, 0.035, 0.92), Color("#b88b36"), 2, 12))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.04, 0.06, 0.105, 0.94), GOLD, 3, 12))
	parent.add_child(button)
	button.owner = _get_owner(parent)
	return button


func _add_art_button(parent: Node, node_name: String, path: String, node_size: Vector2, tooltip: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.custom_minimum_size = node_size
	button.size = node_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = tooltip
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var texture := load(path) as Texture2D
	var sprite := Sprite2D.new()
	sprite.name = "Art"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = node_size * 0.5
	if texture:
		var scale_factor: float = min(node_size.x / texture.get_width(), node_size.y / texture.get_height())
		sprite.scale = Vector2.ONE * scale_factor
	button.add_child(sprite)
	parent.add_child(button)
	button.owner = _get_owner(parent)
	sprite.owner = _get_owner(parent)
	return button


func _add_scene_fairies(parent: Node) -> void:
	_add_sprite(parent, "LunaSceneSprite", TEX_LUNA, Vector2(132, 396), Vector2(164, 342))
	_add_sprite(parent, "PipSceneSprite", TEX_PIP, Vector2(486, 402), Vector2(150, 374))
	_add_sprite(parent, "NimSceneSprite", TEX_NIM, Vector2(106, 786), Vector2(228, 220))


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _get_owner(node: Node) -> Node:
	var current := node
	while current.owner:
		current = current.owner
	return current
