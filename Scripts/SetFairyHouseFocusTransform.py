import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def main():
    unreal.EditorLevelLibrary.load_level(LEVEL_PATH)

    house = find_actor("Fairy House")
    if not house:
        raise RuntimeError("Missing Fairy House actor.")

    focus_target = find_actor("Fairy House Focus Target")
    if not focus_target:
        focus_target = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.Actor,
            unreal.Vector(300.0, -470.0, 390.0),
            unreal.Rotator(0.0, -30.0, 50.0),
        )
        focus_target.set_actor_label("Fairy House Focus Target")

    focus_target.set_actor_location(unreal.Vector(300.0, -470.0, 390.0), False, False)
    focus_target.set_actor_rotation(unreal.Rotator(0.0, -30.0, 50.0), False)
    focus_target.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
    focus_target.set_is_temporarily_hidden_in_editor(True)

    house.set_editor_property("zoom_target", focus_target)
    house.set_editor_property("zoom_offset", unreal.Vector(0.0, 0.0, 0.0))

    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).save_current_level()
    unreal.log("Fairy House focus target transform set to Location 300,-470,390 and Rotation 0,-30,50.")


main()
