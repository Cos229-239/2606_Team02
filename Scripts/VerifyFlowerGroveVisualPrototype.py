import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"

REQUIRED_ACTORS = [
    "Flower Grove",
    "Flower Grove Focus Target",
    "Flower Grove Plot 01",
    "Flower Grove Plot 02",
    "Flower Grove Plot 03",
    "Flower Grove Bloom Label 01",
    "Flower Grove Bloom Label 02",
    "Flower Grove Bloom Label 03",
    "Flower Grove Mana Flower Light 01",
    "Flower Grove Mana Flower Light 02",
    "Flower Grove Mana Flower Light 03",
    "Flower Grove Lantern Post 01",
    "Flower Grove Lantern Glow 01",
    "Flower Grove Path Stone 01",
    "Flower Grove Mushroom Stem 01",
    "Flower Grove Wildflower Edge 01",
]


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def main():
    unreal.EditorLevelLibrary.load_level(LEVEL_PATH)

    missing = [label for label in REQUIRED_ACTORS if not find_actor(label)]
    if missing:
        raise RuntimeError("Missing Flower Grove visual actors: " + ", ".join(missing))

    grove = find_actor("Flower Grove")
    focus_target = find_actor("Flower Grove Focus Target")
    if grove.get_editor_property("zoom_target") != focus_target:
        raise RuntimeError("Flower Grove is not using Flower Grove Focus Target.")

    unreal.log("Flower Grove visual prototype verified.")


main()
