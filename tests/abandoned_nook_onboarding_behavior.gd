extends SceneTree

func _init() -> void:
	var state: Node = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.has_completed_onboarding:
		fail("Onboarding should start incomplete after reset")
	if state.first_merge_complete:
		fail("First merge should start incomplete after reset")

	state.complete_onboarding_merge()

	if not state.has_completed_onboarding:
		fail("Onboarding should complete after first merge")
	if not state.first_merge_complete:
		fail("First merge flag should be saved after merge")
	if state.total_mana != 10:
		fail("First merge should reward 10 Mana")
	if state.grove_restoration < 5:
		fail("First merge should restore the grove to at least 5 percent")
	if not state.has_seen_tutorial:
		fail("Old tutorial popup should be skipped after onboarding")

	var save_data: Dictionary = state.get_save_data()
	var loaded: Node = load("res://scripts/game_state.gd").new()
	loaded.apply_save_data(save_data)

	if not loaded.has_completed_onboarding:
		fail("Onboarding completion should persist")
	if not loaded.first_merge_complete:
		fail("First merge completion should persist")
	if loaded.total_mana != 10:
		fail("Onboarding Mana reward should persist")
	if loaded.grove_restoration < 5:
		fail("Onboarding restoration should persist")

	print("Abandoned Nook onboarding behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
