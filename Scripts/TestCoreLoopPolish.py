import unreal


MAP_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def assert_equal(actual, expected, message):
    if actual != expected:
        raise RuntimeError(f"{message} Expected {expected}, got {actual}.")


def assert_contains(text, expected, message):
    if expected not in str(text):
        raise RuntimeError(f"{message} Expected text containing {expected!r}, got {text!r}.")


def find_actor(label):
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in subsystem.get_all_level_actors():
        if actor.get_actor_label() == label:
            return actor
    return None


def main():
    unreal.EditorLoadingAndSavingUtils.load_map(MAP_PATH)

    try:
        hud_class = unreal.MysticHud
    except AttributeError as exc:
        raise RuntimeError("Core loop polish needs MysticHud exposed to Python.") from exc

    hud_cdo = unreal.get_default_object(hud_class)
    for property_name in ["grove_restoration_percent", "button_flash_visible"]:
        try:
            hud_cdo.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"HUD missing core loop polish property {property_name}.") from exc

    try:
        controller_class = unreal.MysticGrovePlayerController
    except AttributeError as exc:
        raise RuntimeError("Core loop polish needs MysticGrovePlayerController exposed to Python.") from exc

    controller_cdo = unreal.get_default_object(controller_class)
    assert_contains(
        controller_cdo.get_tutorial_prompt_for_step(0),
        "The grove has lost its magic",
        "First launch tutorial message should explain the core loop."
    )
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(1), "Tap Flower Grove", "Step 1 prompt should be direct.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(3), "Collect Mana", "Step 2 action prompt should mention Collect Mana.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(4), "Tap Sacred Pond", "Step 3 prompt should mention Sacred Pond.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(5), "Restore the Pond", "Step 4 prompt should mention Restore the Pond.")

    for function_name in ["get_grove_restoration_percent", "refresh_grove_restoration_hud", "update_grove_restoration_visuals"]:
        if not hasattr(controller_cdo, function_name):
            raise RuntimeError(f"Player controller missing {function_name}.")

    try:
        fairy_loop_class = unreal.MysticFairyLoopActor
    except AttributeError as exc:
        raise RuntimeError("Core loop polish needs a MysticFairyLoopActor class.") from exc

    fairy_loop_cdo = unreal.get_default_object(fairy_loop_class)
    for property_name in ["fairy_house_label", "flower_grove_label", "sacred_pond_label", "move_speed"]:
        try:
            fairy_loop_cdo.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Fairy loop actor missing property {property_name}.") from exc

    required_actors = [
        "Core Loop Extra Flowers 25",
        "Core Loop Pond Glow 50",
        "Core Loop Fairy Lights 75",
        "Core Loop Ancient Tree Glow 100",
        "Luna Fairy Movement Loop",
    ]
    missing = [label for label in required_actors if not find_actor(label)]
    if missing:
        raise RuntimeError("Missing core loop polish actors: " + ", ".join(missing))

    unreal.log("Core loop polish verification passed")


main()
