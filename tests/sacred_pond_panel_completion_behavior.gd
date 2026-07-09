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
	game_state.sacred_pond_water_purity = 100
	game_state.update_sacred_pond_level_and_rewards()

	var panel: Node = load("res://ui/SacredPondPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	if _find_button(panel, "UpgradesButton") != null:
		fail("Sacred Pond should not expose unfinished upgrade action")
		return

	var stats := panel.get_node_or_null("Root/StatsLabel") as Label
	if stats == null or not stats.text.contains("Fully Restored"):
		fail("Sacred Pond panel should show fully restored status")
		return
	if panel.get_node_or_null("Root/PondStatusCards") == null:
		fail("Sacred Pond panel should build polished status cards")
		return
	if panel.get_node_or_null("Root/PondStatusCards/PurityProgress") == null:
		fail("Sacred Pond panel should show water purity progress")
		return

	var restore_button := _find_button(panel, "RestoreButton")
	if restore_button == null:
		fail("Sacred Pond restore button should exist")
		return
	var mana_before: int = game_state.total_mana
	restore_button.pressed.emit()
	await process_frame
	if game_state.total_mana != mana_before:
		fail("Full pond restore button should not spend Mana")
		return
	var feedback := panel.get_node_or_null("Root/FeedbackLabel") as Label
	if feedback == null or not feedback.text.contains("fully restored"):
		fail("Full pond restore button should explain the complete state")
		return

	panel.queue_free()
	await process_frame
	print("Sacred Pond panel completion behavior check passed")
	quit(0)


func _find_button(node: Node, button_name: String) -> BaseButton:
	if node is BaseButton and String(node.name) == button_name:
		return node
	for child in node.get_children():
		var found := _find_button(child, button_name)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
