extends SceneTree

const SCENE_PATH := "res://ui/PondDecoratePanel.tscn"
const SCRIPT_PATH := "res://scripts/pond_decorate_panel.gd"

const TEX_POND_BG := "res://assets/sprites/panels/sacred_pond_zoom.png"
const TEX_TITLE := "res://assets/sprites/ui/decorate_title_plaque.png"
const TEX_SLOT := "res://assets/sprites/ui/decorate_slot_marker.png"
const TEX_PLACE := "res://assets/sprites/ui/decorate_place_button.png"
const TEX_REMOVE := "res://assets/sprites/ui/decorate_remove_button.png"
const TEX_BACK := "res://assets/sprites/ui/decorate_back_button.png"

const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")


func _initialize() -> void:
	var root := PanelContainer.new()
	root.name = "PondDecoratePanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.script = load(SCRIPT_PATH)

	var scene_root := Control.new()
	scene_root.name = "Root"
	scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scene_root)
	scene_root.owner = root

	_add_color(scene_root, "DarkBackground", Vector2.ZERO, DESIGN_SIZE, Color("#030813"))
	_add_sprite(scene_root, "PondBackground", TEX_POND_BG, Vector2(540, 960), Vector2(1080, 1920), Color(0.78, 0.82, 0.9, 1.0))
	_add_color(scene_root, "Vignette", Vector2.ZERO, DESIGN_SIZE, Color(0, 0, 0, 0.22))
	_add_sprite(scene_root, "TitlePlaque", TEX_TITLE, Vector2(540, 96), Vector2(830, 145))
	_add_label(scene_root, "TitleLabel", "Sacred Koi Pond", Vector2(230, 70), Vector2(620, 66), 56, TEXT_LIGHT)

	var stats := Control.new()
	stats.name = "Stats"
	stats.position = Vector2.ZERO
	stats.size = DESIGN_SIZE
	scene_root.add_child(stats)
	stats.owner = root
	_add_stat_card(stats, "PondBeautyCard", "Pond Beauty", Vector2(72, 186), Vector2(280, 104))
	_add_stat_card(stats, "ManaCard", "Mana", Vector2(400, 186), Vector2(280, 104))
	_add_stat_card(stats, "DecorationBonusCard", "Decoration Bonus", Vector2(728, 186), Vector2(280, 104))

	var pond_layer := Control.new()
	pond_layer.name = "PondLayer"
	pond_layer.position = Vector2.ZERO
	pond_layer.size = DESIGN_SIZE
	scene_root.add_child(pond_layer)
	pond_layer.owner = root

	var slot_positions := [
		Vector2(300, 438),
		Vector2(810, 535),
		Vector2(218, 900),
		Vector2(742, 1005),
		Vector2(548, 394),
		Vector2(540, 1038)
	]
	for index in range(slot_positions.size()):
		_add_texture_button(pond_layer, "Slot%d" % index, TEX_SLOT, slot_positions[index] - Vector2(58, 38), Vector2(116, 76))

	_add_label(scene_root, "FeedbackLabel", "", Vector2(120, 1182), Vector2(840, 36), 26, GOLD)
	_add_decoration_tray(scene_root)
	_add_action_row(scene_root)

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		push_error("Could not pack PondDecoratePanel scene.")
		quit(1)
		return
	result = ResourceSaver.save(packed, SCENE_PATH)
	if result != OK:
		push_error("Could not save PondDecoratePanel scene.")
		quit(1)
		return
	print("Editable PondDecoratePanel scene saved.")
	quit()


func _add_color(parent: Node, node_name: String, pos: Vector2, node_size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = pos
	rect.size = node_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.owner = _get_owner(parent)
	return rect


func _add_sprite(parent: Node, node_name: String, path: String, center: Vector2, target_size: Vector2, tint: Color = Color.WHITE) -> Sprite2D:
	var texture: Texture2D = load(path)
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = center
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if texture:
		var scale_factor: float = min(target_size.x / float(texture.get_width()), target_size.y / float(texture.get_height()))
		sprite.scale = Vector2(scale_factor, scale_factor)
	parent.add_child(sprite)
	sprite.owner = _get_owner(parent)
	return sprite


func _add_texture_button(parent: Node, node_name: String, path: String, pos: Vector2, node_size: Vector2) -> TextureButton:
	var texture: Texture2D = load(path)
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = pos
	button.size = node_size
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
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.owner = _get_owner(parent)
	return label


func _add_stat_card(parent: Node, node_name: String, title: String, pos: Vector2, node_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.position = pos
	card.size = node_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.018, 0.04, 0.86), Color("#b88b36"), 2, 12))
	parent.add_child(card)
	card.owner = _get_owner(parent)

	var title_label := _add_label(card, "Title", title, Vector2(0, 8), Vector2(node_size.x, 32), 20, GOLD)
	var value_label := _add_label(card, "Value", "0", Vector2(0, 42), Vector2(node_size.x, 48), 30, TEXT_LIGHT)
	title_label.owner = _get_owner(parent)
	value_label.owner = _get_owner(parent)
	return card


func _add_decoration_tray(parent: Node) -> void:
	var tray := Control.new()
	tray.name = "DecorationTray"
	tray.position = Vector2(36, 1222)
	tray.size = Vector2(1008, 424)
	parent.add_child(tray)
	tray.owner = _get_owner(parent)
	_add_color(tray, "TrayBackground", Vector2.ZERO, tray.size, Color(0.015, 0.022, 0.05, 0.84))
	_add_label(tray, "TrayTitle", "Select a Decoration", Vector2(0, 14), Vector2(1008, 52), 32, GOLD)

	var row := HBoxContainer.new()
	row.name = "DecorationRow"
	row.position = Vector2(24, 84)
	row.size = Vector2(960, 300)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	tray.add_child(row)
	row.owner = _get_owner(parent)

	var card_data := [
		["Moon Lantern", "res://assets/sprites/environment/moon_lantern.png", "Moon Lantern\n25 Mana\n+5 Beauty"],
		["Spirit Stone", "res://assets/sprites/environment/spirit_stone.png", "Spirit Stone\n40 Mana\n+8 Beauty"],
		["Bloom Lilypad", "res://assets/sprites/environment/bloom_lilypad.png", "Bloom Lilypad\n30 Mana\n+6 Beauty"],
		["Sacred Bridge", "res://assets/sprites/environment/sacred_bridge.png", "Sacred Bridge\n75 Mana\n+12 Beauty"]
	]
	for index in range(card_data.size()):
		var button := Button.new()
		button.name = "DecorationCard%d" % index
		button.custom_minimum_size = Vector2(228, 294)
		button.text = card_data[index][2]
		button.icon = load(card_data[index][1])
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", TEXT_LIGHT)
		button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.01, 0.016, 0.035, 0.88), Color("#8c6a2e"), 2, 10))
		button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.04, 0.06, 0.105, 0.92), GOLD, 3, 10))
		row.add_child(button)
		button.owner = _get_owner(parent)


func _add_action_row(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(32, 1698)
	row.size = Vector2(1016, 150)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)
	row.owner = _get_owner(parent)
	_add_texture_button(row, "PlaceButton", TEX_PLACE, Vector2.ZERO, Vector2(300, 118)).custom_minimum_size = Vector2(300, 118)
	_add_texture_button(row, "RemoveButton", TEX_REMOVE, Vector2.ZERO, Vector2(300, 118)).custom_minimum_size = Vector2(300, 118)
	_add_texture_button(row, "BackButton", TEX_BACK, Vector2.ZERO, Vector2(300, 118)).custom_minimum_size = Vector2(300, 118)


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
