extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.fairies.size() != 5:
		fail("Expected Luna, Pip, Nim, and recruitable fairies to exist")
	if state.get_unlocked_fairy_count() != 3:
		fail("Expected three fairies to be unlocked by default")
	if state.get_recruitable_fairy_cards().size() != 2:
		fail("Expected two recruitable fairy cards by default")
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
		if String(task.get("StatusText", "")) == "":
			fail("Fairy task cards should expose visible status text")
		if String(task.get("WorkerText", "")) == "":
			fail("Fairy task cards should expose worker contribution text")
		if String(task.get("ProgressText", "")) == "":
			fail("Fairy task cards should expose visible progress text")
		if String(task.get("TimeRemainingText", "")) == "":
			fail("Fairy task cards should expose visible ETA text")
		if not task.has("IsReady") or not task.has("IsActive"):
			fail("Fairy task cards should expose ready and active flags")
	var first_mana_task: Dictionary = task_cards[0]
	if String(first_mana_task.get("StatusText", "")) != "Working":
		fail("Mana task should show working when Luna is assigned")
	if not String(first_mana_task.get("WorkerText", "")).contains("Luna"):
		fail("Mana task should show Luna as a working fairy")
	if state.get_fairy_house_task_speed_multiplier() != 1.0:
		fail("Fairy House level 1 should not alter task speed")
	if state.get_fairy_house_reward_multiplier() != 1.0:
		fail("Fairy House level 1 should not alter task rewards")
	if state.get_total_fairy_task_ready_count() != 0:
		fail("No fairy rewards should be ready at the start")
	if not state.get_fairy_task_inbox_text().contains("in progress"):
		fail("Fairy task inbox should summarize active work")

	state.update_fairy_tasks(30.0)
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_FLOWER_GROVE) != 1:
		fail("Luna should complete one Flower Grove fairy task after 30 seconds")
	if state.get_fairy_task_ready_count(state.FAIRY_TASK_SACRED_POND) != 0:
		fail("Pip should need more time before a Sacred Pond fairy task is ready")
	var ready_task: Dictionary = state.get_fairy_task_cards()[0]
	if String(ready_task.get("StatusText", "")) != "Ready to collect":
		fail("Completed mana task should advertise that a reward is ready")
	if not bool(ready_task.get("IsReady", false)):
		fail("Completed mana task should expose ready flag")
	if state.get_total_fairy_task_ready_count() != 1:
		fail("Fairy task inbox should count ready rewards")
	if not state.get_fairy_task_inbox_text().contains("ready to collect"):
		fail("Fairy task inbox should summarize ready rewards")

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
	var claim_all_reward: Dictionary = state.collect_all_fairy_task_rewards()
	if not bool(claim_all_reward.get("Success", false)):
		fail("Claim all should collect ready fairy task rewards")
	if int(claim_all_reward.get("ClaimedCount", 0)) != 3:
		fail("Claim all should collect mana, pond, and ingredient rewards")
	if not String(claim_all_reward.get("Message", "")).contains("Mana"):
		fail("Claim all should summarize collected Mana")
	if state.sacred_pond_spirit_energy != 1:
		fail("Claim all should award Spirit Energy")
	if state.get_total_fairy_task_ready_count() != 0:
		fail("Claim all should clear ready fairy rewards")
	if bool(state.collect_all_fairy_task_rewards().get("Success", false)):
		fail("Claim all should fail cleanly when no rewards are ready")
	var luna_after_tasks: Dictionary = state.get_fairy_data("Luna")
	if int(luna_after_tasks.get("FairyLevel", 1)) != 2:
		fail("Luna should level up from individual and claim-all task rewards")
	if int(luna_after_tasks.get("FairyXP", 0)) != 0:
		fail("Luna XP should reset after leveling from claim-all rewards")
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
	if state.get_sacred_pond_fairy_restore_bonus() != 4:
		fail("Expected Pip and Luna to boost Sacred Pond restore")
	if state.get_sacred_pond_total_restore_amount() != 9:
		fail("Expected total restore amount to update to 9")

	state.total_mana = 25
	var old_purity: int = state.sacred_pond_water_purity
	if not state.restore_sacred_pond():
		fail("Restore should succeed with enough mana")
	if state.sacred_pond_water_purity != old_purity + 9:
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
	if loaded_state.get_sacred_pond_fairy_restore_bonus() != 4:
		fail("Loaded Sacred Pond bonus should be recalculated")

	loaded_state.total_mana = 1000
	loaded_state.total_coins = 1000
	loaded_state.sacred_pond_spirit_energy = 100
	var upgrade_2: Dictionary = loaded_state.upgrade_fairy_house()
	if not bool(upgrade_2.get("Success", false)) or loaded_state.fairy_house_level != 2:
		fail("Fairy House should upgrade to level 2")
	if loaded_state.get_fairy_house_task_speed_multiplier() <= 1.0:
		fail("Fairy House level 2 should speed up fairy tasks")
	var capacity_before: int = loaded_state.fairy_max_residents
	var upgrade_3: Dictionary = loaded_state.upgrade_fairy_house()
	if not bool(upgrade_3.get("Success", false)) or loaded_state.fairy_house_level != 3:
		fail("Fairy House should upgrade to level 3")
	if loaded_state.fairy_max_residents != capacity_before + 1:
		fail("Fairy House level 3 should add fairy capacity")
	var reward_before_level_4: int = loaded_state.get_fairy_task_reward_amount(loaded_state.FAIRY_TASK_FLOWER_GROVE)
	loaded_state.upgrade_fairy_house()
	if loaded_state.fairy_house_level != 4:
		fail("Fairy House should upgrade to level 4")
	if loaded_state.get_fairy_task_reward_amount(loaded_state.FAIRY_TASK_FLOWER_GROVE) <= reward_before_level_4:
		fail("Fairy House level 4 should improve task rewards")
	loaded_state.upgrade_fairy_house()
	if loaded_state.fairy_house_level != loaded_state.FAIRY_HOUSE_MAX_LEVEL:
		fail("Fairy House should upgrade to max level")
	if loaded_state.get_fairy_house_xp_gain() != 2:
		fail("Max Fairy House should grant extra task XP")
	if loaded_state.fairy_max_residents < 5:
		fail("Max Fairy House should have room for recruitable fairies")

	loaded_state.total_mana = 1000
	loaded_state.total_coins = 1000
	loaded_state.sacred_pond_spirit_energy = 100
	loaded_state.add_potion_ingredient(loaded_state.POTION_INGREDIENT_MANA_CRYSTAL, 4)
	loaded_state.add_potion_ingredient(loaded_state.POTION_INGREDIENT_DREAMBLOOM, 4)
	loaded_state.add_potion_ingredient(loaded_state.POTION_INGREDIENT_EMPTY_VIAL, 2)
	var sol_recruit: Dictionary = loaded_state.recruit_fairy("Sol")
	if not bool(sol_recruit.get("Success", false)):
		fail("Sol should be recruitable with capacity and resources")
	if loaded_state.get_unlocked_fairy_count() != 4:
		fail("Recruiting Sol should increase unlocked fairy count")
	var sol_assign: String = loaded_state.assign_fairy_to_area("Sol", "Flower Grove")
	if sol_assign != "Sol assigned to Flower Grove":
		fail("Recruited Sol should be assignable")
	if int(loaded_state.get_flower_fairy_bonus_production()) < 1:
		fail("Recruited Sol should add Flower Grove production")
	var mira_recruit: Dictionary = loaded_state.recruit_fairy("Mira")
	if not bool(mira_recruit.get("Success", false)):
		fail("Mira should be recruitable with max house capacity")
	if loaded_state.get_unlocked_fairy_count() != 5:
		fail("Recruiting Mira should fill max fairy capacity")
	if bool(loaded_state.recruit_fairy("Mira").get("Success", false)):
		fail("Mira should not be recruitable twice")

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
	if int(leveled_nim.get("FairyXP", 0)) != 3:
		fail("Nim XP should carry over after max-house training")
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
	if reloaded_state.fairy_house_level != loaded_state.FAIRY_HOUSE_MAX_LEVEL:
		fail("Fairy House level should survive save/load")
	if not bool(reloaded_state.get_fairy_data("Sol").get("IsUnlocked", false)):
		fail("Recruited Sol should survive save/load")
	if not bool(reloaded_state.get_fairy_data("Mira").get("IsUnlocked", false)):
		fail("Recruited Mira should survive save/load")

	print("Fairy worker assignment behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
