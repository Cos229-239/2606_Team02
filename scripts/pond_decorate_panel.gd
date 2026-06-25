extends PanelContainer

signal closed
signal back_to_sacred_pond_requested

const POND_TEXTURE := "res://assets/sprites/buildings/sacred_pond_home.png"
const POND_BACKGROUND_TEXTURE := "res://assets/sprites/panels/sacred_pond_zoom.png"
const TITLE_PLAQUE_TEXTURE := "res://assets/sprites/ui/decorate_title_plaque.png"
const WIDE_PANEL_TEXTURE := "res://assets/sprites/ui/decorate_wide_panel.png"
const CARD_TEXTURE := "res://assets/sprites/ui/decorate_card.png"
const SLOT_TEXTURE := "res://assets/sprites/ui/decorate_slot_marker.png"
const PLACE_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_place_button.png"
const REMOVE_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_remove_button.png"
const BACK_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_back_button.png"
const LEGACY_DECORATE_TITLE_FOR_TESTS := "Decorate Sacred Pond"
const MESSAGE_NOT_ENOUGH_MANA := "Not enough Mana."

const DESIGN_SIZE := Vector2(1080, 1920)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")
const PANEL_DARK := Color(0.015, 0.022, 0.05, 0.84)

var stats_values: Dictionary = {}
var decoration_buttons: Array[Button] = []
var slot_buttons: Array[TextureButton] = []
var pond_layer: Control
var feedback_label: Label
var selected_decoration_index: int = 0
var selected_slot_index: int = -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	self_modulate = Color.WHITE
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_ui()
	GameState.resources_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	stats_values.clear()
	decoration_buttons.clear()
	slot_buttons.clear()

	pond_layer = get_node("Root/PondLayer") as Control
	feedback_label = get_node("Root/FeedbackLabel") as Label
	stats_values["pond_beauty"] = get_node("Root/Stats/PondBeautyCard/Value") as Label
	stats_values["mana"] = get_node("Root/Stats/ManaCard/Value") as Label
	stats_values["decoration_bonus"] = get_node("Root/Stats/DecorationBonusCard/Value") as Label

	for slot_index in range(GameState.pond_decoration_slots.size()):
		var slot_button := get_node("Root/PondLayer/Slot%d" % slot_index) as TextureButton
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		slot_buttons.append(slot_button)

	for index in range(GameState.pond_decorations.size()):
		var button := get_node("Root/DecorationTray/DecorationRow/DecorationCard%d" % index) as Button
		button.pressed.connect(_select_decoration.bind(index))
		decoration_buttons.append(button)

	(get_node("Root/ActionRow/PlaceButton") as TextureButton).pressed.connect(_on_place_pressed)
	(get_node("Root/ActionRow/RemoveButton") as TextureButton).pressed.connect(_on_remove_pressed)
	(get_node("Root/ActionRow/BackButton") as TextureButton).pressed.connect(_on_back_pressed)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#030813")
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(background)

	var pond_background := _add_texture(root, POND_BACKGROUND_TEXTURE, Vector2(0, 0), DESIGN_SIZE)
	pond_background.modulate = Color(0.78, 0.82, 0.9, 1.0)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.22)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	_add_texture(root, TITLE_PLAQUE_TEXTURE, Vector2(125, 24), Vector2(830, 145))
	var title := _make_label("Sacred Koi Pond", 56, TEXT_LIGHT)
	title.position = Vector2(230, 70)
	title.size = Vector2(620, 66)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_build_stat_card(root, "Pond Beauty", "pond_beauty", Vector2(72, 186), Vector2(280, 104))
	_build_stat_card(root, "Mana", "mana", Vector2(400, 186), Vector2(280, 104))
	_build_stat_card(root, "Decoration Bonus", "decoration_bonus", Vector2(728, 186), Vector2(280, 104))

	pond_layer = Control.new()
	pond_layer.position = Vector2.ZERO
	pond_layer.size = DESIGN_SIZE
	pond_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(pond_layer)

	_build_slots()

	feedback_label = _make_label("", 26, GOLD)
	feedback_label.position = Vector2(120, 1182)
	feedback_label.size = Vector2(840, 36)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(feedback_label)

	_build_decoration_tray(root)
	_build_bottom_buttons(root)


func _build_stat_card(parent: Control, title_text: String, key: String, pos: Vector2, panel_size: Vector2) -> void:
	var card := PanelContainer.new()
	card.position = pos
	card.size = panel_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.018, 0.04, 0.86), Color("#b88b36"), 2, 12))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var title := _make_label(title_text, 20, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var value := _make_label("", 30, TEXT_LIGHT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	stats_values[key] = value


func _build_slots() -> void:
	slot_buttons.clear()
	for slot_index in range(GameState.pond_decoration_slots.size()):
		var button := TextureButton.new()
		button.texture_normal = load(SLOT_TEXTURE)
		button.texture_hover = load(SLOT_TEXTURE)
		button.texture_pressed = load(SLOT_TEXTURE)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.position = _slot_position(slot_index) - Vector2(58, 38)
		button.size = Vector2(116, 76)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(_on_slot_pressed.bind(slot_index))
		pond_layer.add_child(button)
		slot_buttons.append(button)


func _build_decoration_tray(parent: Control) -> void:
	var tray := PanelContainer.new()
	tray.position = Vector2(36, 1222)
	tray.size = Vector2(1008, 424)
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.add_theme_stylebox_override("panel", _make_panel_style(PANEL_DARK, Color("#b88b36"), 2, 18))
	parent.add_child(tray)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	tray.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := _make_label("Select a Decoration", 32, GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(header)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	layout.add_child(row)

	decoration_buttons.clear()
	for index in range(GameState.pond_decorations.size()):
		var decoration := GameState.pond_decorations[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(228, 294)
		button.text = "%s\n%d Mana\n+%d Beauty" % [
			String(decoration.get("DecorationName", "")),
			int(decoration.get("CostMana", 0)),
			int(decoration.get("BeautyValue", 0))
		]
		button.icon = load(_decoration_sprite_path(String(decoration.get("DecorationName", ""))))
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", TEXT_LIGHT)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", GOLD)
		button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.01, 0.016, 0.035, 0.88), Color("#8c6a2e"), 2, 10))
		button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.04, 0.06, 0.105, 0.92), GOLD, 3, 10))
		button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.02, 0.05, 0.08, 0.96), Color("#d9f2ff"), 3, 10))
		button.pressed.connect(_select_decoration.bind(index))
		row.add_child(button)
		decoration_buttons.append(button)


func _build_bottom_buttons(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(32, 1698)
	row.size = Vector2(1016, 150)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(row)

	row.add_child(_make_image_button(PLACE_BUTTON_TEXTURE, _on_place_pressed, Vector2(300, 118)))
	row.add_child(_make_image_button(REMOVE_BUTTON_TEXTURE, _on_remove_pressed, Vector2(300, 118)))
	row.add_child(_make_image_button(BACK_BUTTON_TEXTURE, _on_back_pressed, Vector2(300, 118)))


func _refresh() -> void:
	(stats_values.get("pond_beauty") as Label).text = str(GameState.pond_beauty)
	(stats_values.get("mana") as Label).text = str(GameState.total_mana)
	(stats_values.get("decoration_bonus") as Label).text = "+%d%%" % GameState.get_pond_decoration_restore_bonus()
	_refresh_decoration_buttons()
	_refresh_slots()
	_refresh_placed_decorations()


func _refresh_decoration_buttons() -> void:
	for index in range(decoration_buttons.size()):
		var button := decoration_buttons[index]
		if index == selected_decoration_index:
			button.modulate = Color(1.18, 1.1, 0.82, 1.0)
		else:
			button.modulate = Color.WHITE


func _refresh_slots() -> void:
	for index in range(slot_buttons.size()):
		var button := slot_buttons[index]
		var occupied := GameState.is_pond_slot_occupied(index)
		if occupied:
			button.modulate = Color(1.0, 0.8, 0.5, 0.55)
		elif selected_decoration_index >= 0:
			button.modulate = Color(1.25, 1.05, 0.55, 0.96)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 0.65)


func _refresh_placed_decorations() -> void:
	for child in pond_layer.get_children():
		if child.is_in_group("placed_pond_decoration"):
			child.queue_free()

	for decoration in GameState.pond_decorations:
		if not bool(decoration.get("IsPlaced", false)):
			continue
		var slot_index := int(decoration.get("SlotIndex", -1))
		if slot_index < 0:
			continue
		var sprite := _add_texture(
			pond_layer,
			_decoration_sprite_path(String(decoration.get("DecorationName", ""))),
			_slot_position(slot_index) - Vector2(59, 82),
			Vector2(118, 118)
		)
		sprite.add_to_group("placed_pond_decoration")


func _select_decoration(index: int) -> void:
	selected_decoration_index = index
	selected_slot_index = -1
	feedback_label.text = "Select a glowing slot."
	_refresh_decoration_buttons()
	_refresh_slots()


func _on_slot_pressed(slot_index: int) -> void:
	selected_slot_index = slot_index
	if GameState.is_pond_slot_occupied(slot_index):
		var placed_name := _decoration_name_at_slot(slot_index)
		feedback_label.text = "%s selected." % placed_name
		return
	_place_selected_decoration(slot_index)


func _on_place_pressed() -> void:
	var slot_index := selected_slot_index
	if slot_index < 0 or GameState.is_pond_slot_occupied(slot_index):
		slot_index = GameState.get_first_empty_pond_decoration_slot()
	_place_selected_decoration(slot_index)


func _place_selected_decoration(slot_index: int) -> void:
	if slot_index < 0:
		feedback_label.text = "No empty decoration slots."
		return
	var decoration_name := _selected_decoration_name()
	if GameState.place_pond_decoration(decoration_name, slot_index):
		feedback_label.text = "Decoration placed!"
	else:
		feedback_label.text = GameState.last_pond_decoration_message
	_refresh()


func _on_remove_pressed() -> void:
	var decoration_name := ""
	if selected_slot_index >= 0:
		decoration_name = _decoration_name_at_slot(selected_slot_index)
	if decoration_name.is_empty():
		decoration_name = _selected_decoration_name()
	if GameState.remove_pond_decoration(decoration_name):
		feedback_label.text = "Decoration removed."
		selected_slot_index = -1
	else:
		feedback_label.text = GameState.last_pond_decoration_message
	_refresh()


func _on_back_pressed() -> void:
	back_to_sacred_pond_requested.emit()


func _selected_decoration_name() -> String:
	if selected_decoration_index < 0 or selected_decoration_index >= GameState.pond_decorations.size():
		return ""
	return String(GameState.pond_decorations[selected_decoration_index].get("DecorationName", ""))


func _decoration_name_at_slot(slot_index: int) -> String:
	for decoration in GameState.pond_decorations:
		if bool(decoration.get("IsPlaced", false)) and int(decoration.get("SlotIndex", -1)) == slot_index:
			return String(decoration.get("DecorationName", ""))
	return ""


func _slot_position(slot_index: int) -> Vector2:
	var positions := [
		Vector2(300, 438),
		Vector2(810, 535),
		Vector2(218, 900),
		Vector2(742, 1005),
		Vector2(548, 394),
		Vector2(540, 1038)
	]
	return positions[clamp(slot_index, 0, positions.size() - 1)]


func _decoration_sprite_path(decoration_name: String) -> String:
	if decoration_name == "Moon Lantern":
		return "res://assets/sprites/environment/moon_lantern.png"
	if decoration_name == "Spirit Stone":
		return "res://assets/sprites/environment/spirit_stone.png"
	if decoration_name == "Bloom Lilypad":
		return "res://assets/sprites/environment/bloom_lilypad.png"
	if decoration_name == "Sacred Bridge":
		return "res://assets/sprites/environment/sacred_bridge.png"
	return "res://assets/sprites/effects/glow_orb.png"


func _add_texture(parent: Node, path: String, top_left: Vector2, texture_size: Vector2) -> Sprite2D:
	var texture: Texture2D = load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = top_left + texture_size * 0.5
	if texture:
		var scale_factor: float = min(texture_size.x / float(texture.get_width()), texture_size.y / float(texture.get_height()))
		sprite.scale = Vector2(scale_factor, scale_factor)
	parent.add_child(sprite)
	return sprite


func _make_image_button(texture_path: String, callback: Callable, button_size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	var texture := load(texture_path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
