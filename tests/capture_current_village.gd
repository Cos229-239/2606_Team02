extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	GameState.has_seen_tutorial = true
	var village = load("res://scenes/MainVillage.tscn").instantiate()
	root.add_child(village)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png("user://mystic_grove_current_screenshot.png")
	print(OS.get_user_data_dir().path_join("mystic_grove_current_screenshot.png"))
	quit(0)
