extends PanelContainer

signal closed

var item_list: VBoxContainer
var summary_label: Label
var notes_label: Label


func _ready() -> void:
	self_modulate = Color(0.014, 0.018, 0.030, 0.96)
	GameState.resources_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	GameState.fairy_house_changed.connect(_refresh)
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 120)
	margin.add_theme_constant_override("margin_bottom", 150)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := _make_label("Inventory", 48, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	summary_label = _make_label("", 24, Color("#fff2a8"))
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(summary_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1, 900)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 14)
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_list)

	notes_label = _make_label("", 22, Color("#d9cfaa"))
	notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_label.custom_minimum_size = Vector2(1, 58)
	layout.add_child(notes_label)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): SoundManager.play_click(); closed.emit())
	layout.add_child(back_button)


func _refresh() -> void:
	if item_list == null:
		return
	for child in item_list.get_children():
		child.queue_free()

	var grouped_items := {}
	for item in GameState.get_inventory_items():
		var category := String(item.get("Category", "Other"))
		if not grouped_items.has(category):
			grouped_items[category] = []
		grouped_items[category].append(item)

	for category in grouped_items.keys():
		var header := _make_label(category, 30, Color("#f5d66f"))
		item_list.add_child(header)
		for item in grouped_items[category]:
			item_list.add_child(_make_item_row(item))

	var summary: Dictionary = GameState.get_inventory_summary()
	summary_label.text = "Stored goods: %d        Pond rewards: %d        Decorations placed: %d" % [
		int(summary.get("CraftedGoods", 0)),
		int(summary.get("UnlockedRewards", 0)),
		int(summary.get("PlacedDecorations", 0))
	]
	var notes: Array = summary.get("Notes", [])
	notes_label.text = "Notes: %s" % ", ".join(notes) if notes.size() > 0 else "Notes: New discoveries and rare goods will appear here."


func _make_item_row(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.030, 0.034, 0.052, 0.92), Color("#b99245"), 2, 8))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	var qty := _make_label(str(int(item.get("Quantity", 0))), 34, Color("#fff2a8"))
	qty.custom_minimum_size = Vector2(96, 74)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qty.add_theme_stylebox_override("normal", _make_style(Color(0.012, 0.018, 0.026, 0.88), Color("#6f5327"), 1, 8))
	row.add_child(qty)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	text_box.add_child(_make_label(String(item.get("Name", "Unknown Item")), 28, Color("#fff2a8")))
	var description := _make_label(String(item.get("Description", "")), 21, Color("#e8dfca"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(description)
	return panel


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 76)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	return button


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
