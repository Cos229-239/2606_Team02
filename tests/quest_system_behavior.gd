extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.quests.size() != 8:
		fail("Expected eight starting quests")
	if state.has_claimable_quest_rewards():
		fail("No quests should be claimable at start")

	state.flower_grove_stored_mana = 50.0
	if state.collect_flower_mana() != 50:
		fail("Expected to collect 50 mana")
	if not state.is_quest_completed("first_harvest"):
		fail("First Harvest should complete after collecting 50 mana")
	if not state.claim_quest_reward("first_harvest"):
		fail("First Harvest reward should be claimable")
	if state.total_coins != 25:
		fail("First Harvest should reward 25 coins")

	state.total_mana = 25
	if not state.restore_sacred_pond():
		fail("Pond restore should succeed")
	if not state.is_quest_completed("restore_waters"):
		fail("Restore the Waters should complete after one restore")
	if not state.claim_quest_reward("restore_waters"):
		fail("Restore the Waters reward should be claimable")
	if state.total_mana != 25:
		fail("Restore the Waters should reward 25 mana after spending 25")

	state.assign_fairy_to_area("Nim", "Flower Grove")
	if not state.is_quest_completed("fairy_work"):
		fail("A Fairy's Work should complete after assigning a fairy to Flower Grove")

	state.total_mana = 25
	state.add_potion_ingredient(state.POTION_INGREDIENT_MANA_CRYSTAL, 1)
	state.add_potion_ingredient(state.POTION_INGREDIENT_EMPTY_VIAL, 1)
	if not state.start_mana_potion_craft():
		fail("Potion craft should start")
	state.update_potion_crafting(5.1)
	if not state.is_quest_completed("beginner_brewer"):
		fail("Beginner Brewer should complete after crafting one potion")

	state.total_mana = state.get_flower_upgrade_cost()
	if not state.upgrade_flower_grove():
		fail("Flower Grove upgrade should succeed")
	if not state.is_quest_completed("village_growth"):
		fail("Village Growth should complete after upgrading Flower Grove")

	var data: Dictionary = state.get_save_data()
	if not data.has("quests"):
		fail("Save data should include quests")
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if not loaded_state.is_quest_completed("village_growth"):
		fail("Loaded quest completion should persist")
	if not loaded_state.is_quest_claimed("first_harvest"):
		fail("Loaded claimed quest should persist")

	print("Quest system behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
