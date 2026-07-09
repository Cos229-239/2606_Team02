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
	if state.get_potion_recipes().size() < 2:
		fail("Potion Shop should expose more than one recipe")
	if state.get_potion_recipe_data("spirit_tonic").is_empty():
		fail("Spirit Tonic recipe should exist")

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

	state.total_mana = 20
	state.sacred_pond_spirit_energy = 4
	if state.start_potion_craft("spirit_tonic"):
		fail("Spirit Tonic should require enough Spirit Energy")
	state.sacred_pond_spirit_energy = 5
	if not state.start_potion_craft("spirit_tonic"):
		fail("Spirit Tonic craft should start with Mana and Spirit Energy")
	if state.total_mana != 0:
		fail("Spirit Tonic should spend 20 mana")
	if state.sacred_pond_spirit_energy != 0:
		fail("Spirit Tonic should spend 5 spirit energy")
	state.update_potion_crafting(float(state.get_potion_craft_time("spirit_tonic")) + 0.1)
	if state.get_potion_count("spirit_tonic") != 1:
		fail("Spirit Tonic craft should add one tonic")
	if not state.sell_potion("spirit_tonic"):
		fail("Spirit Tonic should sell when owned")
	if state.total_coins != 145:
		fail("Spirit Tonic should sell for 95 coins after prior Mana Potion sale")

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
	if not data.has("potion_inventory"):
		fail("Save data should include recipe potion inventory")
	if not data.has("potion_crafting_active"):
		fail("Save data should include crafting active state")

	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.potion_shop_level != 2:
		fail("Loaded shop level should persist")
	if loaded_state.get_potion_craft_time() != 4:
		fail("Loaded craft time should persist")
	if loaded_state.get_potion_count("mana_potion") != loaded_state.mana_potion_count:
		fail("Loaded mana potion legacy count should mirror recipe inventory")

	var legacy_state = load("res://scripts/game_state.gd").new()
	legacy_state.apply_save_data({
		"mana_potion_count": 3,
		"potion_shop_level": 1
	})
	if legacy_state.get_potion_count("mana_potion") != 3:
		fail("Old saves should migrate mana_potion_count into recipe inventory")

	print("Potion Shop behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
