extends Node

const TRACK_MAIN_VILLAGE := "res://assets/audio/music/main_village_music.mp3"
const TRACK_ABANDONED_NOOK := "res://assets/audio/music/abandoned_nook_music.mp3"

const SFX_CLICK := "res://assets/audio/sfx/click1.wav"
const SFX_MOUSE_CLICK := "res://assets/audio/sfx/mouseclick1.wav"
const SFX_MOUSE_RELEASE := "res://assets/audio/sfx/mouserelease1.wav"
const SFX_SWITCH := "res://assets/audio/sfx/switch1.wav"
const SFX_MERGE := "res://assets/audio/sfx/planting_sfx.mp3"
const SFX_COLLECT := "res://assets/audio/sfx/collecting_ammo.wav"
const SFX_INVALID := "res://assets/audio/sfx/invalid_sfx.wav"
const SFX_FIRST_MERGE := "res://assets/audio/sfx/first_merge_sfx.mp3"

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var music_player: AudioStreamPlayer
var moment_player: AudioStreamPlayer
var current_track: String = ""
var first_merge_played: bool = false


func _ready() -> void:
	_setup_buses()
	_setup_music_player()
	_setup_moment_player()
	_apply_volumes()


func _setup_buses() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)
		AudioServer.set_bus_send(idx, "Master")

	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, SFX_BUS)
		AudioServer.set_bus_send(idx, "Master")


func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)


func _setup_moment_player() -> void:
	moment_player = AudioStreamPlayer.new()
	moment_player.bus = MUSIC_BUS
	add_child(moment_player)


func _apply_volumes() -> void:
	var game_state := _get_game_state()
	set_music_volume(float(game_state.get("music_volume")) if game_state else 0.75)
	set_sfx_volume(float(game_state.get("sfx_volume")) if game_state else 0.75)


func set_music_volume(linear: float) -> void:
	var db := linear_to_db(linear) if linear > 0.0 else -80.0
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)


func set_sfx_volume(linear: float) -> void:
	var db := linear_to_db(linear) if linear > 0.0 else -80.0
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)


func play_music(track_path: String) -> void:
	if current_track == track_path and music_player.playing:
		return
	current_track = track_path
	var stream := load(track_path)
	if stream == null:
		push_error("SoundManager: could not load track: " + track_path)
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	current_track = ""


func play_first_merge_moment() -> void:
	if first_merge_played:
		return
	first_merge_played = true
	var stream := load(SFX_FIRST_MERGE)
	if stream == null:
		push_error("SoundManager: could not load first merge sfx: " + SFX_FIRST_MERGE)
		return
	moment_player.stream = stream
	moment_player.play()


func stop_moment() -> void:
	moment_player.stop()


func play_sfx(sfx_path: String) -> void:
	var stream := load(sfx_path)
	if stream == null:
		push_error("SoundManager: could not load sfx: " + sfx_path)
		return
	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_click() -> void:
	play_sfx(SFX_CLICK)


func play_mouse_click() -> void:
	play_sfx(SFX_MOUSE_CLICK)


func play_mouse_release() -> void:
	play_sfx(SFX_MOUSE_RELEASE)


func play_switch() -> void:
	play_sfx(SFX_SWITCH)


func play_merge() -> void:
	play_sfx(SFX_MERGE)


func play_collect() -> void:
	play_sfx(SFX_COLLECT)


func play_invalid() -> void:
	play_sfx(SFX_INVALID)


func _get_game_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameState")
