extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()

	await _verify_fairy_house_tabs()
	await _verify_potion_upgrade_confirmation()

	print("Panel interaction polish behavior check passed")
	quit(0)


func _verify_fairy_house_tabs() -> void:
	var panel: Node = load("res://ui/FairyHousePanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	if not _press_button(panel, "TasksButton"):
		return
	await process_frame
	var title := panel.get_node_or_null("Root/WorkersTitle") as Label
	if title == null or title.text != "Fairy Tasks":
		fail("Fairy House Tasks tab should show task summary content")
		return

	if not _press_button(panel, "UpgradeHouseButton"):
		return
	await process_frame
	if title.text != "House Upgrades":
		fail("Fairy House Upgrades tab should show upgrade summary content")
		return

	panel.queue_free()


func _verify_potion_upgrade_confirmation() -> void:
	var game_state := root.get_node("GameState")
	game_state.total_coins = game_state.potion_shop_upgrade_cost
	var starting_coins: int = game_state.total_coins
	var starting_level: int = game_state.potion_shop_level

	var panel: Node = load("res://ui/PotionShopPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	if not _press_button(panel, "UpgradeShopButton"):
		return
	await process_frame
	if game_state.total_coins != starting_coins:
		fail("First Potion Shop upgrade tap should not spend Coins")
		return
	if game_state.potion_shop_level != starting_level:
		fail("First Potion Shop upgrade tap should not increase level")
		return
	var feedback := panel.get_node_or_null("Root/FeedbackLabel") as Label
	if feedback == null or not feedback.text.contains("confirm"):
		fail("First Potion Shop upgrade tap should ask for confirmation")
		return

	if not _press_button(panel, "UpgradeShopButton"):
		return
	await process_frame
	if game_state.potion_shop_level != starting_level + 1:
		fail("Second Potion Shop upgrade tap should confirm the upgrade")
		return
	if game_state.total_coins != 0:
		fail("Confirmed Potion Shop upgrade should spend Coins")
		return

	panel.queue_free()


func _press_button(node: Node, button_name: String) -> bool:
	var button := _find_button(node, button_name)
	if button == null:
		fail("Missing button: %s" % button_name)
		return false
	button.pressed.emit()
	return true


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
