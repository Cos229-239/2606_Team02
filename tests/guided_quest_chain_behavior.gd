extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if not state.has_method("get_visible_quests"):
		fail("GameState should expose visible guided quests")
	if not state.has_method("get_next_guided_quest_id"):
		fail("GameState should expose the next guided quest")
	if not state.has_method("record_building_visit"):
		fail("GameState should record building visits for guided quests")
	if not state.has_method("is_quest_unlocked"):
		fail("GameState should expose guided quest unlock state")

	assert_visible_quest_ids(state, ["first_harvest"])
	if state.get_next_guided_quest_id() != "first_harvest":
		fail("First Harvest should be the first guided quest")

	state.flower_grove_stored_mana = 50.0
	state.collect_flower_mana()
	if not state.is_quest_completed("first_harvest"):
		fail("First Harvest should complete after collecting mana")
	if not state.claim_quest_reward("first_harvest"):
		fail("First Harvest reward should be claimable")
	assert_visible_quest_ids(state, ["visit_fairy_house"])

	state.record_building_visit("Fairy House")
	if not state.is_quest_completed("visit_fairy_house"):
		fail("Fairy House visit quest should complete when opening Fairy House")
	state.claim_quest_reward("visit_fairy_house")
	assert_visible_quest_ids(state, ["fairy_work"])

	state.assign_fairy_to_area("Nim", "Flower Grove")
	if not state.is_quest_completed("fairy_work"):
		fail("A Fairy's Work should complete after assigning a fairy to Flower Grove")
	state.claim_quest_reward("fairy_work")
	assert_visible_quest_ids(state, ["restore_waters"])

	state.total_mana = max(state.total_mana, state.sacred_pond_restore_cost)
	state.restore_sacred_pond()
	state.claim_quest_reward("restore_waters")
	assert_visible_quest_ids(state, ["beginner_brewer"])

	state.total_mana = max(state.total_mana, state.potion_mana_cost)
	state.start_mana_potion_craft()
	state.update_potion_crafting(5.1)
	state.claim_quest_reward("beginner_brewer")
	assert_visible_quest_ids(state, ["visit_market_stall"])

	state.record_building_visit("Market Stall")
	state.claim_quest_reward("visit_market_stall")
	assert_visible_quest_ids(state, ["village_growth"])

	state.total_mana = max(state.total_mana, state.get_flower_upgrade_cost())
	state.upgrade_flower_grove()
	state.claim_quest_reward("village_growth")
	assert_visible_quest_ids(state, ["visit_arcane_forge"])

	state.record_building_visit("Arcane Forge")
	state.claim_quest_reward("visit_arcane_forge")
	assert_visible_quest_ids(state, ["visit_ancient_tree"])

	state.record_building_visit("Ancient Tree")
	if not state.is_quest_completed("visit_ancient_tree"):
		fail("Ancient Tree visit quest should complete when opening Ancient Tree")

	var data: Dictionary = state.get_save_data()
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if not loaded_state.is_quest_unlocked("visit_ancient_tree"):
		fail("Guided quest unlock state should persist")

	print("Guided quest chain behavior check passed")
	quit(0)


func assert_visible_quest_ids(state: Node, expected_ids: Array[String]) -> void:
	var visible_quests: Array = state.get_visible_quests()
	if visible_quests.size() != expected_ids.size():
		fail("Expected %d visible quests, found %d" % [expected_ids.size(), visible_quests.size()])
	for index in range(expected_ids.size()):
		var quest_id := String(visible_quests[index].get("QuestID", ""))
		if quest_id != expected_ids[index]:
			fail("Expected visible quest %s at index %d, found %s" % [expected_ids[index], index, quest_id])


func fail(message: String) -> void:
	push_error(message)
	quit(1)
