import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def assert_close(actual, expected, message):
    if abs(float(actual) - float(expected)) > 0.01:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def main():
    level_subsystem = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    level_subsystem.load_level(LEVEL_PATH)

    flower_grove = find_actor("Flower Grove")
    if not flower_grove:
        raise RuntimeError("Missing Flower Grove actor.")

    required_properties = [
        "stored_mana",
        "max_stored_mana",
        "mana_production_rate",
        "flower_grove_level",
    ]
    for property_name in required_properties:
        try:
            flower_grove.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Flower Grove is missing property {property_name}.") from exc

    flower_grove.set_editor_property("stored_mana", 0.0)
    assert_equal(flower_grove.get_editor_property("max_stored_mana"), 100, "MaxStoredMana default is wrong.")
    assert_close(flower_grove.get_editor_property("mana_production_rate"), 5.0, "ManaProductionRate default is wrong.")
    assert_equal(flower_grove.get_editor_property("flower_grove_level"), 1, "FlowerGroveLevel default is wrong.")

    flower_grove.generate_mana_for_seconds(3.0)
    assert_close(flower_grove.get_editor_property("stored_mana"), 15.0, "Flower Grove should generate 15 mana after 3 seconds.")

    flower_grove.generate_mana_for_seconds(100.0)
    assert_close(flower_grove.get_editor_property("stored_mana"), 100.0, "StoredMana should cap at MaxStoredMana.")

    collected = flower_grove.collect_stored_mana()
    assert_equal(collected, 100, "CollectStoredMana should return the stored amount.")
    assert_close(flower_grove.get_editor_property("stored_mana"), 0.0, "StoredMana should reset after collection.")

    unreal.log("Flower Grove mana loop verification passed.")


main()
