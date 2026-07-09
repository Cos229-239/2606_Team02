extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.fairies.size() != 3:
		fail("Expected Luna, Pip, and Nim to exist")
	if int(state.get_flower_fairy_bonus_production()) != 2:
		fail("Expected Luna to add +2 mana/sec by default")
	if int(state.get_flower_production_rate()) != 7:
		fail("Expected Flower Grove total production to start at 7")
	if state.get_sacred_pond_fairy_restore_bonus() != 1:
		fail("Expected Pip to add +1 restore purity by default")
	if state.get_sacred_pond_total_restore_amount() != 6:
		fail("Expected total restore amount to start at 6")
	if state.fairy_workers_active != 2:
		fail("Expected Luna and Pip to count as active workers")
	if state.get_fairy_task_cards().size() != 3:
		fail("Expected Fairy House to expose mana, ingredient, and pond task cards")
	var task_cards: Array[Dictionary] = state.get_fairy_task_cards()
	for task in task_cards:
		if String(task.get("TaskRateText", "")) == "":
			fail("Fairy task cards should expose visible task rate text")

	state.update_fairy_tasks(30.0)
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_FLOWER_GROVE) != 1:
		fail("Luna should complete one Flower Grove fairy task after 30 seconds")
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_SACRED_POND) != 0:
		fail("Pip should need more time before a Sacred Pond fairy task is ready")

	var mana_reward: Dictionary = state.collect_fairy_task_reward(state.FAIRY_TASK_FLOWER_GROVE)
	if not bool(mana_reward.get("Success", false)):
		fail("Flower Grove fairy task reward should be collectable")
	if state.total_mana != 25:
		fail("Flower Grove fairy task should award 25 Mana with one assigned fairy")
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_FLOWER_GROVE) != 0:
		fail("Collecting Flower Grove fairy task should consume one ready reward")

	state.update_fairy_tasks(30.0)
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_SACRED_POND) != 1:
		fail("Pip should complete one Sacred Pond fairy task after 60 total seconds")
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_FORAGE_INGREDIENTS) != 1:
		fail("Luna should complete one ingredient forage after 60 seconds")
	var pond_reward: Dictionary = state.collect_fairy_task_reward(state.FAIRY_TASK_SACRED_POND)
	if not bool(pond_reward.get("Success", false)):
		fail("Sacred Pond fairy task reward should be collectable")
	if state.sacred_pond_spirit_energy != 1:
		fail("Sacred Pond fairy task should award Spirit Energy")
	var ingredient_reward: Dictionary = state.collect_fairy_task_reward(state.FAIRY_TASK_FORAGE_INGREDIENTS)
	if not bool(ingredient_reward.get("Success", false)):
		fail("Ingredient fairy task reward should be collectable")
	var luna_after_tasks: Dictionary = state.get_fairy_data("Luna")
	if int(luna_after_tasks.get("FairyXP", 0)) != 2:
		fail("Luna should gain XP from completed mana and ingredient tasks")
	if state.get_potion_ingredient_count(state.POTION_INGREDIENT_MANA_CRYSTAL) != 1:
		fail("Ingredient forage should add Mana Crystal")
	if state.get_potion_ingredient_count(state.POTION_INGREDIENT_DREAMBLOOM) != 2:
		fail("Ingredient forage should add Dreambloom")
	if state.get_potion_ingredient_count(state.POTION_INGREDIENT_EMPTY_VIAL) != 1:
		fail("Ingredient forage should add Empty Vial")

	var nim_message: String = state.assign_fairy_to_area("Nim", "Flower Grove")
	if nim_message != "Nim assigned to Flower Grove":
		fail("Expected Nim assignment feedback")
	if int(state.get_flower_fairy_bonus_production()) != 3:
		fail("Expected Luna and Nim to add +3 mana/sec")
	if int(state.get_flower_production_rate()) != 8:
		fail("Expected total production to update to 8")
	if state.fairy_workers_active != 3:
		fail("Expected all fairies to count as active workers")

	var luna_message: String = state.assign_fairy_to_area("Luna", "Sacred Koi Pond")
	if luna_message != "Luna assigned to Sacred Pond":
		fail("Expected Luna pond assignment feedback")
	if int(state.get_flower_fairy_bonus_production()) != 1:
		fail("Expected only Nim to boost Flower Grove")
	if state.get_sacred_pond_fairy_restore_bonus() != 3:
		fail("Expected Pip and Luna to boost Sacred Pond restore")
	if state.get_sacred_pond_total_restore_amount() != 8:
		fail("Expected total restore amount to update to 8")

	state.total_mana = 25
	var old_purity: int = state.sacred_pond_water_purity
	if not state.restore_sacred_pond():
		fail("Restore should succeed with enough mana")
	if state.sacred_pond_water_purity != old_purity + 8:
		fail("Restore should include fairy pond bonus")

	var rest_message: String = state.assign_fairy_to_area("Nim", "Unassigned")
	if rest_message != "Nim is resting":
		fail("Expected resting feedback")
	if int(state.get_flower_fairy_bonus_production()) != 0:
		fail("Expected no Flower Grove bonus after Luna and Nim leave")

	var data: Dictionary = state.get_save_data()
	if not data.has("fairies"):
		fail("Save data should include fairies")
	if not data.has("fairy_task_progress") or not data.has("fairy_task_ready_counts"):
		fail("Save data should include fairy task state")
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.get_fairy_assigned_area("Luna") != "Sacred Koi Pond":
		fail("Luna assignment should survive load")
	if int(loaded_state.get_flower_fairy_bonus_production()) != 0:
		fail("Loaded Flower Grove bonus should be recalculated")
	if loaded_state.get_sacred_pond_fairy_restore_bonus() != 3:
		fail("Loaded Sacred Pond bonus should be recalculated")

	var level_message: String = loaded_state.assign_fairy_to_area("Nim", "Flower Grove")
	if level_message != "Nim assigned to Flower Grove":
		fail("Expected Nim to be assignable before leveling")
	loaded_state.fairy_task_ready_counts[loaded_state.FAIRY_TASK_FORAGE_INGREDIENTS] = 3
	for reward_index in range(3):
		var forage_reward: Dictionary = loaded_state.collect_fairy_task_reward(loaded_state.FAIRY_TASK_FORAGE_INGREDIENTS)
		if not bool(forage_reward.get("Success", false)):
			fail("Forage reward %d should be collectable for leveling" % reward_index)
		if not forage_reward.has("LevelUpNames"):
			fail("Fairy rewards should expose level-up names for UI feedback")
	var leveled_nim: Dictionary = loaded_state.get_fairy_data("Nim")
	if int(leveled_nim.get("FairyLevel", 1)) != 2:
		fail("Nim should reach level 2 after repeated forage work")
	if int(leveled_nim.get("FairyXP", 0)) != 0:
		fail("Nim XP should roll over after leveling")
	if float(leveled_nim.get("WorkBonus", 1.0)) < 1.5:
		fail("Nim should gain work bonus after leveling")
	var leveled_data: Dictionary = loaded_state.get_save_data()
	var reloaded_state = load("res://scripts/game_state.gd").new()
	reloaded_state.apply_save_data(leveled_data)
	var reloaded_nim: Dictionary = reloaded_state.get_fairy_data("Nim")
	if int(reloaded_nim.get("FairyLevel", 1)) != 2:
		fail("Fairy level should survive save/load")
	if float(reloaded_nim.get("WorkBonus", 1.0)) < 1.5:
		fail("Fairy work bonus should survive save/load")

	print("Fairy worker assignment behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
