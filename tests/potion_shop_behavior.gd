extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.potion_shop_level != 1:
		fail("Expected Potion Shop level 1 default")
	if state.mana_potion_count != 0:
		fail("Expected zero mana potions default")
	if state.get_potion_mana_cost() != 25:
		fail("Expected mana potion cost 25")
	if state.get_potion_craft_time() != 5:
		fail("Expected starting craft time 5 seconds")
	if state.get_potion_sell_value() != 50:
		fail("Expected sell value 50 coins")

	if state.start_mana_potion_craft():
		fail("Craft should fail without enough mana")
	state.total_mana = 25
	if not state.start_mana_potion_craft():
		fail("Craft should start with enough mana")
	if state.total_mana != 0:
		fail("Craft should spend 25 mana")
	if not state.potion_crafting_active:
		fail("Crafting should be active")
	if state.start_mana_potion_craft():
		fail("Craft should not start while already crafting")

	state.update_potion_crafting(4.9)
	if state.mana_potion_count != 0:
		fail("Potion should not finish early")
	state.update_potion_crafting(0.2)
	if state.potion_crafting_active:
		fail("Crafting should complete after timer")
	if state.mana_potion_count != 1:
		fail("Craft completion should add one potion")

	if not state.sell_mana_potion():
		fail("Sell should succeed with one potion")
	if state.mana_potion_count != 0:
		fail("Sell should remove one potion")
	if state.total_coins != 50:
		fail("Sell should add 50 coins")
	if state.sell_mana_potion():
		fail("Sell should fail with no potions")

	state.total_coins = 100
	if not state.upgrade_potion_shop():
		fail("Upgrade should succeed with 100 coins")
	if state.total_coins != 0:
		fail("Upgrade should spend 100 coins")
	if state.potion_shop_level != 2:
		fail("Upgrade should raise shop level")
	if state.get_potion_craft_time() != 4:
		fail("Upgrade should reduce craft time by one second")

	var data: Dictionary = state.get_save_data()
	if not data.has("potion_shop_level"):
		fail("Save data should include potion shop level")
	if not data.has("mana_potion_count"):
		fail("Save data should include mana potion count")
	if not data.has("potion_crafting_active"):
		fail("Save data should include crafting active state")

	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.potion_shop_level != 2:
		fail("Loaded shop level should persist")
	if loaded_state.get_potion_craft_time() != 4:
		fail("Loaded craft time should persist")

	print("Potion Shop behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
