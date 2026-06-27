extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	game_state.has_completed_onboarding = true
	game_state.first_merge_complete = true
	game_state.has_seen_tutorial = false

	var village: Node = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame

	if village.get_node_or_null("TutorialLayer/Tutorial") != null:
		fail("Main Village should not show the old tutorial after onboarding is complete")

	village.queue_free()
	await process_frame
	print("Main Village tutorial gate behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
