extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()

	var menu: Node = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame

	game_state.total_mana = 1234
	var overlay := menu.get_node_or_null("ResetConfirmationOverlay") as Control
	if overlay == null:
		fail("Main Menu should include a reset confirmation overlay")
		return
	if overlay.visible:
		fail("Main Menu reset confirmation should start hidden")
		return

	if not _press_button(menu, "Reset Save"):
		return
	await process_frame
	if not overlay.visible:
		fail("Main Menu Reset Save should show confirmation overlay")
		return
	if game_state.total_mana != 1234:
		fail("Opening Main Menu reset confirmation should not reset progress")
		return

	if not _press_button(menu, "CancelResetButton"):
		return
	await process_frame
	if overlay.visible:
		fail("Main Menu reset cancel should hide overlay")
		return
	if game_state.total_mana != 1234:
		fail("Main Menu reset cancel should preserve progress")
		return

	if not _press_button(menu, "Reset Save"):
		return
	await process_frame
	if not _press_button(menu, "ConfirmResetButton"):
		return
	await process_frame
	if overlay.visible:
		fail("Main Menu reset confirm should hide overlay")
		return
	if game_state.total_mana == 1234:
		fail("Main Menu reset confirm should reset progress")
		return
	if not game_state.show_tutorial_after_reset:
		fail("Main Menu reset confirm should restart the tutorial flow")
		return

	menu.queue_free()
	print("Main Menu reset confirmation behavior check passed")
	quit(0)


func _press_button(node: Node, button_name: String) -> bool:
	var button := _find_button(node, button_name)
	if button == null:
		fail("Missing button: %s" % button_name)
		return false
	button.pressed.emit()
	return true


func _find_button(node: Node, button_name: String) -> BaseButton:
	if node is BaseButton and (String(node.name) == button_name or (node as BaseButton).text == button_name):
		return node
	for child in node.get_children():
		var found := _find_button(child, button_name)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
