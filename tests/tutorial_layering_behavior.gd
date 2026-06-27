extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return

	game_state.reset_to_defaults()
	var village: Node = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame

	var tutorial: Node = village.get_node_or_null("TutorialLayer/Tutorial")
	if tutorial == null:
		fail("Tutorial should be visible for a fresh village")
		return

	var tutorial_layer := tutorial.get_parent() as CanvasLayer
	if tutorial_layer == null:
		fail("Tutorial should be parented to a CanvasLayer")
		return
	if tutorial_layer.layer <= village.bottom_nav_layer.layer:
		fail("Tutorial layer should render above bottom navigation")
		return

	village.queue_free()
	await process_frame
	print("Tutorial layering behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
