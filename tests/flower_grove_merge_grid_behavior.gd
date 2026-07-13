extends SceneTree

func _init() -> void:
	var state: Node = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.flower_grove_grid_slots.size() != 12:
		fail("Flower Grove grid should have 12 slots")
	if int(state.get_flower_grid_production_rate()) != 5:
		fail("Starting grid should produce 5 mana/sec")
	if int(state.get_flower_production_rate()) != 7:
		fail("Starting production should include Luna fairy bonus")
	if bool(state.flower_grove_grid_slots[6].get("Locked", false)) != true:
		fail("Slots after the first 6 should start locked")

	var merge_result: Dictionary = state.merge_flower_grid_slots(0, 1)
	if not bool(merge_result.get("Success", false)):
		fail("Matching seeds should merge")
	if int(state.flower_grove_grid_slots[1].get("Tier", 0)) != state.FLOWER_TIER_FLOWER:
		fail("Two seeds should become one Flower")
	if int(state.flower_grove_grid_slots[0].get("Tier", -1)) != state.FLOWER_TIER_EMPTY:
		fail("Merged source slot should become empty")
	if state.total_mana != 5:
		fail("Seed merge should reward 5 mana")
	if int(state.flower_grove_base_mana_production_rate) != 6:
		fail("Merge should update base production by the net flower value")

	if state.plant_seed_in_flower_slot(0) != 1:
		fail("Empty unlocked slot should accept a new Seed")
	if int(state.flower_grove_grid_slots[0].get("Tier", 0)) != state.FLOWER_TIER_SEED:
		fail("Planting should create a Seed")

	state.total_mana = 50
	if state.unlock_flower_plot() != 1:
		fail("Unlock plot should still work with merge grid")
	if bool(state.flower_grove_grid_slots[6].get("Locked", true)):
		fail("Unlock plot should unlock more grid slots")

	state.flower_grove_grid_slots[0]["Tier"] = state.FLOWER_TIER_RARE_BLOSSOM
	state.flower_grove_grid_slots[1]["Tier"] = state.FLOWER_TIER_RARE_BLOSSOM
	state.flower_grove_base_mana_production_rate = 50.0
	state.total_mana = 0
	var cashout_result: Dictionary = state.merge_flower_grid_slots(0, 1)
	if not bool(cashout_result.get("Success", false)):
		fail("Matching Rare Blossoms should cash out")
	if int(cashout_result.get("Reward", 0)) != 180:
		fail("Rare Blossom cash-out should reward 180 mana")
	if state.total_mana != 180:
		fail("Rare Blossom cash-out should add mana")
	if int(state.flower_grove_grid_slots[0].get("Tier", -1)) != state.FLOWER_TIER_EMPTY:
		fail("Rare Blossom cash-out should clear source slot")
	if int(state.flower_grove_grid_slots[1].get("Tier", -1)) != state.FLOWER_TIER_EMPTY:
		fail("Rare Blossom cash-out should clear target slot")
	if int(state.flower_grove_base_mana_production_rate) != 10:
		fail("Rare Blossom cash-out should remove both flowers from production")

	var save_data: Dictionary = state.get_save_data()
	var loaded: Node = load("res://scripts/game_state.gd").new()
	loaded.apply_save_data(save_data)
	if loaded.flower_grove_grid_slots.size() != 12:
		fail("Grid slot count should persist")
	if int(loaded.flower_grove_grid_slots[1].get("Tier", -1)) != loaded.FLOWER_TIER_EMPTY:
		fail("Cashed-out flower slot should persist as empty")
	if bool(loaded.flower_grove_grid_slots[6].get("Locked", true)):
		fail("Unlocked grid slot should persist")

	print("Flower Grove merge grid behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
