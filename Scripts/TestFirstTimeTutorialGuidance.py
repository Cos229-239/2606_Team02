import unreal

SAVE_BLUEPRINT_PATH = "/Game/Saves/SaveGame_MysticGrove"
SAVE_SLOT = "MysticGrove_SaveSlot"


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


def assert_contains(text, expected, message):
    if expected not in str(text):
        raise RuntimeError(f"{message} Expected text containing {expected!r}, got {text!r}.")


def main():
    save_class = get_generated_class(SAVE_BLUEPRINT_PATH)
    save_game = unreal.GameplayStatics.create_save_game_object(save_class)

    for property_name in ["has_completed_tutorial", "tutorial_step"]:
        try:
            save_game.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 9 missing save property {property_name}.") from exc

    assert_equal(save_game.get_editor_property("has_completed_tutorial"), False, "Tutorial should default to incomplete.")
    assert_equal(save_game.get_editor_property("tutorial_step"), 0, "Tutorial should default to step 0.")

    try:
        hud_class = unreal.MysticHud
    except AttributeError as exc:
        raise RuntimeError("Milestone 9 needs MysticHud exposed to Python.") from exc

    hud_cdo = unreal.get_default_object(hud_class)
    for property_name in ["tutorial_prompt_text", "tutorial_prompt_visible", "tutorial_next_button_visible"]:
        try:
            hud_cdo.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 9 missing HUD property {property_name}.") from exc

    try:
        controller_class = unreal.MysticGrovePlayerController
    except AttributeError as exc:
        raise RuntimeError("Milestone 9 needs MysticGrovePlayerController exposed to Python.") from exc

    controller_cdo = unreal.get_default_object(controller_class)
    for property_name in ["has_completed_tutorial", "tutorial_step"]:
        try:
            controller_cdo.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 9 missing player controller tutorial property {property_name}.") from exc

    try:
        tutorial_widget_class = unreal.MysticTutorialPromptWidget
    except AttributeError as exc:
        raise RuntimeError("Milestone 9 tutorial prompt needs a real clickable MysticTutorialPromptWidget.") from exc

    tutorial_widget_cdo = unreal.get_default_object(tutorial_widget_class)
    for property_name in ["prompt_text", "show_next_button", "on_next_requested", "on_skip_requested"]:
        try:
            tutorial_widget_cdo.get_editor_property(property_name)
        except Exception as exc:
            raise RuntimeError(f"Milestone 9 missing tutorial widget property {property_name}.") from exc

    # Text helper should expose the actual prototype instructions without needing PIE.
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(0), "The grove has lost its magic", "Step 0 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(1), "Tap Flower Grove", "Step 1 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(2), "Wait for Stored Mana", "Step 2 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(3), "Collect Mana", "Step 3 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(4), "Tap Sacred Pond", "Step 4 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(5), "Restore the Pond", "Step 5 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(6), "Tap the Fairy House", "Step 6 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(7), "View Luna", "Step 7 text is wrong.")
    assert_contains(controller_cdo.get_tutorial_prompt_for_step(8), "Tutorial complete", "Step 8 text is wrong.")

    controller_cdo.set_editor_property("has_completed_tutorial", False)
    controller_cdo.set_editor_property("tutorial_step", 0)
    assert_equal(
        controller_cdo.get_tutorial_button_action_for_point(unreal.Vector2D(700.0, 634.0), unreal.Vector2D(1280.0, 720.0)),
        1,
        "Tutorial Next fallback hitbox should work."
    )
    assert_equal(
        controller_cdo.get_tutorial_button_action_for_point(unreal.Vector2D(820.0, 634.0), unreal.Vector2D(1280.0, 720.0)),
        2,
        "Tutorial Skip fallback hitbox should work."
    )
    controller_cdo.set_editor_property("tutorial_step", 1)
    assert_equal(
        controller_cdo.get_tutorial_button_action_for_point(unreal.Vector2D(700.0, 634.0), unreal.Vector2D(1280.0, 720.0)),
        0,
        "Tutorial Next fallback should only be active when Next is visible."
    )

    save_game.set_editor_property("has_completed_tutorial", True)
    save_game.set_editor_property("tutorial_step", 8)
    if not unreal.GameplayStatics.save_game_to_slot(save_game, SAVE_SLOT, 0):
        raise RuntimeError("Could not save tutorial test data.")

    loaded = unreal.GameplayStatics.load_game_from_slot(SAVE_SLOT, 0)
    if not loaded:
        raise RuntimeError("Could not load tutorial test data.")

    assert_equal(loaded.get_editor_property("has_completed_tutorial"), True, "Completed tutorial should persist.")
    assert_equal(loaded.get_editor_property("tutorial_step"), 8, "Tutorial step should persist.")

    unreal.GameplayStatics.delete_game_in_slot(SAVE_SLOT, 0)
    unreal.log("Milestone 9 first-time tutorial verification passed")


main()
