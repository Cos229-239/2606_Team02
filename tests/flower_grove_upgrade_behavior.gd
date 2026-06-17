extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()
	if state.flower_grove_level != 1:
		fail("Expected level 1 default")
	if state.flower_grove_active_plots != 3 or state.flower_grove_max_plots != 6:
		fail("Expected 3 / 6 default plots")
	if int(state.flower_grove_fairy_bonus_production) != 2:
		fail("Expected Luna fairy bonus to start at 2")
	if int(state.get_flower_production_rate()) != 7:
		fail("Expected total production to start at 7")
	if state.get_flower_unlock_cost() != 50:
		fail("Expected first unlock cost 50")
	state.total_mana = 25
	if not state.upgrade_flower_grove():
		fail("Upgrade should succeed with 25 mana")
	if state.total_mana != 0:
		fail("Upgrade should spend 25 mana")
	if state.flower_grove_level != 2:
		fail("Upgrade should increase level")
	if int(state.flower_grove_base_mana_production_rate) != 7:
		fail("Upgrade should raise base production to 7")
	if int(state.get_flower_production_rate()) != 9:
		fail("Total production should include Luna after upgrade")
	if state.flower_grove_max_stored_mana != 125:
		fail("Level 2 should increase max storage")
	if state.get_flower_upgrade_cost() != 38:
		fail("Upgrade cost should ceil to 38")
	state.flower_grove_fairy_bonus_production = 3.0
	if int(state.get_flower_production_rate()) != 10:
		fail("Total production should include fairy bonus")
	state.total_mana = 50
	if state.unlock_flower_plot() != 1:
		fail("First plot unlock should succeed")
	if state.total_mana != 0:
		fail("Plot unlock should spend 50 mana")
	if state.flower_grove_active_plots != 4:
		fail("Plot unlock should raise active plots to 4")
	if int(state.flower_grove_base_mana_production_rate) != 9:
		fail("Plot unlock should raise base production by 2")
	if int(state.get_flower_production_rate()) != 12:
		fail("Total production should still include fairy bonus after plot unlock")
	if state.get_flower_unlock_cost() != 100:
		fail("Second plot unlock cost should be 100")
	state.total_mana = 100
	if state.unlock_flower_plot() != 1:
		fail("Second plot unlock should succeed")
	if state.get_flower_unlock_cost() != 200:
		fail("Third plot unlock cost should be 200")
	print("Flower Grove upgrade behavior check passed")
	quit(0)

func fail(message: String) -> void:
	push_error(message)
	quit(1)
