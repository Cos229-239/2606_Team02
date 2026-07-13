extends SceneTree

var failed_any := false


func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	_assert_quest_exists(state, "first_trade", "market_trade")
	_assert_quest_exists(state, "awaken_roots", "restore_tree")
	_assert_quest_exists(state, "first_forging", "forge_upgrade")

	state.total_mana = 500
	state.total_coins = 500
	state.sacred_pond_spirit_energy = 60
	state.mana_potion_count = 2

	state.fulfill_market_order("mana_bundle")
	if not state.is_quest_completed("first_trade"):
		fail("First trade quest should complete after fulfilling a market order")

	state.restore_ancient_tree()
	if not state.is_quest_completed("awaken_roots"):
		fail("Awaken Roots quest should complete after restoring Ancient Tree")

	state.purchase_forge_upgrade("flower_focus")
	if not state.is_quest_completed("first_forging"):
		fail("First forging quest should complete after buying a forge upgrade")

	if failed_any:
		quit(1)
		return
	print("Building quest hook behavior check passed")
	quit(0)


func _assert_quest_exists(state: Node, quest_id: String, goal_type: String) -> void:
	for quest in state.quests:
		if String(quest.get("QuestID", "")) == quest_id:
			if String(quest.get("QuestGoalType", "")) != goal_type:
				fail("%s should use goal %s" % [quest_id, goal_type])
			return
	fail("Missing quest: %s" % quest_id)


func fail(message: String) -> void:
	failed_any = true
	push_error(message)
