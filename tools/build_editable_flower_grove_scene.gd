extends SceneTree

const SCENE_PATH := "res://ui/FlowerGrovePanel.tscn"
const SCRIPT_PATH := "res://scripts/flower_grove_panel.gd"

const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")

const TEX_BG := "res://assets/sprites/flower_grove/flower_grove_background.png"
const TEX_TITLE := "res://assets/sprites/flower_grove/flower_grove_title.png"
const TEX_PLOT_EMPTY := "res://assets/sprites/flower_grove/plot_tap_to_plant.png"
const TEX_PLOT_LOCKED := "res://assets/sprites/flower_grove/plot_locked.png"
const TEX_BUTTON_COLLECT := "res://assets/sprites/flower_grove/button_collect_mana.png"
const TEX_BUTTON_UPGRADE := "res://assets/sprites/flower_grove/button_upgrade_grove.png"
const TEX_BUTTON_UNLOCK := "res://assets/sprites/flower_grove/button_unlock_plot.png"
const TEX_BUTTON_BACK := "res://assets/sprites/flower_grove/button_back.png"


func _initialize() -> void:
	var root := PanelContainer.new()
	root.name = "FlowerGrovePanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.script = load(SCRIPT_PATH)

	var scene_root := Control.new()
	scene_root.name = "Root"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scene_root)
	scene_root.owner = root

	_add_color(scene_root, "DarkBackground", Vector2.ZERO, DESIGN_SIZE, Color("#02050a"))
	_add_texture_rect(scene_root, "FlowerGroveBackground", TEX_BG, Vector2.ZERO, DESIGN_SIZE, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_add_color(scene_root, "SoftVignette", Vector2.ZERO, DESIGN_SIZE, Color(0, 0, 0, 0.18))

	var preview_layer := Control.new()
	preview_layer.name = "GardenPreviewLayer"
	preview_layer.position = Vector2.ZERO
	preview_layer.size = DESIGN_SIZE
	preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(preview_layer)
	preview_layer.owner = root

	_add_texture_rect(scene_root, "TitlePlaque", TEX_TITLE, Vector2(110, 38), Vector2(860, 188), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_add_stat_panel(scene_root, "StoredManaPanel", "Stored Mana", "0 / 100", Vector2(250, 228), Vector2(260, 106))
	_add_stat_panel(scene_root, "ProductionPanel", "Production", "+5 / sec", Vector2(570, 228), Vector2(260, 106))
	_add_merge_grid(scene_root)
	_add_lower_stats(scene_root)
	_add_action_row(scene_root)

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Could not pack FlowerGrovePanel scene.")
		quit(1)
		return
	result = ResourceSaver.save(packed, SCENE_PATH)
	if result != OK:
		push_error("Could not save FlowerGrovePanel scene.")
		quit(1)
		return
	print("Editable FlowerGrovePanel scene saved.")
	quit()


func _add_stat_panel(parent: Node, node_name: String, title_text: String, value_text: String, pos: Vector2, node_size: Vector2) -> void:
	_add_color(parent, node_name, pos, node_size, Color(0.012, 0.016, 0.025, 0.78), Color("#b88b36"), 2, 14)
	_add_label(parent, "%sTitle" % node_name, title_text, pos + Vector2(10, 10), Vector2(node_size.x - 20, 34), 22, TEXT_LIGHT)
	_add_label(parent, "%sValue" % node_name, value_text, pos + Vector2(10, 44), Vector2(node_size.x - 20, 48), 32, Color("#ffffff"))


func _add_merge_grid(parent: Node) -> void:
	var panel := Control.new()
	panel.name = "MergeGridPanel"
	panel.position = Vector2(54, 360)
	panel.size = Vector2(972, 900)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(panel)
	panel.owner = _get_owner(parent)

	var grid := GridContainer.new()
	grid.name = "MergeGrid"
	grid.columns = 3
	grid.position = Vector2(0, 0)
	grid.size = panel.size
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 20)
	panel.add_child(grid)
	grid.owner = _get_owner(parent)

	for index in range(12):
		var slot := Button.new()
		slot.name = "GridSlot%d" % index
		slot.text = ""
		slot.custom_minimum_size = Vector2(312, 210)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_add_button_transparent_styles(slot)
		grid.add_child(slot)
		slot.owner = _get_owner(parent)

		var texture := TextureRect.new()
		texture.name = "PlotTexture"
		texture.texture = load(TEX_PLOT_EMPTY if index < 9 else TEX_PLOT_LOCKED)
		texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(texture)
		texture.owner = _get_owner(parent)

		var label := Label.new()
		label.name = "SlotText"
		label.text = "Tap to Plant" if index < 9 else "Locked"
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 23)
		label.add_theme_color_override("font_color", TEXT_LIGHT)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 3)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
		label.owner = _get_owner(parent)


func _add_lower_stats(parent: Node) -> void:
	_add_color(parent, "StatsPanelBackground", Vector2(58, 1310), Vector2(964, 208), Color(0.012, 0.016, 0.025, 0.78), Color("#b88b36"), 2, 20)
	var left_stats := _add_label(
		parent,
		"StatsLabel",
		"Level: 1\nStored Mana: 0 / 100\nActive Plots: 3 / 6\nUpgrade Cost: 25 Mana",
		Vector2(92, 1332),
		Vector2(418, 126),
		22,
		TEXT_LIGHT
	)
	left_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var right_stats := _add_label(
		parent,
		"StatsRightLabel",
		"Grid Production: +0/sec\nBase Production: +5/sec\nFairy Bonus: +0/sec\nTotal Production: +5/sec\nUnlock Plot Cost: 50 Mana",
		Vector2(536, 1332),
		Vector2(452, 126),
		22,
		TEXT_LIGHT
	)
	right_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_add_label(parent, "FeedbackLabel", "", Vector2(100, 1462), Vector2(880, 44), 24, GOLD)


func _add_action_row(parent: Node) -> void:
	_add_color(parent, "ActionBarBackground", Vector2(30, 1570), Vector2(1020, 248), Color(0.012, 0.016, 0.025, 0.76), Color("#6f5327"), 1, 16)

	var row := Control.new()
	row.name = "ActionRow"
	row.position = Vector2(54, 1604)
	row.size = Vector2(972, 164)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(row)
	row.owner = _get_owner(parent)

	_add_image_button(row, "CollectManaButton", TEX_BUTTON_COLLECT, Vector2(0, 0), Vector2(228, 140))
	_add_image_button(row, "UpgradeFlowerButton", TEX_BUTTON_UPGRADE, Vector2(248, 0), Vector2(228, 140))
	_add_image_button(row, "UnlockPlotButton", TEX_BUTTON_UNLOCK, Vector2(496, 0), Vector2(228, 140))
	_add_image_button(row, "BackButton", TEX_BUTTON_BACK, Vector2(744, 0), Vector2(228, 140))


func _add_image_button(parent: Node, node_name: String, texture_path: String, pos: Vector2, node_size: Vector2) -> Button:
	var holder := Control.new()
	holder.name = "%sArt" % node_name
	holder.position = pos
	holder.size = node_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	holder.owner = _get_owner(parent)

	var texture := TextureRect.new()
	texture.name = "Texture"
	texture.texture = load(texture_path)
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(texture)
	texture.owner = _get_owner(parent)

	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.position = pos
	button.size = node_size
	button.custom_minimum_size = node_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_add_button_transparent_styles(button)
	parent.add_child(button)
	button.owner = _get_owner(parent)
	return button


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


func _add_texture_rect(parent: Node, node_name: String, path: String, pos: Vector2, node_size: Vector2, stretch_mode: int) -> TextureRect:
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


func _add_button_transparent_styles(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)


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
