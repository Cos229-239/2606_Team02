extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.quests.size() != 9:
		fail("Expected nine guided quests")
	if state.has_claimable_quest_rewards():
		fail("No quests should be claimable at start")
	if state.get_next_guided_quest_id() != "first_harvest":
		fail("First Harvest should be the first visible quest")

	state.flower_grove_stored_mana = 50.0
	if state.collect_flower_mana() != 50:
		fail("Expected to collect 50 mana")
	if not state.is_quest_completed("first_harvest"):
		fail("First Harvest should complete after collecting 50 mana")
	if not state.claim_quest_reward("first_harvest"):
		fail("First Harvest reward should be claimable")
	if state.total_coins != 25:
		fail("First Harvest should reward 25 coins")

	state.record_building_visit("Fairy House")
	if not state.is_quest_completed("visit_fairy_house"):
		fail("Meet the Fairies should complete after visiting Fairy House")
	if not state.claim_quest_reward("visit_fairy_house"):
		fail("Meet the Fairies reward should be claimable")

	state.assign_fairy_to_area("Nim", "Flower Grove")
	if not state.is_quest_completed("fairy_work"):
		fail("A Fairy's Work should complete after assigning a fairy to Flower Grove")
	if not state.claim_quest_reward("fairy_work"):
		fail("A Fairy's Work reward should be claimable")

	state.total_mana = 25
	if not state.restore_sacred_pond():
		fail("Pond restore should succeed")
	if not state.is_quest_completed("restore_waters"):
		fail("Restore the Waters should complete after one restore")
	if not state.claim_quest_reward("restore_waters"):
		fail("Restore the Waters reward should be claimable")
	if state.total_mana != 25:
		fail("Restore the Waters should reward 25 mana after spending 25")

	state.total_mana = 25
	if not state.start_mana_potion_craft():
		fail("Potion craft should start")
	state.update_potion_crafting(5.1)
	if not state.is_quest_completed("beginner_brewer"):
		fail("Beginner Brewer should complete after crafting one potion")
	if not state.claim_quest_reward("beginner_brewer"):
		fail("Beginner Brewer reward should be claimable")

	state.record_building_visit("Market Stall")
	if not state.is_quest_completed("visit_market_stall"):
		fail("Open the Market should complete after visiting Market Stall")
	if not state.claim_quest_reward("visit_market_stall"):
		fail("Open the Market reward should be claimable")

	state.total_mana = state.get_flower_upgrade_cost()
	if not state.upgrade_flower_grove():
		fail("Flower Grove upgrade should succeed")
	if not state.is_quest_completed("village_growth"):
		fail("Village Growth should complete after upgrading Flower Grove")
	if not state.claim_quest_reward("village_growth"):
		fail("Village Growth reward should be claimable")

	state.record_building_visit("Arcane Forge")
	if not state.is_quest_completed("visit_arcane_forge"):
		fail("Arcane Tools should complete after visiting Arcane Forge")
	if not state.claim_quest_reward("visit_arcane_forge"):
		fail("Arcane Tools reward should be claimable")

	state.record_building_visit("Ancient Tree")
	if not state.is_quest_completed("visit_ancient_tree"):
		fail("Heart of the Grove should complete after visiting Ancient Tree")

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
