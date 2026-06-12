import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"
SAVE_BLUEPRINT_PATH = "/Game/Saves/SaveGame_MysticGrove"
SAVE_SLOT = "MysticGrove_SaveSlot"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def get_generated_class(blueprint_path):
    blueprint = unreal.EditorAssetLibrary.load_asset(blueprint_path)
    if not blueprint:
        raise RuntimeError(f"Missing Blueprint asset: {blueprint_path}")
    generated_class = blueprint.generated_class()
    if not generated_class:
        raise RuntimeError(f"Blueprint has no generated class: {blueprint_path}")
    return generated_class


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def call_restore(pond, mana):
    restored = pond.restore_sacred_pond_with_mana(mana)
    remaining = pond.get_editor_property("last_restore_remaining_mana")
    message = str(pond.get_editor_property("last_restore_message"))
    return restored, remaining, message


def main():
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)

    pond = find_actor("Sacred Koi Pond")
    if not pond:
        raise RuntimeError("Missing Sacred Koi Pond actor.")

    required_actor_properties = [
        "sacred_pond_water_purity",
        "max_water_purity",
        "spirit_energy",
        "sacred_pond_level",
        "restore_cost",
    ]
    for property_name in required_actor_properties:
        try:
            pond.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 6 missing property {property_name}.") from exc

    pond.set_editor_property("sacred_pond_water_purity", 15)
    pond.set_editor_property("max_water_purity", 100)
    pond.set_editor_property("spirit_energy", 0)
    pond.set_editor_property("sacred_pond_level", 1)
    pond.set_editor_property("restore_cost", 25)

    restored, remaining_mana, message = call_restore(pond, 10)
    assert_equal(restored, False, "Restore should fail without enough mana.")
    assert_equal(remaining_mana, 10, "Failed restore should leave mana unchanged.")
    assert_equal(pond.get_editor_property("sacred_pond_water_purity"), 15, "Failed restore should leave purity unchanged.")
    assert_equal(pond.get_editor_property("spirit_energy"), 0, "Failed restore should leave spirit energy unchanged.")
    if "Not enough mana" not in message:
        raise RuntimeError(f"Expected not enough mana message, got: {message}")

    restored, remaining_mana, message = call_restore(pond, 80)
    assert_equal(restored, True, "Restore should succeed with enough mana.")
    assert_equal(remaining_mana, 55, "Restore should subtract 25 mana.")
    assert_equal(pond.get_editor_property("sacred_pond_water_purity"), 20, "Restore should increase purity by 5.")
    assert_equal(pond.get_editor_property("spirit_energy"), 10, "Restore should increase spirit energy by 10.")

    pond.set_editor_property("sacred_pond_water_purity", 98)
    restored, remaining_mana, message = call_restore(pond, 25)
    assert_equal(restored, True, "Restore should succeed near max purity.")
    assert_equal(pond.get_editor_property("sacred_pond_water_purity"), 100, "Purity should cap at 100.")
    if "fully purified" not in message:
        raise RuntimeError(f"Expected fully purified message at cap, got: {message}")

    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)
    save_game.set_editor_property("sacred_pond_water_purity", pond.get_editor_property("sacred_pond_water_purity"))
    save_game.set_editor_property("spirit_energy", pond.get_editor_property("spirit_energy"))
    save_game.set_editor_property("sacred_pond_level", pond.get_editor_property("sacred_pond_level"))
    save_game.set_editor_property("restore_cost", pond.get_editor_property("restore_cost"))
    save_game.set_editor_property("max_water_purity", pond.get_editor_property("max_water_purity"))

    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("Could not save Sacred Pond restore test data.")

    loaded = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded:
        raise RuntimeError("Could not load Sacred Pond restore test data.")

    assert_equal(loaded.get_editor_property("sacred_pond_water_purity"), 100, "Saved purity should load correctly.")
    assert_equal(loaded.get_editor_property("spirit_energy"), 20, "Saved spirit energy should load correctly.")
    assert_equal(loaded.get_editor_property("sacred_pond_level"), 1, "Saved pond level should load correctly.")
    assert_equal(loaded.get_editor_property("restore_cost"), 25, "Saved restore cost should load correctly.")
    assert_equal(loaded.get_editor_property("max_water_purity"), 100, "Saved max purity should load correctly.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Milestone 6 Sacred Pond restore verification passed")


main()

