extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return

	game_state.reset_to_defaults()
	game_state.total_mana = 125
	game_state.total_coins = 80
	game_state.mana_potion_count = 2
	game_state.sacred_pond_spirit_energy = 12
	game_state.add_potion_ingredient(game_state.POTION_INGREDIENT_MANA_CRYSTAL, 3)
	game_state.inventory_notes.clear()
	game_state.inventory_notes.append("Found market ledger")

	var items: Array[Dictionary] = game_state.get_inventory_items()
	if items.size() < 6:
		fail("Inventory should expose resource, crafted, companion, and decor entries")
		return
	if not _has_item(items, "Mana", 125):
		fail("Inventory should include current Mana")
		return
	if not _has_item(items, "Coins", 80):
		fail("Inventory should include current Coins")
		return
	if not _has_item(items, "Mana Potion", 2):
		fail("Inventory should include crafted Mana Potions")
		return
	if not _has_item(items, "Mana Crystal", 3):
		fail("Inventory should include potion ingredients")
		return
	game_state.potion_inventory["spirit_tonic"] = 1
	if not _has_item(game_state.get_inventory_items(), "Spirit Tonic", 1):
		fail("Inventory should include crafted Spirit Tonics")
		return
	if not _has_item(items, "Spirit Energy", 12):
		fail("Inventory should include Spirit Energy")
		return
	if not _has_item(items, "Sun Koi Guardian Bonus", 0):
		fail("Inventory should show inactive Sun Koi Guardian bonus")
		return

	game_state.sacred_pond_water_purity = 100
	game_state.update_sacred_pond_level_and_rewards()
	if not _has_item(game_state.get_inventory_items(), "Sun Koi Guardian Bonus", 1):
		fail("Inventory should show active Sun Koi Guardian bonus")
		return

	var data: Dictionary = game_state.get_save_data()
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if not loaded_state.inventory_notes.has("Found market ledger"):
		fail("Inventory notes should persist through save data")
		return
	if not _has_item(loaded_state.get_inventory_items(), "Mana Potion", 2):
		fail("Loaded inventory should preserve potion count")
		return

	var panel: Control = load("res://ui/InventoryPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame
	if panel.get_child_count() <= 0:
		fail("Inventory panel should build visible UI children")
		return
	if not panel.has_signal("closed"):
		fail("Inventory panel should expose closed signal")
		return
	panel.queue_free()

	var village: Control = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame
	var inventory_button := _find_button(village, "InventoryButton")
	if inventory_button == null:
		fail("Main Village should expose an Inventory button")
		return
	inventory_button.pressed.emit()
	await process_frame
	if village.open_panel == null or village.open_panel.name != "InventoryPanel":
		fail("Inventory button should open InventoryPanel")
		return

	print("Inventory behavior check passed")
	quit(0)


func _has_item(items: Array[Dictionary], item_name: String, quantity: int) -> bool:
	for item in items:
		if String(item.get("Name", "")) == item_name and int(item.get("Quantity", -1)) == quantity:
			return true
	return false


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
