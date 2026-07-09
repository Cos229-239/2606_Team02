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
	if tray.position.y < 1320.0:
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

	var first_card := row.get_child(0) as Control
	if first_card == null:
		fail("Decoration choices should be visible cards")
		return
	if first_card.custom_minimum_size.x < 110.0 or first_card.custom_minimum_size.y < 300.0:
		fail("Decoration choices should be tall inventory cards")
		return
	if first_card.custom_minimum_size.x > 130.0:
		fail("Decoration cards should be compact enough to show a full bottom strip")
		return
	var visible_card_width := first_card.custom_minimum_size.x * 8.0 + float(row.get_theme_constant("separation")) * 7.0
	if visible_card_width > row.size.x:
		fail("Decoration tray should fit eight visible cards like the reference strip")
		return
	var name_label := first_card.get_node_or_null("Frame/StatLayoutMargin/Name") as Label
	if name_label == null:
		name_label = first_card.find_child("Name", true, false) as Label
	if name_label == null or not name_label.text.contains("\n"):
		fail("Decoration names should stack cleanly on narrow cards")
		return
	var art := first_card.find_child("Art", true, false) as TextureRect
	if art == null or art.custom_minimum_size.x < 100.0 or art.custom_minimum_size.y < 110.0:
		fail("Decoration cards should reserve a large art area")
		return
	var click_target := first_card.get_node_or_null("ClickTarget") as Button
	if click_target == null:
		fail("Decoration cards should have a full-card click target")
		return
	var cost := first_card.find_child("Cost", true, false) as Label
	var beauty := first_card.find_child("Beauty", true, false) as Label
	if cost == null or beauty == null:
		fail("Decoration choices should clearly show cost and beauty")
		return
	var clear_button := panel.get_node_or_null("Root/ActionRow/PlaceButton") as Button
	if clear_button == null or clear_button.text != "Clear Selection":
		fail("Bottom action row should use reference-style text buttons")
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
