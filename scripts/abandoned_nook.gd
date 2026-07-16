extends Control

const MAIN_VILLAGE_PATH := "res://scenes/MainVillage.tscn"

var hint_label: Label
var hint_panel: PanelContainer
var message_label: Label
var message_panel: PanelContainer
var fade_overlay: ColorRect
var sprout_button: Button
var seed_piece: Button
var bloom_sprout: Control
var color_wash: ColorRect
var dragging_seed := false
var seed_spawned := false
var merge_complete := false
var seed_drag_offset := Vector2.ZERO

var highlight_ring: Polygon2D
var highlight_tween: Tween
var seed_shadow: Polygon2D


func _ready() -> void:
	_build_scene()
	SoundManager.play_music(SoundManager.TRACK_ABANDONED_NOOK)


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

	hint_panel = _make_hint_panel("Tap the dead flower to begin")
	hint_panel.position = Vector2(290, 280)
	hint_panel.size = Vector2(500, 60)
	add_child(hint_panel)
	hint_label = hint_panel.get_child(0)
	_fade_in_node(hint_panel, 0.4)

	_start_pulse_highlight(sprout_button.position + sprout_button.size * 0.5, Vector2(100, 112))

	message_panel = _make_message_panel("")
	message_panel.position = Vector2(300, 1096)
	message_panel.size = Vector2(560, 76)
	message_panel.modulate.a = 0.0
	add_child(message_panel)
	message_label = message_panel.get_child(0)

	color_wash = ColorRect.new()
	color_wash.color = Color("#4bbf78", 0.0)
	color_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_wash)

	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0.0)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.z_index = 100
	add_child(fade_overlay)


func _spawn_seed() -> void:
	if seed_spawned or merge_complete:
		return
	seed_spawned = true
	_update_hint_text("Drag matching life together.")
	_show_sparkles(Vector2(540, 858), Color("#b8ffd6"))

	seed_piece = Button.new()
	seed_piece.text = ""
	seed_piece.position = Vector2(683, 697)
	seed_piece.size = Vector2(115, 130)
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

	seed_shadow = _add_ellipse(
		seed_piece.position + Vector2(seed_piece.size.x * 0.5, seed_piece.size.y - 18.0),
		Vector2(46, 14),
		Color.BLACK,
		0.0
	)
	seed_shadow.z_index = 0
	var shadow_tween := create_tween()
	shadow_tween.tween_property(seed_shadow, "color:a", 0.22, 0.28)

	_pop_in(seed_art, 0.3)

	# Re-highlight the drop target now that the seed needs to be dragged onto it.
	_start_pulse_highlight(sprout_button.position + sprout_button.size * 0.5, Vector2(100, 112))


func _on_sprout_pressed() -> void:
	SoundManager.play_click()
	_spawn_seed()


func _on_seed_gui_input(event: InputEvent) -> void:
	if merge_complete:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dragging_seed = true
		seed_drag_offset = event.position
		seed_piece.move_to_front()
		_get_seed_art().z_index = 2
	elif event is InputEventScreenTouch and event.pressed:
		dragging_seed = true
		seed_drag_offset = event.position
		seed_piece.move_to_front()
		_get_seed_art().z_index = 2


func _input(event: InputEvent) -> void:
	if not dragging_seed or seed_piece == null or merge_complete:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging_seed = false
		_try_first_merge()
	elif event is InputEventScreenTouch and not event.pressed:
		dragging_seed = false
		_try_first_merge()


func _process(_delta: float) -> void:
	if not dragging_seed or seed_piece == null or merge_complete:
		return
	seed_piece.global_position = get_global_mouse_position() - seed_drag_offset
	_get_seed_art().global_position = seed_piece.global_position
	if seed_shadow:
		seed_shadow.position = seed_piece.position + Vector2(seed_piece.size.x * 0.5, seed_piece.size.y - 18.0)
	# Safety net: if a release event ever gets missed, polling here catches it too.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging_seed = false
		_try_first_merge()


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
	_stop_pulse_highlight()
	_fade_out_and_hide(hint_panel)
	if seed_shadow:
		seed_shadow.queue_free()
		seed_shadow = null
	if seed_piece:
		_get_seed_art().queue_free()
		seed_piece.queue_free()
		seed_piece = null
	if sprout_button:
		_get_sprout_art().queue_free()
		sprout_button.queue_free()
	_show_bloom_sprout()
	_show_sparkles(Vector2(540, 850), Color("#fff2a8"))
	_show_floating_text("+10 Mana", Vector2(448, 782), Color("#f3d57a"))
	_set_message("Life returns to the grove.")
	GameState.complete_onboarding_merge()
	SoundManager.play_merge()
	SoundManager.play_first_merge_moment()

	var tween := create_tween()
	tween.tween_property(color_wash, "color", Color("#4bbf78", 0.18), 0.7)
	tween.tween_interval(1.2)
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1.0), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		SoundManager.stop_moment()
		_go_to_village()
	)


func _go_to_village() -> void:
	# Keep the black overlay alive past this scene's destruction by moving it
	# to the tree root, so we can fade it back out once the village is loaded
	# instead of cutting straight from black to a fully-lit scene.
	remove_child(fade_overlay)
	get_tree().root.add_child(fade_overlay)
	fade_overlay.z_index = 4096

	var village_scene: PackedScene = load(MAIN_VILLAGE_PATH)
	var village: Node = village_scene.instantiate()
	get_tree().root.add_child(village)
	get_tree().current_scene = village

	var fade_in_tween := fade_overlay.create_tween()
	fade_in_tween.tween_interval(0.05)
	fade_in_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0.0), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_callback(fade_overlay.queue_free)

	queue_free()


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
	_fade_in_node(glow_art, 0.5)

	var flower_art := _add_sprite(
		"res://assets/sprites/abandoned_nook/bloom_flower.png",
		bloom_sprout.position,
		bloom_sprout.size
	)
	flower_art.z_index = 2
	_pop_in(flower_art, 0.4)


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


func _start_pulse_highlight(center: Vector2, radius: Vector2) -> void:
	_stop_pulse_highlight()
	highlight_ring = Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	highlight_ring.polygon = points
	highlight_ring.color = Color("#f3d57a", 0.32)
	highlight_ring.position = center
	highlight_ring.z_index = 0
	add_child(highlight_ring)

	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.tween_property(highlight_ring, "scale", Vector2(1.18, 1.18), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	highlight_tween.parallel().tween_property(highlight_ring, "modulate:a", 0.35, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	highlight_tween.tween_property(highlight_ring, "scale", Vector2(1.0, 1.0), 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	highlight_tween.parallel().tween_property(highlight_ring, "modulate:a", 1.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_pulse_highlight() -> void:
	if highlight_tween:
		highlight_tween.kill()
		highlight_tween = null
	if highlight_ring:
		highlight_ring.queue_free()
		highlight_ring = null


func _update_hint_text(new_text: String) -> void:
	var tween := create_tween()
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void:
		hint_label.text = new_text
	)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.15)


func _set_message(text: String) -> void:
	message_label.text = text
	message_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(message_panel, "modulate:a", 1.0, 0.5)


func _fade_in_node(node: CanvasItem, duration: float = 0.25) -> void:
	node.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)


func _fade_out_and_hide(node: CanvasItem, duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(func() -> void:
		node.visible = false
	)


func _pop_in(node: CanvasItem, duration: float = 0.28) -> void:
	var target_scale: Vector2 = node.scale
	node.modulate.a = 0.0
	node.scale = target_scale * 0.7
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", target_scale, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_sprite(path: String, top_left: Vector2, sprite_size: Vector2, sprite_rotation: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + sprite_size * 0.5
	sprite.rotation = sprite_rotation
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(sprite_size.x / texture.get_width(), sprite_size.y / texture.get_height())
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


func _make_message_panel(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a2418", 0.68)
	style.border_color = Color("#c9f3a8", 0.6)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("#fff2a8"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(label)
	return panel
