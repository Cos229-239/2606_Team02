extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.flower_grove_stored_mana != 0.0:
		fail("Stored Mana should start at 0")
	if state.flower_grove_max_stored_mana != 100:
		fail("Max Stored Mana should start at 100")
	if int(state.flower_grove_base_mana_production_rate) != 5:
		fail("Base Mana Production should start at 5/sec")
	if state.flower_grove_upgrade_cost != 25:
		fail("Flower Upgrade Cost should start at 25 Mana")
	if state.get_flower_unlock_cost() != 50:
		fail("First Unlock Plot cost should be 50 Mana")

	if state.sacred_pond_water_purity != 15:
		fail("Water Purity should start at 15")
	if state.sacred_pond_restore_cost != 25:
		fail("Restore Cost should start at 25 Mana")
	if state.sacred_pond_base_restore_amount != 5:
		fail("Restore Amount should start at 5")

	if state.potion_mana_cost != 25:
		fail("Mana Potion Cost should be 25 Mana")
	if state.get_potion_craft_time() != 5:
		fail("Craft Time should start at 5 seconds")
	if state.potion_sell_value != 50:
		fail("Sell Value should be 50 Coins")
	if state.potion_shop_upgrade_cost != 100:
		fail("Shop Upgrade Cost should be 100 Coins")

	_complete_and_claim_loop(state)
	var save_data: Dictionary = state.get_save_data()
	var loaded = load("res://scripts/game_state.gd").new()
	loaded.apply_save_data(save_data)

	if loaded.total_mana != state.total_mana:
		fail("Mana should persist")
	if loaded.total_coins != state.total_coins:
		fail("Coins should persist")
	if loaded.flower_grove_level != state.flower_grove_level:
		fail("Flower Grove level should persist")
	if loaded.flower_grove_active_plots != state.flower_grove_active_plots:
		fail("Unlocked plots should persist")
	if loaded.get_fairy_assigned_area("Nim") != "Flower Grove":
		fail("Fairy assignment should persist")
	if loaded.sacred_pond_water_purity != state.sacred_pond_water_purity:
		fail("Pond progress should persist")
	if loaded.sacred_pond_level != state.sacred_pond_level:
		fail("Pond level should persist")
	if loaded.sacred_pond_spirit_energy != state.sacred_pond_spirit_energy:
		fail("Spirit energy should persist")
	if loaded.mana_potion_count != state.mana_potion_count:
		fail("Potion count should persist")
	if loaded.potion_shop_level != state.potion_shop_level:
		fail("Potion shop level should persist")
	if not loaded.is_quest_completed("first_harvest"):
		fail("Quest progress should persist")
	if not loaded.is_quest_claimed("first_harvest"):
		fail("Claimed quests should persist")

	print("Balance and save behavior check passed")
	quit(0)


func _complete_and_claim_loop(state: Node) -> void:
	state.flower_grove_stored_mana = 50.0
	state.collect_flower_mana()
	state.claim_quest_reward("first_harvest")

	state.total_mana = max(state.total_mana, state.get_flower_upgrade_cost())
	state.upgrade_flower_grove()

	state.total_mana = max(state.total_mana, state.get_flower_unlock_cost())
	state.unlock_flower_plot()

	state.assign_fairy_to_area("Nim", "Flower Grove")

	state.total_mana = max(state.total_mana, state.sacred_pond_restore_cost)
	state.restore_sacred_pond()

	state.total_mana = max(state.total_mana, state.get_potion_mana_cost())
	state.start_mana_potion_craft()
	state.update_potion_crafting(float(state.get_potion_craft_time()) + 0.1)
	state.sell_mana_potion()

	state.total_coins = max(state.total_coins, state.potion_shop_upgrade_cost)
	state.upgrade_potion_shop()


func fail(message: String) -> void:
	push_error(message)
	quit(1)
