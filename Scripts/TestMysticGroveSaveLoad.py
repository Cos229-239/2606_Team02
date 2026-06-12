import unreal

SAVE_BLUEPRINT_PATH = "/Game/Saves/SaveGame_MysticGrove"
SAVE_SLOT = "MysticGrove_SaveSlot"

EXPECTED_DEFAULTS = {
    "total_mana": 0,
    "total_coins": 0,
    "flower_grove_stored_mana": 0.0,
    "flower_grove_level": 1,
    "flower_grove_max_stored_mana": 100,
    "flower_grove_mana_production_rate": 5.0,
    "sacred_pond_water_purity": 15,
    "sacred_pond_level": 1,
    "fairy_house_level": 1,
    "fairy_residents": 1,
    "fairy_workers_active": 1,
}


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def assert_close(actual, expected, message):
    if abs(float(actual) - float(expected)) > 0.01:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def get_generated_class(blueprint_path):
    blueprint = unreal.EditorAssetLibrary.load_asset(blueprint_path)
    if not blueprint:
        raise RuntimeError(f"Missing Blueprint asset: {blueprint_path}")

    generated_class = blueprint.generated_class()
    if not generated_class:
        raise RuntimeError(f"Blueprint has no generated class: {blueprint_path}")
    return generated_class


def main():
    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)
    if not save_game:
        raise RuntimeError("Could not create SaveGame_MysticGrove object.")

    for property_name, expected_value in EXPECTED_DEFAULTS.items():
        actual_value = save_game.get_editor_property(property_name)
        if isinstance(expected_value, float):
            assert_close(actual_value, expected_value, f"Default {property_name} is wrong.")
        else:
            assert_equal(actual_value, expected_value, f"Default {property_name} is wrong.")

    save_game.set_editor_property("total_mana", 42)
    save_game.set_editor_property("total_coins", 7)
    save_game.set_editor_property("flower_grove_stored_mana", 25.0)
    save_game.set_editor_property("flower_grove_level", 2)
    save_game.set_editor_property("flower_grove_max_stored_mana", 150)
    save_game.set_editor_property("flower_grove_mana_production_rate", 9.0)
    save_game.set_editor_property("sacred_pond_water_purity", 33)
    save_game.set_editor_property("sacred_pond_level", 3)
    save_game.set_editor_property("fairy_house_level", 4)
    save_game.set_editor_property("fairy_residents", 2)
    save_game.set_editor_property("fairy_workers_active", 1)

    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("SaveGame_MysticGrove did not save to MysticGrove_SaveSlot.")

    loaded_game = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded_game:
        raise RuntimeError("Could not load MysticGrove_SaveSlot after saving.")

    assert_equal(loaded_game.get_editor_property("total_mana"), 42, "Saved TotalMana did not load.")
    assert_equal(loaded_game.get_editor_property("total_coins"), 7, "Saved TotalCoins did not load.")
    assert_close(loaded_game.get_editor_property("flower_grove_stored_mana"), 25.0, "Saved FlowerGroveStoredMana did not load.")
    assert_equal(loaded_game.get_editor_property("flower_grove_level"), 2, "Saved FlowerGroveLevel did not load.")
    assert_equal(loaded_game.get_editor_property("flower_grove_max_stored_mana"), 150, "Saved FlowerGroveMaxStoredMana did not load.")
    assert_close(loaded_game.get_editor_property("flower_grove_mana_production_rate"), 9.0, "Saved FlowerGroveManaProductionRate did not load.")
    assert_equal(loaded_game.get_editor_property("sacred_pond_water_purity"), 33, "Saved SacredPondWaterPurity did not load.")
    assert_equal(loaded_game.get_editor_property("sacred_pond_level"), 3, "Saved SacredPondLevel did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_house_level"), 4, "Saved FairyHouseLevel did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_residents"), 2, "Saved FairyResidents did not load.")
    assert_equal(loaded_game.get_editor_property("fairy_workers_active"), 1, "Saved FairyWorkersActive did not load.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Mystic Grove save/load verification passed.")


main()
