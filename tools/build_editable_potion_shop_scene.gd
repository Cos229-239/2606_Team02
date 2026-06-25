extends SceneTree

const SCENE_PATH := "res://ui/PotionShopPanel.tscn"
const SCRIPT_PATH := "res://scripts/potion_shop_panel.gd"

const TEX_BG := "res://assets/sprites/panels/potion_shop_zoom.png"
const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")


func _initialize() -> void:
	var root := PanelContainer.new()
	root.name = "PotionShopPanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.script = load(SCRIPT_PATH)

	var scene_root := Control.new()
	scene_root.name = "Root"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scene_root)
	scene_root.owner = root

	_add_color(scene_root, "DarkBackground", Vector2.ZERO, DESIGN_SIZE, Color("#08040c"))
	_add_texture_rect(scene_root, "PotionShopBackground", TEX_BG, Vector2.ZERO, DESIGN_SIZE)
	_add_color(scene_root, "SoftVignette", Vector2.ZERO, DESIGN_SIZE, Color(0, 0, 0, 0.10))

	_add_color(scene_root, "StatsPanelBackground", Vector2(288, 150), Vector2(504, 520), Color(0.012, 0.018, 0.04, 0.78), Color("#b88b36"), 2, 16)
	_add_label(
		scene_root,
		"StatsLabel",
		"Shop Level\n1\n\nPotions Owned\n0 / 50\n\nCraft Speed\n5s\n\nMana Cost: 25  |  Sell: 50 Coins\nCoins: 0",
		Vector2(310, 172),
		Vector2(460, 476),
		24,
		TEXT_LIGHT
	)

	var progress := ProgressBar.new()
	progress.name = "CraftProgressBar"
	progress.position = Vector2(248, 1360)
	progress.size = Vector2(584, 34)
	progress.max_value = 100.0
	progress.value = 0.0
	progress.visible = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(progress)
	progress.owner = root

	_add_label(scene_root, "FeedbackLabel", "", Vector2(80, 1460), Vector2(920, 70), 28, GOLD)
	_add_action_row(scene_root)

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Could not pack PotionShopPanel scene.")
		quit(1)
		return
	result = ResourceSaver.save(packed, SCENE_PATH)
	if result != OK:
		push_error("Could not save PotionShopPanel scene.")
		quit(1)
		return
	print("Editable PotionShopPanel scene saved.")
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
	bar.position = Vector2(24, 1642)
	bar.size = Vector2(1032, 160)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.015, 0.018, 0.025, 0.68), Color("#6f5327"), 1, 16))
	parent.add_child(bar)
	bar.owner = _get_owner(parent)

	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(38, 1660)
	row.size = Vector2(1004, 124)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	row.owner = _get_owner(parent)

	_add_button(row, "BuyButton", "Buy", Vector2(190, 88))
	_add_button(row, "CraftPotionButton", "Craft Potion", Vector2(190, 88))
	_add_button(row, "SellPotionButton", "Sell Potion", Vector2(190, 88))
	_add_button(row, "UpgradeShopButton", "Upgrade Shop", Vector2(190, 88))
	_add_button(row, "BackButton", "Back", Vector2(190, 88))


func _add_button(parent: Node, node_name: String, text: String, node_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = node_size
	button.size = node_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.025, 0.028, 0.035, 0.92), Color("#9e7332"), 2, 10))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.10, 0.14, 0.08, 0.96), Color("#d0a246"), 2, 10))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.16, 0.22, 0.10, 0.98), GOLD, 2, 10))
	parent.add_child(button)
	button.owner = _get_owner(parent)
	return button


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
