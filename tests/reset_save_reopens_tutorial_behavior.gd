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
	game_state.has_seen_tutorial = true

	var village: Node = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame

	if village.get_node_or_null("Tutorial") != null:
		fail("Tutorial should start hidden for a completed save")
		return

	game_state.reset_save()
	await process_frame

	if game_state.has_seen_tutorial:
		fail("Reset save should mark tutorial unseen")
		return
	if village.get_node_or_null("Tutorial") == null:
		fail("Reset save should show the tutorial again in the active village")
		return

	village.queue_free()
	await process_frame
	print("Reset save tutorial behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
