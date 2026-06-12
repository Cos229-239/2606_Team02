import unreal

LEVEL_PATH = "/Game/Maps/MAP_EtherwoodVillage"

REQUIRED_ACTORS = [
    "Etherwood Dirt Path Fairy To Flower",
    "Etherwood Dirt Path Fairy To Pond",
    "Etherwood Dirt Path Flower To Pond",
    "Flower Grove Label",
    "Fairy House Label",
    "Sacred Koi Pond Label",
    "Flower Grove Bloom Label 01",
    "Flower Grove Bloom Label 02",
    "Flower Grove Bloom Label 03",
]

AREA_LABELS = {"Flower Grove Label", "Fairy House Label", "Sacred Koi Pond Label"}
FLOWER_LABELS = {"Flower Grove Bloom Label 01", "Flower Grove Bloom Label 02", "Flower Grove Bloom Label 03"}


def find_actor(label):
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()
    for actor in actors:
        if actor.get_actor_label() == label:
            return actor
    return None


def main():
    unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).load_level(LEVEL_PATH)
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()

    missing = [label for label in REQUIRED_ACTORS if not find_actor(label)]
    if missing:
        raise RuntimeError("Missing readability actors: " + ", ".join(missing))

    ground = find_actor("Etherwood Village Ground")
    if not ground:
        raise RuntimeError("Missing Etherwood Village Ground.")

    shadow_labels = [
        actor.get_actor_label()
        for actor in actors
        if actor.get_actor_label().endswith(" Shadow")
    ]
    if shadow_labels:
        raise RuntimeError("Duplicate shadow labels still exist: " + ", ".join(shadow_labels))

    area_label_counts = {label: 0 for label in AREA_LABELS}
    flower_label_counts = {label: 0 for label in FLOWER_LABELS}
    extra_flower_labels = []
    for actor in actors:
        label = actor.get_actor_label()
        if label in area_label_counts:
            area_label_counts[label] += 1
        if label in flower_label_counts:
            flower_label_counts[label] += 1
        if label.startswith("Flower Grove Bloom Label ") and label not in FLOWER_LABELS and not label.endswith(" Backing"):
            extra_flower_labels.append(label)

    duplicate_area_labels = [label for label, count in area_label_counts.items() if count != 1]
    duplicate_flower_labels = [label for label, count in flower_label_counts.items() if count != 1]
    if duplicate_area_labels:
        raise RuntimeError("Area label count is not exactly one: " + ", ".join(duplicate_area_labels))
    if duplicate_flower_labels:
        raise RuntimeError("Flower label count is not exactly one: " + ", ".join(duplicate_flower_labels))
    if extra_flower_labels:
        raise RuntimeError("Extra flower labels still exist: " + ", ".join(extra_flower_labels))

    for label in AREA_LABELS:
        actor = find_actor(label)
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if not component:
            raise RuntimeError(f"{label} should exist as a hidden HUD anchor.")

    for label in FLOWER_LABELS:
        actor = find_actor(label)
        component = actor.get_component_by_class(unreal.TextRenderComponent)
        if not component:
            raise RuntimeError(f"{label} should exist as a hidden HUD anchor.")

    unreal.log("Week 1 readability verification passed.")


main()
