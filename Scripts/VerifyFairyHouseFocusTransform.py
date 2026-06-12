import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def near(value, expected, tolerance=0.1):
    return abs(value - expected) <= tolerance


def main():
    unreal.EditorLevelLibrary.load_level(LEVEL_PATH)

    focus_target = find_actor("Fairy House Focus Target")
    if not focus_target:
        raise RuntimeError("Missing Fairy House Focus Target.")

    location = focus_target.get_actor_location()
    rotation = focus_target.get_actor_rotation()

    if not (
        near(location.x, 300.0)
        and near(location.y, -470.0)
        and near(location.z, 390.0)
        and near(rotation.roll, 0.0)
        and near(rotation.pitch, -30.0)
        and near(rotation.yaw, 50.0)
    ):
        raise RuntimeError(
            "Fairy House Focus Target has unexpected transform: "
            f"Location {location}, Rotation {rotation}"
        )

    unreal.log("Fairy House Focus Target transform verified.")


main()
