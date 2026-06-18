extends SceneTree

func _init() -> void:
	GameState.reset_to_defaults()
	GameState.has_seen_tutorial = true

	var village = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)

	village._open_sacred_pond()
	if village.open_panel == null or village.open_panel.name != "SacredPondPanel":
		fail("Sacred Pond should open before nav test")
	_press_button(village, "Quests")
	if village.open_panel == null or village.open_panel.name != "QuestPanel":
		fail("Quests should close Sacred Pond and open QuestPanel")

	village._open_flower_grove()
	if village.open_panel == null or village.open_panel.name != "FlowerGrovePanel":
		fail("Flower Grove should open before nav test")
	_press_button(village, "Settings")
	if village.open_panel == null or village.open_panel.name != "SettingsPanel":
		fail("Settings should close Flower Grove and open SettingsPanel")

	village._open_fairy_house()
	if village.open_panel == null or village.open_panel.name != "FairyHousePanel":
		fail("Fairy House should open before nav test")
	_press_button(village, "Map")
	if village.open_panel != null:
		fail("Map should close Fairy House and return to village")

	village._open_potion_shop()
	if village.open_panel == null or village.open_panel.name != "PotionShopPanel":
		fail("Potion Shop should open before nav test")
	_press_button(village, "Buildings")
	if village.open_panel == null or village.open_panel.name != "BuildingsPanel":
		fail("Buildings should close Potion Shop and open BuildingsPanel")

	_press_button(village, "Explore")
	if village.open_panel == null or village.open_panel.name != "ExplorePanel":
		fail("Explore should open ExplorePanel")

	_press_button(village, "Buildings")
	if village.open_panel == null or village.open_panel.name != "BuildingsPanel":
		fail("Buildings should open BuildingsPanel")

	_press_button(village.open_panel, "Open")
	if village.open_panel == null or village.open_panel.name != "FlowerGrovePanel":
		fail("First Buildings Open button should open FlowerGrovePanel")

	_press_button(village, "Settings")
	if village.open_panel == null or village.open_panel.name != "SettingsPanel":
		fail("Settings should open SettingsPanel")

	_press_button(village, "Map")
	if village.open_panel != null:
		fail("Map should close the open panel")

	print("Bottom navigation behavior check passed")
	quit(0)


func _press_button(root_node: Node, text: String) -> void:
	var button := _find_button(root_node, text)
	if button == null:
		fail("Missing button: %s" % text)
	button.pressed.emit()


func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
