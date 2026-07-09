extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	game_state.total_mana = 999

	var panel: Node = load("res://ui/PondDecoratePanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	var pond_layer := panel.get_node_or_null("Root/PondLayer") as Control
	if pond_layer == null:
		fail("Decorate screen should expose the editable pond layer")
		return
	if pond_layer.position != Vector2.ZERO:
		fail("Pond layer should start at the top-left so the whole pond can be decorated")
		return
	if pond_layer.size.x < 1080.0 or pond_layer.size.y < 1920.0:
		fail("Pond layer should cover the full design canvas")
		return

	var tray := panel.get_node_or_null("Root/DecorationTray") as Control
	if tray == null:
		fail("Decorate screen should expose the decoration tray")
		return
	if tray.position.y < 1180.0:
		fail("Decoration tray should sit low enough to keep the pond visible")
		return
	if tray.position.y <= GameState.POND_DECORATION_EDITOR_RECT.end.y:
		fail("Decoration tray should not cover the editable pond area")
		return

	var row := _find_node(panel, "DecorationRow") as HBoxContainer
	if row == null:
		fail("Decoration tray should contain a decoration row")
		return
	if row.get_child_count() < 4:
		fail("Decoration row should show available decoration choices")
		return

	var first_card := row.get_child(0) as Button
	if first_card == null:
		fail("Decoration choices should be visible buttons")
		return
	if first_card.custom_minimum_size.x < 110.0 or first_card.custom_minimum_size.y < 330.0:
		fail("Decoration choices should be tall inventory cards")
		return
	if first_card.custom_minimum_size.x > 130.0:
		fail("Decoration cards should be compact enough to show a full bottom strip")
		return
	if first_card.get_theme_constant("icon_max_width") < 100:
		fail("Decoration choices should reserve a large icon area")
		return
	var visible_card_width := first_card.custom_minimum_size.x * 8.0 + float(row.get_theme_constant("separation")) * 7.0
	if visible_card_width > row.size.x:
		fail("Decoration tray should fit eight visible cards like the reference strip")
		return
	if not first_card.text.contains("\n"):
		fail("Decoration names should stack cleanly on narrow cards")
		return
	if not first_card.text.contains("Cost") or not first_card.text.contains("Beauty"):
		fail("Decoration choices should clearly show cost and beauty")
		return

	panel.queue_free()
	await process_frame
	print("Pond decorate visual behavior check passed")
	quit(0)


func _find_node(node: Node, wanted_name: String) -> Node:
	if String(node.name) == wanted_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, wanted_name)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
