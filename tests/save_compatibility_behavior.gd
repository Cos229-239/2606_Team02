extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.apply_save_data({
		"total_mana": 42,
		"flower_grove_production_rate": 9.0,
		"mana_potion_count": 2,
		"potion_crafting_active": true,
		"potion_crafting_recipe_id": "removed_recipe",
		"potion_inventory": {
			"removed_recipe": 99
		},
		"forge_level": 1,
		"forge_flower_focus_level": 1,
		"forge_potion_gilding_level": 1,
		"forge_pond_resonance_level": 1,
		"quests": [
			{
				"QuestID": "first_harvest",
				"QuestTitle": "Old First Harvest",
				"QuestDescription": "Old description",
				"QuestGoalType": "collect_mana",
				"CurrentProgress": 50,
				"RequiredProgress": 50,
				"RewardType": "Coins",
				"RewardAmount": 25,
				"IsCompleted": true,
				"IsClaimed": true
			},
			{
				"QuestID": "legacy_festival",
				"QuestTitle": "Legacy Festival",
				"QuestDescription": "Quest from an older branch.",
				"QuestGoalType": "legacy_goal",
				"CurrentProgress": 7,
				"RequiredProgress": 5,
				"RewardType": "Coins",
				"RewardAmount": 10,
				"IsCompleted": false,
				"IsClaimed": false
			}
		]
	})

	if state.total_mana != 42:
		fail("Basic resource values should load from partial saves")
	if int(state.flower_grove_base_mana_production_rate) != 9:
		fail("Legacy flower_grove_production_rate should migrate")
	if state.get_potion_count("mana_potion") != 2:
		fail("Legacy mana_potion_count should migrate into potion inventory")
	if state.get_potion_count("removed_recipe") != 0:
		fail("Unknown potion recipes should not load into inventory")
	if state.potion_crafting_active:
		fail("Crafting should stop when the saved recipe no longer exists")
	if state.potion_crafting_recipe_id != "mana_potion":
		fail("Invalid crafting recipe should fall back to mana potion")
	if state.forge_level != 4:
		fail("Forge level should derive from loaded upgrade levels")
	if state.inventory_notes.is_empty():
		fail("Missing inventory notes should receive a default note")

	if not state.is_quest_claimed("first_harvest"):
		fail("Saved quest claim state should persist")
	if not _has_quest(state, "first_trade"):
		fail("New Market Stall quest should be present after loading old quest saves")
	if not _has_quest(state, "awaken_roots"):
		fail("New Ancient Tree quest should be present after loading old quest saves")
	if not _has_quest(state, "first_forging"):
		fail("New Arcane Forge quest should be present after loading old quest saves")
	if not _has_quest(state, "legacy_festival"):
		fail("Unknown legacy quests should be preserved")
	if not state.is_quest_completed("legacy_festival"):
		fail("Legacy quest progress should be clamped and completed when progress exceeds the requirement")

	print("Save compatibility behavior check passed")
	quit(0)


func _has_quest(state: Node, quest_id: String) -> bool:
	for quest in state.quests:
		if String(quest.get("QuestID", "")) == quest_id:
			return true
	return false


func fail(message: String) -> void:
	push_error(message)
	quit(1)
