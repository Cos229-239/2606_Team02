extends Control

const MAIN_VILLAGE_PATH := "res://scenes/MainVillage.tscn"

var hint_label: Label
var hint_panel: PanelContainer
var message_label: Label
var sprout_button: Button
var seed_piece: Button
var bloom_sprout: Control
var color_wash: ColorRect
var dragging_seed := false
var seed_spawned := false
var merge_complete := false
var seed_drag_offset := Vector2.ZERO


func _ready() -> void:
	_build_scene()


func _build_scene() -> void:
	var background := _add_sprite(
		"res://assets/sprites/backgrounds/abandoned_village_bg.png",
		Vector2(0, 0),
		Vector2(1080, 1920),
		0.0,
		Color.WHITE
	)
	background.z_index = -10

	sprout_button = Button.new()
	sprout_button.text = ""
	sprout_button.position = Vector2(505, 676)
	sprout_button.size = Vector2(150, 170)
	sprout_button.focus_mode = Control.FOCUS_NONE
	sprout_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	sprout_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	sprout_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	sprout_button.pressed.connect(_on_sprout_pressed)
	add_child(sprout_button)
	var sprout_art := _add_sprite(
		"res://assets/sprites/abandoned_nook/dead_flower.png",
		sprout_button.position,
		sprout_button.size
	)
	sprout_art.z_index = 1
	sprout_button.set_meta("art", sprout_art)

	hint_label = Label.new()
	hint_panel = _make_hint_panel("Tap the dead flower to begin")
	hint_panel.position = Vector2(290, 420)
	hint_panel.size = Vector2(500, 60)
	add_child(hint_panel)
	hint_label = hint_panel.get_child(0)

	_add_arrow(Vector2(580, 498), Vector2(580, 650))

	message_label = Label.new()
	message_label.position = Vector2(150, 1140)
	message_label.size = Vector2(780, 80)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color("#fff2a8"))
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 3)
	message_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(message_label)

	color_wash = ColorRect.new()
	color_wash.color = Color("#4bbf78", 0.0)
	color_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_wash)


func _spawn_seed() -> void:
	if seed_spawned or merge_complete:
		return
	seed_spawned = true
	hint_label.text = "Drag matching life together."
	_show_sparkles(Vector2(540, 858), Color("#b8ffd6"))

	seed_piece = Button.new()
	seed_piece.text = ""
	seed_piece.position = Vector2(665, 676)
	seed_piece.size = Vector2(150, 170)
	seed_piece.focus_mode = Control.FOCUS_NONE
	seed_piece.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	seed_piece.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	seed_piece.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	seed_piece.gui_input.connect(_on_seed_gui_input)
	add_child(seed_piece)
	var seed_art := _add_sprite(
		"res://assets/sprites/abandoned_nook/seed.png",
		seed_piece.position,
		seed_piece.size
	)
	seed_art.z_index = 1
	seed_piece.set_meta("art", seed_art)


func _on_sprout_pressed() -> void:
	_spawn_seed()


func _on_seed_gui_input(event: InputEvent) -> void:
	if merge_complete:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_seed = true
			seed_drag_offset = event.position
			seed_piece.move_to_front()
			_get_seed_art().z_index = 2
		else:
			dragging_seed = false
			_try_first_merge()
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragging_seed = true
			seed_drag_offset = event.position
			seed_piece.move_to_front()
			_get_seed_art().z_index = 2
		else:
			dragging_seed = false
			_try_first_merge()
	elif dragging_seed and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		seed_piece.global_position = get_global_mouse_position() - seed_drag_offset
		_get_seed_art().global_position = seed_piece.global_position


func _get_seed_art() -> Sprite2D:
	return seed_piece.get_meta("art") as Sprite2D


func _get_sprout_art() -> Sprite2D:
	return sprout_button.get_meta("art") as Sprite2D


func _try_first_merge() -> void:
	if seed_piece == null:
		return
	var seed_center := seed_piece.position + seed_piece.size * 0.5
	var sprout_rect := Rect2(sprout_button.position, sprout_button.size).grow(44)
	if sprout_rect.has_point(seed_center):
		_complete_first_merge()


func _complete_first_merge() -> void:
	if merge_complete:
		return
	merge_complete = true
	hint_panel.visible = false
	if seed_piece:
		_get_seed_art().queue_free()
		seed_piece.queue_free()
	if sprout_button:
		_get_sprout_art().queue_free()
		sprout_button.queue_free()
	_show_bloom_sprout()
	_show_sparkles(Vector2(540, 850), Color("#fff2a8"))
	_show_floating_text("+10 Mana", Vector2(448, 782), Color("#f3d57a"))
	message_label.text = "Life returns to the grove."
	GameState.complete_onboarding_merge()

	var tween := create_tween()
	tween.tween_property(color_wash, "color", Color("#4bbf78", 0.18), 0.7)
	tween.tween_interval(1.2)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(MAIN_VILLAGE_PATH)
	)


func _show_bloom_sprout() -> void:
	bloom_sprout = Control.new()
	bloom_sprout.position = Vector2(505, 676)
	bloom_sprout.size = Vector2(150, 170)
	add_child(bloom_sprout)

	var glow_art := _add_sprite(
		"res://assets/sprites/abandoned_nook/bloom_glow.png",
		bloom_sprout.position - Vector2(20, 20),
		bloom_sprout.size + Vector2(40, 40)
	)
	glow_art.z_index = 1

	var flower_art := _add_sprite(
		"res://assets/sprites/abandoned_nook/bloom_flower.png",
		bloom_sprout.position,
		bloom_sprout.size
	)
	flower_art.z_index = 2


func _show_sparkles(origin: Vector2, color: Color) -> void:
	for index in range(10):
		var sparkle := ColorRect.new()
		sparkle.color = color
		sparkle.position = origin + Vector2(cos(index) * 70.0, sin(index * 1.7) * 52.0)
		sparkle.size = Vector2(10, 10)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sparkle)
		var tween := create_tween()
		tween.tween_property(sparkle, "position", sparkle.position + Vector2(0, -48), 0.58)
		tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 0.58)
		tween.tween_callback(sparkle.queue_free)


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = start_position
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -90), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _add_dead_tree(pos: Vector2) -> void:
	_add_shadow_ellipse(pos + Vector2(62, 128), Vector2(72, 20), 0.24)


func _add_arrow(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 5
	line.default_color = Color("#fff2d6", 0.65)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)
	var head := Polygon2D.new()
	head.color = Color("#fff2d6", 0.65)
	head.polygon = PackedVector2Array([
		to,
		to + Vector2(-24, -38),
		to + Vector2(24, -38)
	])
	add_child(head)


func _add_sprite(path: String, top_left: Vector2, size: Vector2, rotation: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + size * 0.5
	sprite.rotation = rotation
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	add_child(sprite)
	return sprite


func _add_local_ellipse(parent: Node, center: Vector2, radius: Vector2, color: Color, alpha: float = 1.0) -> Polygon2D:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var ellipse := Polygon2D.new()
	ellipse.polygon = points
	ellipse.color = Color(color.r, color.g, color.b, alpha)
	parent.add_child(ellipse)
	return ellipse


func _add_ellipse(center: Vector2, radius: Vector2, color: Color, alpha: float = 1.0) -> Polygon2D:
	return _add_local_ellipse(self, center, radius, color, alpha)


func _add_shadow_ellipse(center: Vector2, radius: Vector2, alpha: float) -> Polygon2D:
	return _add_ellipse(center, radius, Color.BLACK, alpha)


func _make_piece_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style


func _make_hint_panel(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a1410", 0.72)
	style.border_color = Color("#f3d57a", 0.55)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("#fff2d6"))
	panel.add_child(label)
	return panel
