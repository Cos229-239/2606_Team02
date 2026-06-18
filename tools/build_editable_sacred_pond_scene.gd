extends SceneTree

const SCENE_PATH := "res://ui/SacredPondPanel.tscn"
const SCRIPT_PATH := "res://scripts/sacred_pond_panel.gd"

const TEX_POND_BG := "res://assets/sprites/panels/sacred_pond_zoom.png"
const TEX_RESTORE := "res://assets/sprites/ui/panel_restore.png"
const TEX_DECORATE := "res://assets/sprites/ui/panel_decorate.png"
const TEX_UPGRADES := "res://assets/sprites/ui/panel_upgrades.png"
const TEX_BACK := "res://assets/sprites/ui/panel_back.png"

const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")


func _initialize() -> void:
	var root := PanelContainer.new()
	root.name = "SacredPondPanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.script = load(SCRIPT_PATH)

	var scene_root := Control.new()
	scene_root.name = "Root"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scene_root)
	scene_root.owner = root

	_add_color(scene_root, "DarkBackground", Vector2.ZERO, DESIGN_SIZE, Color("#020714"))
	_add_texture_rect(scene_root, "PondBackground", TEX_POND_BG, Vector2.ZERO, DESIGN_SIZE)
	_add_color(scene_root, "SoftVignette", Vector2.ZERO, DESIGN_SIZE, Color(0, 0, 0, 0.12))

	_add_color(scene_root, "StatsPanelBackground", Vector2(70, 1324), Vector2(940, 142), Color(0.012, 0.018, 0.04, 0.72), Color("#b88b36"), 2, 16)
	_add_label(
		scene_root,
		"StatsLabel",
		"Water Purity: 15%    Spirit Energy: 0    Pond Beauty: 0\nRestore Cost: 25 Mana    Decoration Bonus: +0%    Restore Amount: +5%\nActive Bonus: None\nNext Reward: Blooming Waters at 25%",
		Vector2(94, 1340),
		Vector2(892, 110),
		21,
		TEXT_LIGHT
	)

	_add_label(scene_root, "FeedbackLabel", "", Vector2(110, 1516), Vector2(860, 54), 28, GOLD)
	_add_action_row(scene_root)

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Could not pack SacredPondPanel scene.")
		quit(1)
		return
	result = ResourceSaver.save(packed, SCENE_PATH)
	if result != OK:
		push_error("Could not save SacredPondPanel scene.")
		quit(1)
		return
	print("Editable SacredPondPanel scene saved.")
	quit()


func _add_color(parent: Node, node_name: String, pos: Vector2, node_size: Vector2, color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0, radius: int = 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = pos
	rect.size = node_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if border_width > 0:
		var panel := PanelContainer.new()
		panel.name = node_name
		panel.position = pos
		panel.size = node_size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", _make_panel_style(color, border_color, border_width, radius))
		parent.add_child(panel)
		panel.owner = _get_owner(parent)
		return rect
	parent.add_child(rect)
	rect.owner = _get_owner(parent)
	return rect


func _add_texture_rect(parent: Node, node_name: String, path: String, pos: Vector2, node_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = load(path)
	rect.position = pos
	rect.size = node_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.owner = _get_owner(parent)
	return rect


func _add_texture_button(parent: Node, node_name: String, path: String, node_size: Vector2) -> TextureButton:
	var texture: Texture2D = load(path)
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = node_size
	button.size = node_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(button)
	button.owner = _get_owner(parent)
	return button


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
	bar.position = Vector2(38, 1604)
	bar.size = Vector2(1004, 178)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.015, 0.018, 0.025, 0.68), Color("#6f5327"), 1, 16))
	parent.add_child(bar)
	bar.owner = _get_owner(parent)

	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(50, 1624)
	row.size = Vector2(980, 140)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	row.owner = _get_owner(parent)

	_add_texture_button(row, "RestoreButton", TEX_RESTORE, Vector2(238, 130))
	_add_texture_button(row, "DecorateButton", TEX_DECORATE, Vector2(238, 130))
	_add_texture_button(row, "UpgradesButton", TEX_UPGRADES, Vector2(238, 130))
	_add_texture_button(row, "BackButton", TEX_BACK, Vector2(238, 130))


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
