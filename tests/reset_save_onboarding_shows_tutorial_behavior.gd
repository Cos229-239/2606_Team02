extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return

	game_state.reset_save()
	game_state.complete_onboarding_merge()

	var village: Node = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame

	if village.get_node_or_null("TutorialLayer/Tutorial") == null:
		fail("Tutorial should show after resetting save and completing onboarding")
		return

	village.queue_free()
	await process_frame
	print("Reset save onboarding tutorial behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
