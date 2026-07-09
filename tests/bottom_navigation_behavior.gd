extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	game_state.has_seen_tutorial = true

	var village = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame

	village._open_sacred_pond()
	if village.open_panel == null or village.open_panel.name != "SacredPondPanel":
		fail("Sacred Pond should open before nav test")
	if not _press_button(village, "QuestsNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "QuestPanel":
		fail("Quests should close Sacred Pond and open QuestPanel")

	village._open_flower_grove()
	if village.open_panel == null or village.open_panel.name != "FlowerGrovePanel":
		fail("Flower Grove should open before nav test")
	if not _press_button(village, "SettingsNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "SettingsPanel":
		fail("Settings should close Flower Grove and open SettingsPanel")

	village._open_fairy_house()
	if village.open_panel == null or village.open_panel.name != "FairyHousePanel":
		fail("Fairy House should open before nav test")
	if not _press_button(village, "MapNavButton"):
		return
	await process_frame
	if village.open_panel != null:
		fail("Map should close Fairy House and return to village")

	village._open_potion_shop()
	if village.open_panel == null or village.open_panel.name != "PotionShopPanel":
		fail("Potion Shop should open before nav test")
	if not _press_button(village, "BuildingsNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "BuildingsPanel":
		fail("Buildings should close Potion Shop and open BuildingsPanel")

	if not _press_button(village, "ExploreNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "ExplorePanel":
		fail("Explore should open ExplorePanel")

	if not _press_button(village, "BuildingsNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "BuildingsPanel":
		fail("Buildings should open BuildingsPanel")

	if not _press_button(village.open_panel, "Open"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "FlowerGrovePanel":
		fail("First Buildings Open button should open FlowerGrovePanel")

	if not _press_button(village, "SettingsNavButton"):
		return
	await process_frame
	if village.open_panel == null or village.open_panel.name != "SettingsPanel":
		fail("Settings should open SettingsPanel")

	if not _press_button(village, "MapNavButton"):
		return
	await process_frame
	if village.open_panel != null:
		fail("Map should close the open panel")

	print("Bottom navigation behavior check passed")
	village.queue_free()
	quit(0)


func _press_button(root_node: Node, identifier: String) -> bool:
	var button := _find_button(root_node, identifier)
	if button == null:
		fail("Missing button: %s" % identifier)
		return false
	button.pressed.emit()
	return true


func _find_button(node: Node, identifier: String) -> BaseButton:
	if node is BaseButton and (String(node.name) == identifier or (node is Button and node.text == identifier)):
		return node
	for child in node.get_children():
		var found := _find_button(child, identifier)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
