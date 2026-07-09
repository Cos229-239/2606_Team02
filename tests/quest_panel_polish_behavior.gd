extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	_make_quest_claimable(game_state, "first_harvest")

	var panel: Node = load("res://ui/QuestPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	var summary := _find_label(panel, "QuestSummaryLabel")
	if summary == null or summary.text != "1 ready to claim - 7 in progress":
		fail("Quest panel should summarize claimable and in-progress quests")
		return

	var first_card := _first_quest_card(panel)
	if first_card == null or String(first_card.name) != "QuestCard_first_harvest":
		fail("Claimable quest should be sorted to the top")
		return

	var ready_status := _find_label(first_card, "QuestStatus_Ready")
	if ready_status == null or ready_status.text != "Ready":
		fail("Claimable quest should show a Ready status")
		return

	var claim_button := _find_button(first_card, "ClaimButton_first_harvest")
	if claim_button == null or claim_button.disabled or claim_button.text != "Claim Reward":
		fail("Claimable quest should have an enabled Claim Reward button")
		return

	var in_progress_card := _find_node(panel, "QuestCard_awaken_roots")
	if in_progress_card == null:
		fail("In-progress quest card should remain visible")
		return
	var keep_going := _find_button(in_progress_card, "ClaimButton_awaken_roots")
	if keep_going == null or not keep_going.disabled or keep_going.text != "Keep Going":
		fail("In-progress quest should show a disabled Keep Going button")
		return

	claim_button.pressed.emit()
	await process_frame
	if _find_node(panel, "QuestCard_first_harvest") != null:
		fail("Claimed quest should disappear from the active quest list")
		return
	if summary.text != "0 ready to claim - 7 in progress":
		fail("Quest summary should refresh after claiming a reward")
		return

	panel.queue_free()
	print("Quest panel polish behavior check passed")
	quit(0)


func _make_quest_claimable(game_state: Node, quest_id: String) -> void:
	for index in range(game_state.quests.size()):
		if String(game_state.quests[index].get("QuestID", "")) == quest_id:
			var required := int(game_state.quests[index].get("RequiredProgress", 1))
			game_state.quests[index]["CurrentProgress"] = required
			game_state.quests[index]["IsCompleted"] = true
			return
	fail("Missing quest fixture: %s" % quest_id)


func _first_quest_card(node: Node) -> Node:
	var quest_scroll := _find_node(node, "QuestScrollContainer")
	if quest_scroll == null:
		return null
	for child in quest_scroll.get_children():
		for card in child.get_children():
			if String(card.name).begins_with("QuestCard_"):
				return card
	return null


func _find_node(node: Node, node_name: String) -> Node:
	if String(node.name) == node_name:
		return node
	for child in node.get_children():
		var found := _find_node(child, node_name)
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
