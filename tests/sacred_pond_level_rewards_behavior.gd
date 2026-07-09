extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.sacred_pond_level != 1:
		fail("Expected pond level 1 default")
	if state.sacred_pond_water_purity != 15:
		fail("Expected 15 water purity default")
	if state.sacred_pond_restore_cost != 25:
		fail("Expected restore cost 25 default")
	if state.get_sacred_pond_base_restore_amount() != 5:
		fail("Expected base restore amount 5")
	if state.get_sacred_pond_total_restore_amount() != 6:
		fail("Expected Pip to make default total restore 6")
	if state.get_sun_koi_guardian_spirit_bonus() != 0:
		fail("Sun Koi Guardian spirit bonus should start inactive")
	if state.get_active_pond_bonus_text() != "None":
		fail("Expected no active pond bonus at level 1")
	if state.get_next_pond_reward_text() != "Blooming Waters at 25%":
		fail("Expected level 2 next reward text")

	state.total_mana = 200
	if not state.restore_sacred_pond():
		fail("Restore should succeed with enough mana")
	if state.total_mana != 175:
		fail("Restore should spend 25 mana")
	if state.sacred_pond_water_purity != 21:
		fail("Restore should add total restore amount")
	if state.sacred_pond_spirit_energy != 10:
		fail("Restore should add spirit energy")
	if state.sacred_pond_restore_cost != 32:
		fail("Restore cost should scale by 1.25 rounded up")

	state.sacred_pond_water_purity = 25
	state.update_sacred_pond_level_and_rewards()
	if state.sacred_pond_level != 2:
		fail("25 purity should set pond level 2")
	if not state.is_pond_reward_unlocked("Blooming Waters"):
		fail("Level 2 should unlock Blooming Waters")
	if state.get_active_pond_bonus_text() != "Blooming Waters +5% Flower Production":
		fail("Expected Blooming Waters active bonus text")
	if int(round(state.get_flower_production_rate() * 10.0)) != 74:
		fail("Blooming Waters should add 5 percent to Flower Grove total production")

	state.sacred_pond_water_purity = 50
	state.update_sacred_pond_level_and_rewards()
	if state.sacred_pond_level != 3:
		fail("50 purity should set pond level 3")
	if state.flower_grove_max_stored_mana != 110:
		fail("Moonlit Reflection should add 10 max stored mana once")
	state.update_sacred_pond_level_and_rewards()
	if state.flower_grove_max_stored_mana != 110:
		fail("Moonlit Reflection should not stack repeatedly")

	state.sacred_pond_water_purity = 75
	state.update_sacred_pond_level_and_rewards()
	if state.sacred_pond_level != 4:
		fail("75 purity should set pond level 4")
	if state.fairy_max_residents != 4:
		fail("Fairy Blessing should add one resident capacity placeholder")

	state.sacred_pond_water_purity = 100
	state.update_sacred_pond_level_and_rewards()
	if state.sacred_pond_level != 5:
		fail("100 purity should set pond level 5")
	if not state.is_pond_reward_unlocked("Sun Koi Guardian"):
		fail("100 purity should unlock Sun Koi Guardian")
	if state.get_active_pond_bonus_text() != "Sun Koi Guardian +1 Spirit Energy per Restore":
		fail("Sun Koi Guardian should expose real active bonus text")
	if state.get_sun_koi_guardian_spirit_bonus() != 1:
		fail("Sun Koi Guardian should add one bonus Spirit Energy per restore")
	if state.get_next_pond_reward_text() != "All pond rewards unlocked":
		fail("Expected all rewards unlocked text at level 5")
	state.total_mana = state.sacred_pond_restore_cost
	state.sacred_pond_water_purity = 99
	var spirit_before: int = state.sacred_pond_spirit_energy
	if not state.restore_sacred_pond():
		fail("Restore should still work after Sun Koi Guardian unlock")
	if state.sacred_pond_spirit_energy != spirit_before + 11:
		fail("Sun Koi Guardian should add 11 total Spirit Energy after unlock")
	if state.sacred_pond_water_purity != 100:
		fail("Restore should cap water purity at 100")
	var maxed_mana: int = state.sacred_pond_restore_cost
	var maxed_spirit: int = state.sacred_pond_spirit_energy
	state.total_mana = maxed_mana
	if state.restore_sacred_pond():
		fail("Restore should not run when the Sacred Pond is fully restored")
	if state.total_mana != maxed_mana:
		fail("Full pond restore attempt should not spend Mana")
	if state.sacred_pond_spirit_energy != maxed_spirit:
		fail("Full pond restore attempt should not add Spirit Energy")
	if state.can_restore_sacred_pond():
		fail("Full pond should not report restorable")

	var data: Dictionary = state.get_save_data()
	if not data.has("active_pond_bonus"):
		fail("Save data should include active pond bonus")
	if not data.has("unlocked_pond_rewards"):
		fail("Save data should include unlocked pond rewards")
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.sacred_pond_level != 5:
		fail("Loaded pond level should persist")
	if not loaded_state.is_pond_reward_unlocked("Sun Koi Guardian"):
		fail("Loaded rewards should persist")
	if loaded_state.get_sun_koi_guardian_spirit_bonus() != 1:
		fail("Loaded Sun Koi Guardian bonus should persist")
	if loaded_state.fairy_max_residents != 4:
		fail("Loaded Fairy Blessing capacity should remain applied")

	print("Sacred Pond level rewards behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
