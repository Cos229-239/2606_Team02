extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	for method_name in [
		"get_forge_craft_mana_cost",
		"get_forge_upgrade_cost_mana",
		"get_forge_upgrade_cost_coins",
		"get_forge_enhance_crystal_cost",
		"craft_forge_gear",
		"enhance_forge_gear",
		"upgrade_arcane_forge"
	]:
		if not state.has_method(method_name):
			fail("GameState should expose %s" % method_name)
			return

	if state.arcane_forge_level != 1:
		fail("Expected Arcane Forge level 1 default")
	if state.forge_gear_count != 0:
		fail("Expected zero crafted gear default")
	if state.arcane_crystal_count != 0:
		fail("Expected zero arcane crystals default")
	if state.forge_enhancement_power != 0:
		fail("Expected zero enhancement power default")
	if state.get_forge_craft_mana_cost() != 40:
		fail("Expected starting craft cost 40 mana")
	if state.get_forge_upgrade_cost_mana() != 100:
		fail("Expected starting upgrade mana cost 100")
	if state.get_forge_upgrade_cost_coins() != 50:
		fail("Expected starting upgrade coin cost 50")

	if state.craft_forge_gear():
		fail("Craft should fail without enough mana")
	state.total_mana = 40
	if not state.craft_forge_gear():
		fail("Craft should succeed with enough mana")
	if state.total_mana != 0:
		fail("Craft should spend mana")
	if state.forge_gear_count != 1:
		fail("Craft should add one gear")
	if state.arcane_crystal_count != 6:
		fail("Craft should add level-scaled crystals")

	if state.enhance_forge_gear():
		fail("Enhance should fail without enough crystals")
	state.arcane_crystal_count = state.get_forge_enhance_crystal_cost()
	if not state.enhance_forge_gear():
		fail("Enhance should succeed with gear and crystals")
	if state.forge_enhancement_power != 1:
		fail("Enhance should raise gear power")
	if state.arcane_crystal_count != 0:
		fail("Enhance should spend crystals")

	state.total_mana = state.get_forge_upgrade_cost_mana()
	state.total_coins = state.get_forge_upgrade_cost_coins()
	if not state.upgrade_arcane_forge():
		fail("Forge upgrade should succeed with enough resources")
	if state.arcane_forge_level != 2:
		fail("Forge upgrade should raise level")
	if state.get_forge_craft_mana_cost() != 35:
		fail("Forge level 2 should reduce craft cost")

	var data: Dictionary = state.get_save_data()
	if not data.has("arcane_forge_level"):
		fail("Save data should include forge level")
	if not data.has("forge_gear_count"):
		fail("Save data should include gear count")
	if not data.has("arcane_crystal_count"):
		fail("Save data should include crystal count")

	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.arcane_forge_level != 2:
		fail("Loaded forge level should persist")
	if loaded_state.forge_enhancement_power != 1:
		fail("Loaded enhancement power should persist")

	print("Arcane Forge behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
