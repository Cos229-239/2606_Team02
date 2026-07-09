extends SceneTree

func _init() -> void:
	var sound_manager_scene := load("res://scripts/sound_manager.gd")
	assert(sound_manager_scene != null, "SoundManager script should load.")
	var sound_manager: Node = sound_manager_scene.new()
	root.add_child(sound_manager)
	await process_frame

	assert(AudioServer.get_bus_index("Music") != -1, "Music bus should exist.")
	assert(AudioServer.get_bus_index("SFX") != -1, "SFX bus should exist.")

	var music_stream := load("res://assets/audio/music/main_village_music.mp3")
	assert(music_stream != null, "Main village music should load.")
	var click_stream := load("res://assets/audio/sfx/click1.wav")
	assert(click_stream != null, "Click SFX should load.")

	sound_manager.play_music(sound_manager.TRACK_MAIN_VILLAGE)
	await process_frame
	assert(sound_manager.music_player.playing, "Music player should be playing.")

	sound_manager.play_click()
	await process_frame
	var sfx_players := 0
	for child in sound_manager.get_children():
		if child is AudioStreamPlayer and child != sound_manager.music_player and child != sound_manager.moment_player:
			sfx_players += 1
	assert(sfx_players > 0, "Playing click should create an SFX player.")

	print("Audio system behavior check passed")
	quit()
