extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.name = "GameState"
	root.add_child(state)
	state.reset_to_defaults()

	var scene := load("res://ui/ArcaneForgePanel.tscn") as PackedScene
	if scene == null:
		fail("Arcane Forge panel scene should load")
		return

	var panel := scene.instantiate()
	if panel == null:
		fail("Arcane Forge panel should instantiate")
		return

	root.add_child(panel)
	await process_frame

	if not panel.has_signal("closed"):
		fail("Arcane Forge panel should expose closed signal")
		return
	if panel.get_node_or_null("ForgeLevelLabel") == null and not _has_descendant_named(panel, "ForgeLevelLabel"):
		fail("Arcane Forge panel should build a ForgeLevelLabel")
		return

	print("Arcane Forge panel scene load check passed")
	quit(0)


func _has_descendant_named(node: Node, target_name: String) -> bool:
	for child in node.get_children():
		if child.name == target_name:
			return true
		if _has_descendant_named(child, target_name):
			return true
	return false


func fail(message: String) -> void:
	push_error(message)
	quit(1)
