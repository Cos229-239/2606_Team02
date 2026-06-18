extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	for method_name in [
		"get_market_trade_mana_cost",
		"get_market_trade_coin_reward",
		"get_market_order_target",
		"get_market_upgrade_cost_coins",
		"get_market_storage_upgrade_cost_coins",
		"fulfill_market_trade",
		"upgrade_market_stall",
		"upgrade_market_storage"
	]:
		if not state.has_method(method_name):
			fail("GameState should expose %s" % method_name)
			return

	if state.market_stall_level != 1:
		fail("Expected Market Stall level 1 default")
	if state.market_reputation != 0:
		fail("Expected zero market reputation default")
	if state.market_orders_completed != 0:
		fail("Expected zero completed orders default")
	if state.market_storage_capacity != 3:
		fail("Expected starting storage capacity 3")
	if state.get_market_trade_mana_cost() != 25:
		fail("Expected starting trade cost 25 mana")
	if state.get_market_trade_coin_reward() != 35:
		fail("Expected starting trade reward 35 coins")
	if state.get_market_order_target() != 3:
		fail("Expected starting order target 3")
	if state.get_market_upgrade_cost_coins() != 100:
		fail("Expected starting stall upgrade cost 100 coins")

	if state.fulfill_market_trade():
		fail("Trade should fail without enough mana")
	state.total_mana = 25
	if not state.fulfill_market_trade():
		fail("Trade should succeed with enough mana")
	if state.total_mana != 0:
		fail("Trade should spend mana")
	if state.total_coins != 35:
		fail("Trade should award coins")
	if state.market_orders_completed != 1:
		fail("Trade should complete one order")
	if state.market_reputation != 2:
		fail("Trade should raise reputation")

	state.total_coins = state.get_market_upgrade_cost_coins()
	if not state.upgrade_market_stall():
		fail("Market upgrade should succeed with enough coins")
	if state.market_stall_level != 2:
		fail("Market upgrade should raise level")
	if state.get_market_trade_coin_reward() != 45:
		fail("Level 2 market should improve trade rewards")

	state.total_coins = state.get_market_storage_upgrade_cost_coins()
	if not state.upgrade_market_storage():
		fail("Storage upgrade should succeed with enough coins")
	if state.market_storage_capacity != 5:
		fail("Storage upgrade should add two slots")

	var data: Dictionary = state.get_save_data()
	if not data.has("market_stall_level"):
		fail("Save data should include market level")
	if not data.has("market_reputation"):
		fail("Save data should include reputation")
	if not data.has("market_storage_capacity"):
		fail("Save data should include storage capacity")

	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.market_stall_level != 2:
		fail("Loaded market level should persist")
	if loaded_state.market_orders_completed != 1:
		fail("Loaded completed orders should persist")
	if loaded_state.market_storage_capacity != 5:
		fail("Loaded storage capacity should persist")

	print("Market Stall behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
