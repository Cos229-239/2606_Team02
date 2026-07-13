extends SceneTree

var failed_any := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		quit(1)
		return
	game_state.reset_to_defaults()
	game_state.total_mana = 250
	game_state.total_coins = 250
	game_state.sacred_pond_spirit_energy = 40
	game_state.mana_potion_count = 1

	for scene_path in [
		"res://ui/SacredPondPanel.tscn",
		"res://ui/PondDecoratePanel.tscn",
		"res://ui/PotionShopPanel.tscn",
		"res://ui/MarketStallPanel.tscn",
		"res://ui/AncientTreePanel.tscn",
		"res://ui/ArcaneForgePanel.tscn"
	]:
		var scene: PackedScene = load(scene_path)
		if scene == null:
			fail("Could not load %s" % scene_path)
			continue
		var panel := scene.instantiate()
		get_root().add_child(panel)
		await process_frame
		if not panel.has_signal("closed"):
			fail("%s should expose closed signal" % scene_path)
		if panel.get_child_count() <= 0:
			fail("%s should build visible UI children" % scene_path)
		panel.queue_free()
		await process_frame

	if failed_any:
		quit(1)
		return
	print("Building panel scene-load check passed")
	quit(0)


func fail(message: String) -> void:
	failed_any = true
	push_error(message)
