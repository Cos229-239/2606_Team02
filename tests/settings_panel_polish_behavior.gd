extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()

	var panel: Node = load("res://ui/SettingsPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	_verify_volume_controls(panel, game_state)
	await process_frame
	_verify_reset_confirmation(panel, game_state)
	await process_frame

	panel.queue_free()
	print("Settings panel polish behavior check passed")
	quit(0)


func _verify_volume_controls(panel: Node, game_state: Node) -> void:
	var music_value := _find_label(panel, "MusicVolumeValueLabel")
	if music_value == null or music_value.text != "75%":
		fail("Settings should show current Music volume percent")
		return

	if not _press_button(panel, "MusicVolumeMuteButton"):
		return
	await process_frame
	if game_state.music_volume != 0.0:
		fail("Music mute button should set Music volume to 0")
		return
	if music_value.text != "0%":
		fail("Music volume percent should update after muting")
		return

	if not _press_button(panel, "MusicVolumeMuteButton"):
		return
	await process_frame
	if game_state.music_volume <= 0.0:
		fail("Music mute button should unmute when already muted")
		return


func _verify_reset_confirmation(panel: Node, game_state: Node) -> void:
	game_state.total_mana = 1234
	var overlay := panel.get_node_or_null("ResetConfirmationOverlay") as Control
	if overlay == null:
		fail("Settings should include a reset confirmation overlay")
		return
	if overlay.visible:
		fail("Reset confirmation overlay should start hidden")
		return

	if not _press_button(panel, "Reset Save"):
		return
	await process_frame
	if not overlay.visible:
		fail("Reset Save should show confirmation overlay")
		return
	if game_state.total_mana != 1234:
		fail("Opening reset confirmation should not reset progress")
		return

	if not _press_button(panel, "CancelResetButton"):
		return
	await process_frame
	if overlay.visible:
		fail("Cancel should hide reset confirmation overlay")
		return
	if game_state.total_mana != 1234:
		fail("Cancel should preserve progress")
		return

	if not _press_button(panel, "Reset Save"):
		return
	await process_frame
	if not _press_button(panel, "ConfirmResetButton"):
		return
	await process_frame
	if overlay.visible:
		fail("Confirm should hide reset confirmation overlay")
		return
	if game_state.total_mana == 1234:
		fail("Confirm should reset progress")
		return
	if not game_state.show_tutorial_after_reset:
		fail("Confirm reset should restart the tutorial flow")
		return


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


func _find_label(node: Node, label_name: String) -> Label:
	if node is Label and String(node.name) == label_name:
		return node
	for child in node.get_children():
		var found := _find_label(child, label_name)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
