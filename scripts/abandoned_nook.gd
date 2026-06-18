extends Control

const MAIN_VILLAGE_PATH := "res://scenes/MainVillage.tscn"

var hint_label: Label
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
	var background := ColorRect.new()
	background.color = Color("#030807")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var clearing := Polygon2D.new()
	clearing.color = Color("#142016")
	clearing.polygon = PackedVector2Array([
		Vector2(96, 438), Vector2(944, 362), Vector2(1018, 1508), Vector2(92, 1598)
	])
	add_child(clearing)

	for pos in [
		Vector2(52, 272), Vector2(820, 262), Vector2(30, 930), Vector2(900, 964),
		Vector2(128, 1502), Vector2(816, 1558), Vector2(398, 316)
	]:
		_add_dead_tree(pos)

	for pos in [
		Vector2(214, 642), Vector2(772, 592), Vector2(162, 1218), Vector2(716, 1312),
		Vector2(504, 1470)
	]:
		_add_withered_prop(pos)

	_add_shadow_ellipse(Vector2(540, 962), Vector2(190, 54), 0.30)
	_add_ellipse(Vector2(540, 900), Vector2(108, 48), Color("#091611"), 0.88)

	sprout_button = Button.new()
	sprout_button.text = ""
	sprout_button.position = Vector2(465, 786)
	sprout_button.size = Vector2(150, 170)
	sprout_button.focus_mode = Control.FOCUS_NONE
	sprout_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	sprout_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	sprout_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	sprout_button.pressed.connect(_on_sprout_pressed)
	add_child(sprout_button)
	_build_sprout_art(sprout_button)

	hint_label = Label.new()
	hint_label.text = "Merge to Restore Life"
	hint_label.position = Vector2(250, 540)
	hint_label.size = Vector2(580, 64)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 34)
	hint_label.add_theme_color_override("font_color", Color("#f3d57a"))
	hint_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint_label.add_theme_constant_override("shadow_offset_x", 3)
	hint_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(hint_label)

	_add_arrow(Vector2(540, 628), Vector2(540, 780))

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


func _build_sprout_art(parent: Control) -> void:
	_add_local_ellipse(parent, Vector2(75, 134), Vector2(50, 18), Color("#112c20"), 0.90)
	_add_local_ellipse(parent, Vector2(75, 82), Vector2(28, 58), Color("#59f0a8"), 0.22)
	_add_local_ellipse(parent, Vector2(58, 76), Vector2(24, 14), Color("#58d68d"), 0.95)
	_add_local_ellipse(parent, Vector2(94, 72), Vector2(24, 14), Color("#8affc1"), 0.95)
	_add_local_ellipse(parent, Vector2(75, 104), Vector2(7, 42), Color("#8affc1"), 0.94)
	_add_local_ellipse(parent, Vector2(75, 74), Vector2(18, 18), Color("#cffff0"), 0.82)


func _spawn_seed() -> void:
	if seed_spawned or merge_complete:
		return
	seed_spawned = true
	hint_label.text = "Drag matching life together."
	_show_sparkles(Vector2(540, 858), Color("#b8ffd6"))

	seed_piece = Button.new()
	seed_piece.text = "Seed"
	seed_piece.position = Vector2(642, 850)
	seed_piece.size = Vector2(132, 112)
	seed_piece.focus_mode = Control.FOCUS_NONE
	seed_piece.add_theme_font_size_override("font_size", 22)
	seed_piece.add_theme_color_override("font_color", Color("#fff2a8"))
	seed_piece.add_theme_color_override("font_shadow_color", Color.BLACK)
	seed_piece.add_theme_stylebox_override("normal", _make_piece_style(Color("#5b3a21", 0.94), Color("#f3d57a")))
	seed_piece.add_theme_stylebox_override("hover", _make_piece_style(Color("#6f4a28", 0.98), Color("#fff2a8")))
	seed_piece.add_theme_stylebox_override("pressed", _make_piece_style(Color("#2c6b42", 0.98), Color("#b8ffd6")))
	seed_piece.gui_input.connect(_on_seed_gui_input)
	add_child(seed_piece)


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
		else:
			dragging_seed = false
			_try_first_merge()
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragging_seed = true
			seed_drag_offset = event.position
			seed_piece.move_to_front()
		else:
			dragging_seed = false
			_try_first_merge()
	elif dragging_seed and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		seed_piece.global_position = get_global_mouse_position() - seed_drag_offset


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
	hint_label.visible = false
	if seed_piece:
		seed_piece.queue_free()
	if sprout_button:
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
	bloom_sprout.position = Vector2(454, 772)
	bloom_sprout.size = Vector2(172, 190)
	add_child(bloom_sprout)
	_add_local_ellipse(bloom_sprout, Vector2(86, 152), Vector2(70, 22), Color("#153a25"), 0.92)
	_add_local_ellipse(bloom_sprout, Vector2(86, 88), Vector2(54, 54), Color("#a8ffbd"), 0.30)
	_add_local_ellipse(bloom_sprout, Vector2(52, 94), Vector2(32, 18), Color("#5ee692"), 0.96)
	_add_local_ellipse(bloom_sprout, Vector2(120, 92), Vector2(32, 18), Color("#80f7ae"), 0.96)
	_add_local_ellipse(bloom_sprout, Vector2(86, 72), Vector2(22, 22), Color("#f3d57a"), 0.96)
	_add_local_ellipse(bloom_sprout, Vector2(86, 116), Vector2(8, 50), Color("#9effc8"), 0.95)


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
	_add_sprite("res://assets/sprites/environment/ancient_tree_large.png", pos, Vector2(132, 158), 0.0, Color(0.20, 0.24, 0.20, 0.74))


func _add_withered_prop(pos: Vector2) -> void:
	_add_shadow_ellipse(pos + Vector2(36, 48), Vector2(44, 12), 0.18)
	_add_sprite("res://assets/sprites/environment/spirit_stone.png", pos, Vector2(54, 64), 0.0, Color(0.32, 0.36, 0.34, 0.76))


func _add_arrow(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 8
	line.default_color = Color("#f3d57a", 0.84)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)
	var head := Polygon2D.new()
	head.color = Color("#f3d57a", 0.84)
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
