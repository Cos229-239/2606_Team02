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
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.get_fairy_assigned_area("Luna") != "Sacred Koi Pond":
		fail("Luna assignment should survive load")
	if int(loaded_state.get_flower_fairy_bonus_production()) != 0:
		fail("Loaded Flower Grove bonus should be recalculated")
	if loaded_state.get_sacred_pond_fairy_restore_bonus() != 3:
		fail("Loaded Sacred Pond bonus should be recalculated")

	print("Fairy worker assignment behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
