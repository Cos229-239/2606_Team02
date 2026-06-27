extends Node

signal resources_changed
signal flower_grove_changed
signal sacred_pond_changed
signal fairy_house_changed
signal potion_shop_changed
signal market_stall_changed
signal ancient_tree_changed
signal arcane_forge_changed
signal quests_changed
signal save_status_changed(message: String)
signal save_reset

const SAVE_PATH := "user://mystic_grove_save.json"
const FAIRY_AREA_FLOWER_GROVE := "Flower Grove"
const FAIRY_AREA_SACRED_POND := "Sacred Koi Pond"
const FAIRY_AREA_UNASSIGNED := "Unassigned"
const POND_BONUS_NONE := "None"
const POND_BONUS_BLOOMING_WATERS := "Blooming Waters"
const POND_BONUS_MOONLIT_REFLECTION := "Moonlit Reflection"
const POND_BONUS_FAIRY_BLESSING := "Fairy Blessing"
const POND_BONUS_SUN_KOI_GUARDIAN := "Sun Koi Guardian"
const QUEST_GOAL_COLLECT_MANA := "collect_mana"
const QUEST_GOAL_RESTORE_POND := "restore_pond"
const QUEST_GOAL_ASSIGN_FLOWER_FAIRY := "assign_flower_fairy"
const QUEST_GOAL_CRAFT_POTION := "craft_potion"
const QUEST_GOAL_UPGRADE_FLOWER := "upgrade_flower"
const QUEST_GOAL_MARKET_TRADE := "market_trade"
const QUEST_GOAL_RESTORE_TREE := "restore_tree"
const QUEST_GOAL_FORGE_UPGRADE := "forge_upgrade"
const QUEST_REWARD_MANA := "Mana"
const QUEST_REWARD_COINS := "Coins"
const FLOWER_GRID_COLUMNS := 3
const FLOWER_GRID_ROWS := 4
const FLOWER_GRID_SLOT_COUNT := 12
const FLOWER_TIER_EMPTY := 0
const FLOWER_TIER_SEED := 1
const FLOWER_TIER_FLOWER := 2
const FLOWER_TIER_BLOOM := 3
const FLOWER_TIER_RARE_BLOSSOM := 4

var total_mana: int = 0
var total_coins: int = 0
var grove_restoration: int = 15

var flower_grove_level: int = 1
var flower_grove_stored_mana: float = 0.0
var flower_grove_max_stored_mana: int = 100
var flower_grove_base_mana_production_rate: float = 5.0
var flower_grove_fairy_bonus_production: float = 0.0
var flower_grove_upgrade_cost: int = 25
var flower_grove_active_plots: int = 3
var flower_grove_max_plots: int = 6
var flower_grove_plot_unlock_states: Array[bool] = [true, true, true, false, false, false]
var flower_grove_grid_slots: Array[Dictionary] = []

var sacred_pond_water_purity: int = 15
var sacred_pond_spirit_energy: int = 0
var sacred_pond_level: int = 1
var sacred_pond_restore_cost: int = 25
var sacred_pond_base_restore_amount: int = 5
var sacred_pond_fairy_restore_bonus: int = 0
var active_pond_bonus: String = POND_BONUS_NONE
var unlocked_pond_rewards: Array[String] = []
var pond_beauty: int = 0
var pond_decorations: Array[Dictionary] = []
var pond_decoration_slots: Array[String] = []
var last_pond_decoration_message: String = ""

var fairy_house_level: int = 1
var fairy_residents: int = 3
var fairy_max_residents: int = 3
var fairy_workers_active: int = 2
var fairy_current_assignment: String = "Flower Grove"
var fairies: Array[Dictionary] = []
var potion_shop_level: int = 1
var mana_potion_count: int = 0
var potion_mana_cost: int = 25
var potion_base_craft_time: int = 5
var potion_current_craft_time: float = 0.0
var potion_crafting_active: bool = false
var potion_sell_value: int = 50
var potion_shop_upgrade_cost: int = 100
var market_reputation: int = 1
var market_orders_completed: int = 0
var ancient_tree_level: int = 1
var ancient_tree_restore_cost: int = 75
var ancient_tree_claimed_rewards: Array[int] = []
var forge_level: int = 1
var forge_flower_focus_level: int = 0
var forge_potion_gilding_level: int = 0
var forge_pond_resonance_level: int = 0
var quests: Array[Dictionary] = []
var preserve_feedback_once: bool = false
var has_completed_onboarding: bool = false
var first_merge_complete: bool = false
var show_tutorial_after_reset: bool = false
var has_seen_tutorial: bool = false
var tutorial_step: int = 0
var music_volume: float = 0.75
var sfx_volume: float = 0.75

func _ready() -> void:
	if _is_test_save_disabled():
		reset_to_defaults()
		save_status_changed.emit("Test save disabled.")
		return
	load_game()


func _process(delta: float) -> void:
	generate_flower_mana(delta)
	update_potion_crafting(delta)


func generate_flower_mana(delta: float) -> void:
	if delta <= 0.0:
		return

	var old_mana := int(floor(flower_grove_stored_mana))
	flower_grove_stored_mana = min(
		flower_grove_stored_mana + get_flower_production_rate() * delta,
		float(flower_grove_max_stored_mana)
	)

	if int(floor(flower_grove_stored_mana)) != old_mana:
		flower_grove_changed.emit()


func collect_flower_mana() -> int:
	var collected := int(floor(flower_grove_stored_mana))
	if collected <= 0:
		return 0

	total_mana += collected
	flower_grove_stored_mana = 0.0
	add_quest_progress(QUEST_GOAL_COLLECT_MANA, collected)
	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return collected


func upgrade_flower_grove() -> bool:
	if total_mana < flower_grove_upgrade_cost:
		save_status_changed.emit("Not enough mana.")
		return false

	total_mana -= flower_grove_upgrade_cost
	flower_grove_level += 1
	flower_grove_base_mana_production_rate += 2.0
	if flower_grove_level % 2 == 0:
		flower_grove_max_stored_mana += 25
	flower_grove_upgrade_cost = int(ceil(float(flower_grove_upgrade_cost) * 1.5))
	add_quest_progress(QUEST_GOAL_UPGRADE_FLOWER, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return true


func unlock_flower_plot() -> int:
	if flower_grove_active_plots >= flower_grove_max_plots:
		save_status_changed.emit("All plots unlocked.")
		return 0

	var unlock_cost := get_flower_unlock_cost()
	if total_mana < unlock_cost:
		save_status_changed.emit("Not enough mana.")
		return -1

	total_mana -= unlock_cost
	flower_grove_active_plots += 1
	flower_grove_base_mana_production_rate += 2.0
	_sync_plot_unlock_states()
	_sync_flower_grid_unlocks()

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return 1


func get_flower_upgrade_cost() -> int:
	return flower_grove_upgrade_cost


func get_flower_unlock_cost() -> int:
	if flower_grove_active_plots >= flower_grove_max_plots:
		return 0
	var unlock_index := flower_grove_active_plots - 3
	return [50, 100, 200][unlock_index]


func get_flower_base_production_rate() -> float:
	return flower_grove_base_mana_production_rate


func get_flower_fairy_bonus_production() -> float:
	return flower_grove_fairy_bonus_production


func get_flower_production_rate() -> float:
	var total := flower_grove_base_mana_production_rate + flower_grove_fairy_bonus_production
	if is_pond_reward_unlocked(POND_BONUS_BLOOMING_WATERS):
		total *= 1.05
	return total


func get_flower_tier_data(tier: int) -> Dictionary:
	match tier:
		FLOWER_TIER_SEED:
			return {
				"Name": "Seed",
				"Sprite": "res://assets/sprites/environment/blue_bloom.png",
				"ManaValue": 2,
				"ManaProductionRate": 1,
				"MergeTier": 1
			}
		FLOWER_TIER_FLOWER:
			return {
				"Name": "Flower",
				"Sprite": "res://assets/sprites/environment/purple_bloom.png",
				"ManaValue": 5,
				"ManaProductionRate": 3,
				"MergeTier": 2
			}
		FLOWER_TIER_BLOOM:
			return {
				"Name": "Bloom",
				"Sprite": "res://assets/sprites/environment/golden_bloom.png",
				"ManaValue": 12,
				"ManaProductionRate": 8,
				"MergeTier": 3
			}
		FLOWER_TIER_RARE_BLOSSOM:
			return {
				"Name": "Rare Blossom",
				"Sprite": "res://assets/sprites/environment/bloom_lilypad.png",
				"ManaValue": 30,
				"ManaProductionRate": 20,
				"MergeTier": 4
			}
	return {
		"Name": "Empty",
		"Sprite": "",
		"ManaValue": 0,
		"ManaProductionRate": 0,
		"MergeTier": 0
	}


func get_flower_grid_production_rate() -> int:
	var production := 0
	for slot in flower_grove_grid_slots:
		production += int(get_flower_tier_data(int(slot.get("Tier", FLOWER_TIER_EMPTY))).get("ManaProductionRate", 0))
	return production


func get_flower_grid_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= flower_grove_grid_slots.size():
		return {"Tier": FLOWER_TIER_EMPTY, "Locked": true}
	return flower_grove_grid_slots[slot_index]


func is_flower_grid_full() -> bool:
	for slot in flower_grove_grid_slots:
		if not bool(slot.get("Locked", false)) and int(slot.get("Tier", FLOWER_TIER_EMPTY)) == FLOWER_TIER_EMPTY:
			return false
	return true


func plant_seed_in_flower_slot(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= flower_grove_grid_slots.size():
		return -1
	if bool(flower_grove_grid_slots[slot_index].get("Locked", false)):
		return -1
	if int(flower_grove_grid_slots[slot_index].get("Tier", FLOWER_TIER_EMPTY)) != FLOWER_TIER_EMPTY:
		return -1
	flower_grove_grid_slots[slot_index]["Tier"] = FLOWER_TIER_SEED
	flower_grove_base_mana_production_rate += float(get_flower_tier_data(FLOWER_TIER_SEED).get("ManaProductionRate", 1))
	flower_grove_changed.emit()
	save_game()
	return 1


func merge_flower_grid_slots(from_slot: int, to_slot: int) -> Dictionary:
	var result := {
		"Success": false,
		"Message": "Flowers must match to merge.",
		"Reward": 0,
		"NewTier": FLOWER_TIER_EMPTY
	}
	if from_slot == to_slot:
		return result
	if from_slot < 0 or from_slot >= flower_grove_grid_slots.size() or to_slot < 0 or to_slot >= flower_grove_grid_slots.size():
		return result
	if bool(flower_grove_grid_slots[from_slot].get("Locked", false)) or bool(flower_grove_grid_slots[to_slot].get("Locked", false)):
		return result

	var from_tier := int(flower_grove_grid_slots[from_slot].get("Tier", FLOWER_TIER_EMPTY))
	var to_tier := int(flower_grove_grid_slots[to_slot].get("Tier", FLOWER_TIER_EMPTY))
	if from_tier <= FLOWER_TIER_EMPTY or to_tier <= FLOWER_TIER_EMPTY:
		result["Message"] = "Drag matching life together."
		return result
	if from_tier != to_tier:
		return result
	if from_tier >= FLOWER_TIER_RARE_BLOSSOM:
		result["Message"] = "Rare Blossom is max tier."
		return result

	var old_production := int(get_flower_tier_data(from_tier).get("ManaProductionRate", 0)) * 2
	var new_tier := from_tier + 1
	var new_data := get_flower_tier_data(new_tier)
	var new_production := int(new_data.get("ManaProductionRate", 0))
	var reward := int(new_data.get("ManaValue", 0))

	flower_grove_grid_slots[from_slot]["Tier"] = FLOWER_TIER_EMPTY
	flower_grove_grid_slots[to_slot]["Tier"] = new_tier
	flower_grove_base_mana_production_rate += float(new_production - old_production)
	total_mana += reward

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()

	result["Success"] = true
	result["Message"] = "%s created!" % String(new_data.get("Name", "Bloom"))
	result["Reward"] = reward
	result["NewTier"] = new_tier
	return result


func _sync_plot_unlock_states() -> void:
	flower_grove_active_plots = clamp(flower_grove_active_plots, 0, flower_grove_max_plots)
	flower_grove_plot_unlock_states.clear()
	for index in range(flower_grove_max_plots):
		flower_grove_plot_unlock_states.append(index < flower_grove_active_plots)


func _sync_flower_grid_unlocks() -> void:
	if flower_grove_grid_slots.size() != FLOWER_GRID_SLOT_COUNT:
		_reset_flower_grid_to_defaults()
	var unlocked_slots: int = clamp(flower_grove_active_plots * 2, 0, FLOWER_GRID_SLOT_COUNT)
	for index in range(FLOWER_GRID_SLOT_COUNT):
		flower_grove_grid_slots[index]["Locked"] = index >= unlocked_slots


func restore_sacred_pond() -> bool:
	if total_mana < sacred_pond_restore_cost:
		save_status_changed.emit("Not enough mana.")
		return false

	total_mana -= sacred_pond_restore_cost
	sacred_pond_water_purity = min(sacred_pond_water_purity + get_sacred_pond_total_restore_amount(), 100)
	sacred_pond_spirit_energy += 10
	sacred_pond_restore_cost = int(ceil(float(sacred_pond_restore_cost) * 1.25))
	grove_restoration = sacred_pond_water_purity
	update_sacred_pond_level_and_rewards()
	add_quest_progress(QUEST_GOAL_RESTORE_POND, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	save_game()
	return true


func get_sacred_pond_base_restore_amount() -> int:
	return sacred_pond_base_restore_amount


func get_sacred_pond_fairy_restore_bonus() -> int:
	return sacred_pond_fairy_restore_bonus


func get_sacred_pond_total_restore_amount() -> int:
	return sacred_pond_base_restore_amount + sacred_pond_fairy_restore_bonus + get_pond_decoration_restore_bonus()


func get_pond_decoration_restore_bonus() -> int:
	return int(floor(float(pond_beauty) / 10.0))


func get_pond_decoration_slot_name(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= pond_decoration_slots.size():
		return "Auto"
	return pond_decoration_slots[slot_index]


func is_pond_slot_occupied(slot_index: int) -> bool:
	for decoration in pond_decorations:
		if bool(decoration.get("IsPlaced", false)) and int(decoration.get("SlotIndex", -1)) == slot_index:
			return true
	return false


func get_first_empty_pond_decoration_slot() -> int:
	for index in range(pond_decoration_slots.size()):
		if not is_pond_slot_occupied(index):
			return index
	return -1


func place_pond_decoration(decoration_name: String, requested_slot_index: int = -1) -> bool:
	for index in range(pond_decorations.size()):
		if String(pond_decorations[index].get("DecorationName", "")) != decoration_name:
			continue
		if not bool(pond_decorations[index].get("IsUnlocked", true)):
			last_pond_decoration_message = "Decoration locked."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		if bool(pond_decorations[index].get("IsPlaced", false)):
			last_pond_decoration_message = "Decoration already placed."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		var slot_index := requested_slot_index
		if slot_index < 0:
			slot_index = get_first_empty_pond_decoration_slot()
		if slot_index < 0:
			last_pond_decoration_message = "No empty decoration slots."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		if is_pond_slot_occupied(slot_index):
			last_pond_decoration_message = "No empty decoration slots."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		var cost := int(pond_decorations[index].get("CostMana", 0))
		if total_mana < cost:
			last_pond_decoration_message = "Not enough Mana."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		total_mana -= cost
		pond_decorations[index]["IsPlaced"] = true
		pond_decorations[index]["SlotIndex"] = slot_index
		recalculate_pond_beauty()
		last_pond_decoration_message = "Decoration placed!"
		resources_changed.emit()
		sacred_pond_changed.emit()
		save_game()
		save_status_changed.emit(last_pond_decoration_message)
		return true

	last_pond_decoration_message = "Decoration not found."
	save_status_changed.emit(last_pond_decoration_message)
	return false


func remove_pond_decoration(decoration_name: String) -> bool:
	for index in range(pond_decorations.size()):
		if String(pond_decorations[index].get("DecorationName", "")) != decoration_name:
			continue
		if not bool(pond_decorations[index].get("IsPlaced", false)):
			last_pond_decoration_message = "Decoration is not placed."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		pond_decorations[index]["IsPlaced"] = false
		pond_decorations[index]["SlotIndex"] = -1
		recalculate_pond_beauty()
		last_pond_decoration_message = "Decoration removed."
		sacred_pond_changed.emit()
		save_game()
		save_status_changed.emit(last_pond_decoration_message)
		return true
	return false


func recalculate_pond_beauty() -> void:
	pond_beauty = 0
	for decoration in pond_decorations:
		if bool(decoration.get("IsPlaced", false)):
			pond_beauty += int(decoration.get("BeautyValue", 0))


func get_potion_mana_cost() -> int:
	return potion_mana_cost


func get_potion_craft_time() -> int:
	return max(2, potion_base_craft_time - (potion_shop_level - 1))


func get_potion_sell_value() -> int:
	return potion_sell_value


func get_potion_craft_progress() -> float:
	if not potion_crafting_active:
		return 0.0
	var craft_time := float(get_potion_craft_time())
	return clamp((craft_time - potion_current_craft_time) / craft_time, 0.0, 1.0)


func start_mana_potion_craft() -> bool:
	if potion_crafting_active:
		save_status_changed.emit("Potion already crafting.")
		return false
	if total_mana < potion_mana_cost:
		save_status_changed.emit("Not enough Mana.")
		return false

	total_mana -= potion_mana_cost
	potion_current_craft_time = float(get_potion_craft_time())
	potion_crafting_active = true
	resources_changed.emit()
	potion_shop_changed.emit()
	save_game()
	return true


func update_potion_crafting(delta: float) -> void:
	if not potion_crafting_active or delta <= 0.0:
		return

	potion_current_craft_time = max(0.0, potion_current_craft_time - delta)
	if potion_current_craft_time <= 0.0:
		potion_crafting_active = false
		mana_potion_count += 1
		add_quest_progress(QUEST_GOAL_CRAFT_POTION, 1)
		potion_shop_changed.emit()
		save_game()
	else:
		potion_shop_changed.emit()


func sell_mana_potion() -> bool:
	if mana_potion_count <= 0:
		save_status_changed.emit("No potions to sell.")
		return false

	mana_potion_count -= 1
	total_coins += potion_sell_value
	resources_changed.emit()
	potion_shop_changed.emit()
	save_game()
	return true


func upgrade_potion_shop() -> bool:
	if total_coins < potion_shop_upgrade_cost:
		save_status_changed.emit("Not enough Coins.")
		return false

	total_coins -= potion_shop_upgrade_cost
	potion_shop_level += 1
	resources_changed.emit()
	potion_shop_changed.emit()
	save_game()
	return true


func get_market_order_data(order_id: String) -> Dictionary:
	match order_id:
		"mana_bundle":
			return {
				"OrderID": "mana_bundle",
				"Title": "Mana Bundle",
				"CostMana": 25,
				"CostPotions": 0,
				"CostSpirit": 0,
				"RewardCoins": 35,
				"ReputationReward": 1,
				"Description": "Trade gathered Mana for village Coins."
			}
		"potion_crate":
			return {
				"OrderID": "potion_crate",
				"Title": "Potion Crate",
				"CostMana": 0,
				"CostPotions": 1,
				"CostSpirit": 0,
				"RewardCoins": 75,
				"ReputationReward": 1,
				"Description": "Sell a finished Mana Potion to traveling sprites."
			}
		"spirit_contract":
			return {
				"OrderID": "spirit_contract",
				"Title": "Spirit Contract",
				"CostMana": 10,
				"CostPotions": 0,
				"CostSpirit": 10,
				"RewardCoins": 110,
				"ReputationReward": 2,
				"Description": "Bind pond Spirit Energy into a high-value contract."
			}
	return {}


func get_market_orders() -> Array[Dictionary]:
	return [
		get_market_order_data("mana_bundle"),
		get_market_order_data("potion_crate"),
		get_market_order_data("spirit_contract")
	]


func fulfill_market_order(order_id: String) -> Dictionary:
	var order := get_market_order_data(order_id)
	if order.is_empty():
		save_status_changed.emit("Unknown market order.")
		return {"Success": false, "Message": "Unknown market order."}

	var cost_mana := int(order.get("CostMana", 0))
	var cost_potions := int(order.get("CostPotions", 0))
	var cost_spirit := int(order.get("CostSpirit", 0))
	if total_mana < cost_mana:
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}
	if mana_potion_count < cost_potions:
		save_status_changed.emit("Not enough Mana Potions.")
		return {"Success": false, "Message": "Not enough Mana Potions."}
	if sacred_pond_spirit_energy < cost_spirit:
		save_status_changed.emit("Not enough Spirit Energy.")
		return {"Success": false, "Message": "Not enough Spirit Energy."}

	total_mana -= cost_mana
	mana_potion_count -= cost_potions
	sacred_pond_spirit_energy -= cost_spirit
	total_coins += int(order.get("RewardCoins", 0))
	market_orders_completed += 1
	market_reputation += int(order.get("ReputationReward", 1))
	add_quest_progress(QUEST_GOAL_MARKET_TRADE, 1)

	resources_changed.emit()
	market_stall_changed.emit()
	potion_shop_changed.emit()
	sacred_pond_changed.emit()
	save_game()
	var message := "%s fulfilled!" % String(order.get("Title", "Order"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func update_ancient_tree_level() -> void:
	if grove_restoration >= 100:
		ancient_tree_level = 5
	elif grove_restoration >= 75:
		ancient_tree_level = 4
	elif grove_restoration >= 50:
		ancient_tree_level = 3
	elif grove_restoration >= 25:
		ancient_tree_level = 2
	else:
		ancient_tree_level = 1


func restore_ancient_tree() -> Dictionary:
	if grove_restoration >= 100:
		save_status_changed.emit("The Ancient Tree is fully restored.")
		return {"Success": false, "Message": "The Ancient Tree is fully restored."}
	if total_mana < ancient_tree_restore_cost:
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}

	total_mana -= ancient_tree_restore_cost
	grove_restoration = min(100, grove_restoration + 10)
	ancient_tree_restore_cost = int(ceil(float(ancient_tree_restore_cost) * 1.35))
	update_ancient_tree_level()
	add_quest_progress(QUEST_GOAL_RESTORE_TREE, 1)

	resources_changed.emit()
	ancient_tree_changed.emit()
	save_game()
	var message := "Ancient Tree restored to %d%%." % grove_restoration
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func get_ancient_tree_reward_data(level: int) -> Dictionary:
	match level:
		2:
			return {"Level": 2, "Title": "Root Memory", "RewardMana": 25, "RewardCoins": 0}
		3:
			return {"Level": 3, "Title": "Branch Blessing", "RewardMana": 50, "RewardCoins": 40}
		4:
			return {"Level": 4, "Title": "Canopy Promise", "RewardMana": 75, "RewardCoins": 80}
		5:
			return {"Level": 5, "Title": "Heartwood Awakening", "RewardMana": 100, "RewardCoins": 150}
	return {}


func claim_ancient_tree_reward(level: int) -> Dictionary:
	var reward := get_ancient_tree_reward_data(level)
	if reward.is_empty():
		save_status_changed.emit("No reward at that level.")
		return {"Success": false, "Message": "No reward at that level."}
	if ancient_tree_level < level:
		save_status_changed.emit("Restore the Ancient Tree further.")
		return {"Success": false, "Message": "Restore the Ancient Tree further."}
	if ancient_tree_claimed_rewards.has(level):
		save_status_changed.emit("Reward already claimed.")
		return {"Success": false, "Message": "Reward already claimed."}

	ancient_tree_claimed_rewards.append(level)
	total_mana += int(reward.get("RewardMana", 0))
	total_coins += int(reward.get("RewardCoins", 0))
	resources_changed.emit()
	ancient_tree_changed.emit()
	save_game()
	var message := "%s claimed!" % String(reward.get("Title", "Reward"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func get_next_ancient_tree_reward_text() -> String:
	for level in [2, 3, 4, 5]:
		if ancient_tree_claimed_rewards.has(level):
			continue
		var reward_thresholds: Array[int] = [0, 0, 25, 50, 75, 100]
		var threshold: int = reward_thresholds[level]
		if ancient_tree_level >= level:
			return "Level %d reward ready" % level
		return "Level %d reward at %d%% restoration" % [level, threshold]
	return "All Ancient Tree rewards claimed"


func get_forge_upgrade_data(upgrade_id: String) -> Dictionary:
	match upgrade_id:
		"flower_focus":
			return {
				"UpgradeID": "flower_focus",
				"Title": "Flower Focus",
				"Level": forge_flower_focus_level,
				"MaxLevel": 3,
				"CostMana": 100 + forge_flower_focus_level * 75,
				"CostCoins": 50 + forge_flower_focus_level * 50,
				"CostSpirit": 0,
				"Description": "+2 Flower Grove Mana/sec per level."
			}
		"potion_gilding":
			return {
				"UpgradeID": "potion_gilding",
				"Title": "Potion Gilding",
				"Level": forge_potion_gilding_level,
				"MaxLevel": 3,
				"CostMana": 75 + forge_potion_gilding_level * 60,
				"CostCoins": 100 + forge_potion_gilding_level * 65,
				"CostSpirit": 0,
				"Description": "+15 Coins per Mana Potion sale per level."
			}
		"pond_resonance":
			return {
				"UpgradeID": "pond_resonance",
				"Title": "Pond Resonance",
				"Level": forge_pond_resonance_level,
				"MaxLevel": 3,
				"CostMana": 50 + forge_pond_resonance_level * 50,
				"CostCoins": 50 + forge_pond_resonance_level * 50,
				"CostSpirit": 20 + forge_pond_resonance_level * 10,
				"Description": "+2 Sacred Pond restore power per level."
			}
	return {}


func get_forge_upgrades() -> Array[Dictionary]:
	return [
		get_forge_upgrade_data("flower_focus"),
		get_forge_upgrade_data("potion_gilding"),
		get_forge_upgrade_data("pond_resonance")
	]


func purchase_forge_upgrade(upgrade_id: String) -> Dictionary:
	var upgrade := get_forge_upgrade_data(upgrade_id)
	if upgrade.is_empty():
		save_status_changed.emit("Unknown forge upgrade.")
		return {"Success": false, "Message": "Unknown forge upgrade."}

	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	if level >= max_level:
		save_status_changed.emit("Forge upgrade is maxed.")
		return {"Success": false, "Message": "Forge upgrade is maxed."}

	var cost_mana := int(upgrade.get("CostMana", 0))
	var cost_coins := int(upgrade.get("CostCoins", 0))
	var cost_spirit := int(upgrade.get("CostSpirit", 0))
	if total_mana < cost_mana:
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}
	if total_coins < cost_coins:
		save_status_changed.emit("Not enough Coins.")
		return {"Success": false, "Message": "Not enough Coins."}
	if sacred_pond_spirit_energy < cost_spirit:
		save_status_changed.emit("Not enough Spirit Energy.")
		return {"Success": false, "Message": "Not enough Spirit Energy."}

	total_mana -= cost_mana
	total_coins -= cost_coins
	sacred_pond_spirit_energy -= cost_spirit
	if upgrade_id == "flower_focus":
		forge_flower_focus_level += 1
		flower_grove_base_mana_production_rate += 2.0
	elif upgrade_id == "potion_gilding":
		forge_potion_gilding_level += 1
		potion_sell_value += 15
	elif upgrade_id == "pond_resonance":
		forge_pond_resonance_level += 1
		sacred_pond_base_restore_amount += 2
	forge_level = 1 + forge_flower_focus_level + forge_potion_gilding_level + forge_pond_resonance_level
	add_quest_progress(QUEST_GOAL_FORGE_UPGRADE, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	potion_shop_changed.emit()
	sacred_pond_changed.emit()
	arcane_forge_changed.emit()
	save_game()
	var message := "%s forged!" % String(upgrade.get("Title", "Upgrade"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func update_sacred_pond_level_and_rewards() -> void:
	if sacred_pond_water_purity >= 100:
		sacred_pond_level = 5
	elif sacred_pond_water_purity >= 75:
		sacred_pond_level = 4
	elif sacred_pond_water_purity >= 50:
		sacred_pond_level = 3
	elif sacred_pond_water_purity >= 25:
		sacred_pond_level = 2
	else:
		sacred_pond_level = 1

	if sacred_pond_level >= 2:
		_unlock_pond_reward(POND_BONUS_BLOOMING_WATERS)
	if sacred_pond_level >= 3:
		_unlock_pond_reward(POND_BONUS_MOONLIT_REFLECTION)
	if sacred_pond_level >= 4:
		_unlock_pond_reward(POND_BONUS_FAIRY_BLESSING)
	if sacred_pond_level >= 5:
		_unlock_pond_reward(POND_BONUS_SUN_KOI_GUARDIAN)

	active_pond_bonus = _get_highest_active_pond_bonus()
	grove_restoration = sacred_pond_water_purity


func _unlock_pond_reward(reward_name: String) -> void:
	if is_pond_reward_unlocked(reward_name):
		return
	unlocked_pond_rewards.append(reward_name)
	if reward_name == POND_BONUS_MOONLIT_REFLECTION:
		flower_grove_max_stored_mana += 10
	elif reward_name == POND_BONUS_FAIRY_BLESSING:
		fairy_max_residents += 1


func _get_highest_active_pond_bonus() -> String:
	if is_pond_reward_unlocked(POND_BONUS_SUN_KOI_GUARDIAN):
		return POND_BONUS_SUN_KOI_GUARDIAN
	if is_pond_reward_unlocked(POND_BONUS_FAIRY_BLESSING):
		return POND_BONUS_FAIRY_BLESSING
	if is_pond_reward_unlocked(POND_BONUS_MOONLIT_REFLECTION):
		return POND_BONUS_MOONLIT_REFLECTION
	if is_pond_reward_unlocked(POND_BONUS_BLOOMING_WATERS):
		return POND_BONUS_BLOOMING_WATERS
	return POND_BONUS_NONE


func is_pond_reward_unlocked(reward_name: String) -> bool:
	return unlocked_pond_rewards.has(reward_name)


func get_active_pond_bonus_text() -> String:
	if active_pond_bonus == POND_BONUS_BLOOMING_WATERS:
		return "Blooming Waters +5% Flower Production"
	if active_pond_bonus == POND_BONUS_MOONLIT_REFLECTION:
		return "Moonlit Reflection +10 Max Stored Mana"
	if active_pond_bonus == POND_BONUS_FAIRY_BLESSING:
		return "Fairy Blessing +1 Fairy House Capacity"
	if active_pond_bonus == POND_BONUS_SUN_KOI_GUARDIAN:
		return "Sun Koi Guardian Spirit Guardian Placeholder"
	return "None"


func get_next_pond_reward_text() -> String:
	if sacred_pond_water_purity < 25:
		return "Blooming Waters at 25%"
	if sacred_pond_water_purity < 50:
		return "Moonlit Reflection at 50%"
	if sacred_pond_water_purity < 75:
		return "Fairy Blessing at 75%"
	if sacred_pond_water_purity < 100:
		return "Sun Koi Guardian at 100%"
	return "All pond rewards unlocked"


func assign_fairy_to_area(fairy_name: String, area: String) -> String:
	var clean_area := area
	if clean_area == "Sacred Pond":
		clean_area = FAIRY_AREA_SACRED_POND
	if clean_area not in [FAIRY_AREA_FLOWER_GROVE, FAIRY_AREA_SACRED_POND, FAIRY_AREA_UNASSIGNED]:
		return "Unknown assignment."

	for index in range(fairies.size()):
		if fairies[index].get("FairyName", "") == fairy_name and bool(fairies[index].get("IsUnlocked", false)):
			fairies[index]["AssignedArea"] = clean_area
			recalculate_fairy_bonuses()
			resources_changed.emit()
			flower_grove_changed.emit()
			sacred_pond_changed.emit()
			fairy_house_changed.emit()
			if clean_area == FAIRY_AREA_FLOWER_GROVE:
				add_quest_progress(QUEST_GOAL_ASSIGN_FLOWER_FAIRY, 1)
			save_game()
			if clean_area == FAIRY_AREA_FLOWER_GROVE:
				return "%s assigned to Flower Grove" % fairy_name
			if clean_area == FAIRY_AREA_SACRED_POND:
				return "%s assigned to Sacred Pond" % fairy_name
			return "%s is resting" % fairy_name

	return "%s is not available." % fairy_name


func recalculate_fairy_bonuses() -> void:
	flower_grove_fairy_bonus_production = 0.0
	sacred_pond_fairy_restore_bonus = 0
	fairy_residents = 0
	fairy_workers_active = 0
	fairy_current_assignment = FAIRY_AREA_UNASSIGNED

	for fairy in fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		fairy_residents += 1
		var assigned_area := String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
		var work_bonus := float(fairy.get("WorkBonus", 0.0))
		if assigned_area == FAIRY_AREA_FLOWER_GROVE:
			flower_grove_fairy_bonus_production += work_bonus
			fairy_workers_active += 1
			fairy_current_assignment = FAIRY_AREA_FLOWER_GROVE
		elif assigned_area == FAIRY_AREA_SACRED_POND:
			sacred_pond_fairy_restore_bonus += int(ceil(work_bonus))
			fairy_workers_active += 1
			fairy_current_assignment = FAIRY_AREA_SACRED_POND

	fairy_max_residents = max(fairy_max_residents, fairy_residents)


func get_fairy_assigned_area(fairy_name: String) -> String:
	for fairy in fairies:
		if fairy.get("FairyName", "") == fairy_name:
			return String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
	return FAIRY_AREA_UNASSIGNED


func get_fairy_bonus_text(fairy: Dictionary) -> String:
	var assigned_area := String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
	var work_bonus := float(fairy.get("WorkBonus", 0.0))
	if assigned_area == FAIRY_AREA_FLOWER_GROVE:
		return "+%d Mana/sec" % int(work_bonus)
	if assigned_area == FAIRY_AREA_SACRED_POND:
		return "+%d Restore" % int(ceil(work_bonus))
	return "No active bonus"


func _reset_fairies_to_defaults() -> void:
	fairies.clear()
	fairies.append({
		"FairyName": "Luna",
		"FairyLevel": 1,
		"FairyRole": "Gatherer",
		"AssignedArea": FAIRY_AREA_FLOWER_GROVE,
		"WorkBonus": 2.0,
		"IsUnlocked": true
	})
	fairies.append({
		"FairyName": "Pip",
		"FairyLevel": 1,
		"FairyRole": "Pond Keeper",
		"AssignedArea": FAIRY_AREA_SACRED_POND,
		"WorkBonus": 1.0,
		"IsUnlocked": true
	})
	fairies.append({
		"FairyName": "Nim",
		"FairyLevel": 1,
		"FairyRole": "Helper",
		"AssignedArea": FAIRY_AREA_UNASSIGNED,
		"WorkBonus": 1.0,
		"IsUnlocked": true
	})


func _reset_quests_to_defaults() -> void:
	quests.clear()
	quests.append(_make_quest(
		"first_harvest",
		"First Harvest",
		"Collect mana from the Flower Grove.",
		QUEST_GOAL_COLLECT_MANA,
		50,
		QUEST_REWARD_COINS,
		25
	))
	quests.append(_make_quest(
		"restore_waters",
		"Restore the Waters",
		"Use mana to restore the Sacred Koi Pond.",
		QUEST_GOAL_RESTORE_POND,
		1,
		QUEST_REWARD_MANA,
		25
	))
	quests.append(_make_quest(
		"fairy_work",
		"A Fairy's Work",
		"Assign a fairy to the Flower Grove.",
		QUEST_GOAL_ASSIGN_FLOWER_FAIRY,
		1,
		QUEST_REWARD_COINS,
		50
	))
	quests.append(_make_quest(
		"beginner_brewer",
		"Beginner Brewer",
		"Craft your first Mana Potion.",
		QUEST_GOAL_CRAFT_POTION,
		1,
		QUEST_REWARD_COINS,
		50
	))
	quests.append(_make_quest(
		"village_growth",
		"Village Growth",
		"Upgrade the Flower Grove.",
		QUEST_GOAL_UPGRADE_FLOWER,
		1,
		QUEST_REWARD_COINS,
		75
	))
	quests.append(_make_quest(
		"first_trade",
		"First Trade",
		"Fulfill a Market Stall order.",
		QUEST_GOAL_MARKET_TRADE,
		1,
		QUEST_REWARD_COINS,
		60
	))
	quests.append(_make_quest(
		"awaken_roots",
		"Awaken the Roots",
		"Restore the Ancient Tree.",
		QUEST_GOAL_RESTORE_TREE,
		1,
		QUEST_REWARD_MANA,
		75
	))
	quests.append(_make_quest(
		"first_forging",
		"First Forging",
		"Purchase an Arcane Forge upgrade.",
		QUEST_GOAL_FORGE_UPGRADE,
		1,
		QUEST_REWARD_COINS,
		100
	))


func _make_quest(quest_id: String, title: String, description: String, goal_type: String, required_progress: int, reward_type: String, reward_amount: int) -> Dictionary:
	return {
		"QuestID": quest_id,
		"QuestTitle": title,
		"QuestDescription": description,
		"QuestGoalType": goal_type,
		"CurrentProgress": 0,
		"RequiredProgress": required_progress,
		"RewardType": reward_type,
		"RewardAmount": reward_amount,
		"IsCompleted": false,
		"IsClaimed": false
	}


func add_quest_progress(goal_type: String, amount: int) -> void:
	if amount <= 0:
		return
	var changed := false
	var completed_now := false
	for index in range(quests.size()):
		if String(quests[index].get("QuestGoalType", "")) != goal_type:
			continue
		if bool(quests[index].get("IsClaimed", false)):
			continue
		var required := int(quests[index].get("RequiredProgress", 1))
		var current := int(quests[index].get("CurrentProgress", 0))
		var was_completed := bool(quests[index].get("IsCompleted", false))
		current = min(current + amount, required)
		quests[index]["CurrentProgress"] = current
		quests[index]["IsCompleted"] = current >= required
		changed = true
		if not was_completed and bool(quests[index]["IsCompleted"]):
			completed_now = true
	if changed:
		quests_changed.emit()
		if completed_now:
			preserve_feedback_once = true
			save_status_changed.emit("Quest Complete!")


func claim_quest_reward(quest_id: String) -> bool:
	for index in range(quests.size()):
		if String(quests[index].get("QuestID", "")) != quest_id:
			continue
		if not bool(quests[index].get("IsCompleted", false)) or bool(quests[index].get("IsClaimed", false)):
			return false
		var reward_type := String(quests[index].get("RewardType", ""))
		var reward_amount := int(quests[index].get("RewardAmount", 0))
		if reward_type == QUEST_REWARD_MANA:
			total_mana += reward_amount
		elif reward_type == QUEST_REWARD_COINS:
			total_coins += reward_amount
		quests[index]["IsClaimed"] = true
		resources_changed.emit()
		quests_changed.emit()
		save_game()
		return true
	return false


func has_claimable_quest_rewards() -> bool:
	for quest in quests:
		if bool(quest.get("IsCompleted", false)) and not bool(quest.get("IsClaimed", false)):
			return true
	return false


func is_quest_completed(quest_id: String) -> bool:
	for quest in quests:
		if String(quest.get("QuestID", "")) == quest_id:
			return bool(quest.get("IsCompleted", false))
	return false


func is_quest_claimed(quest_id: String) -> bool:
	for quest in quests:
		if String(quest.get("QuestID", "")) == quest_id:
			return bool(quest.get("IsClaimed", false))
	return false


func get_save_data() -> Dictionary:
	return {
		"total_mana": total_mana,
		"total_coins": total_coins,
		"flower_grove_level": flower_grove_level,
		"flower_grove_stored_mana": flower_grove_stored_mana,
		"flower_grove_production_rate": flower_grove_base_mana_production_rate,
		"flower_grove_base_mana_production_rate": flower_grove_base_mana_production_rate,
		"flower_grove_fairy_bonus_production": flower_grove_fairy_bonus_production,
		"flower_grove_max_stored_mana": flower_grove_max_stored_mana,
		"flower_grove_upgrade_cost": flower_grove_upgrade_cost,
		"flower_grove_active_plots": flower_grove_active_plots,
		"flower_grove_max_plots": flower_grove_max_plots,
		"flower_grove_plot_unlock_states": flower_grove_plot_unlock_states,
		"flower_grove_grid_slots": flower_grove_grid_slots,
		"flower_grove_grid_production_rate": get_flower_grid_production_rate(),
		"sacred_pond_water_purity": sacred_pond_water_purity,
		"sacred_pond_spirit_energy": sacred_pond_spirit_energy,
		"sacred_pond_level": sacred_pond_level,
		"sacred_pond_restore_cost": sacred_pond_restore_cost,
		"sacred_pond_base_restore_amount": sacred_pond_base_restore_amount,
		"sacred_pond_fairy_restore_bonus": sacred_pond_fairy_restore_bonus,
		"active_pond_bonus": active_pond_bonus,
		"unlocked_pond_rewards": unlocked_pond_rewards,
		"pond_beauty": pond_beauty,
		"pond_decorations": pond_decorations,
		"pond_decoration_slots": pond_decoration_slots,
		"grove_restoration": grove_restoration,
		"fairy_house_level": fairy_house_level,
		"fairy_residents": fairy_residents,
		"fairy_max_residents": fairy_max_residents,
		"fairy_workers_active": fairy_workers_active,
		"fairies": fairies,
		"potion_shop_level": potion_shop_level,
		"mana_potion_count": mana_potion_count,
		"potion_mana_cost": potion_mana_cost,
		"potion_base_craft_time": potion_base_craft_time,
		"potion_current_craft_time": potion_current_craft_time,
		"potion_crafting_active": potion_crafting_active,
		"potion_sell_value": potion_sell_value,
		"potion_shop_upgrade_cost": potion_shop_upgrade_cost,
		"market_reputation": market_reputation,
		"market_orders_completed": market_orders_completed,
		"ancient_tree_level": ancient_tree_level,
		"ancient_tree_restore_cost": ancient_tree_restore_cost,
		"ancient_tree_claimed_rewards": ancient_tree_claimed_rewards,
		"forge_level": forge_level,
		"forge_flower_focus_level": forge_flower_focus_level,
		"forge_potion_gilding_level": forge_potion_gilding_level,
		"forge_pond_resonance_level": forge_pond_resonance_level,
		"quests": quests,
		"has_completed_onboarding": has_completed_onboarding,
		"first_merge_complete": first_merge_complete,
		"show_tutorial_after_reset": show_tutorial_after_reset,
		"has_seen_tutorial": has_seen_tutorial,
		"tutorial_step": tutorial_step,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}


func apply_save_data(data: Dictionary) -> void:
	total_mana = int(data.get("total_mana", 0))
	total_coins = int(data.get("total_coins", 0))
	flower_grove_level = int(data.get("flower_grove_level", 1))
	flower_grove_stored_mana = float(data.get("flower_grove_stored_mana", 0.0))
	flower_grove_base_mana_production_rate = float(data.get("flower_grove_base_mana_production_rate", data.get("flower_grove_production_rate", 5.0)))
	flower_grove_fairy_bonus_production = float(data.get("flower_grove_fairy_bonus_production", 0.0))
	flower_grove_max_stored_mana = int(data.get("flower_grove_max_stored_mana", 100))
	flower_grove_upgrade_cost = int(data.get("flower_grove_upgrade_cost", 25))
	flower_grove_active_plots = int(data.get("flower_grove_active_plots", 3))
	flower_grove_max_plots = int(data.get("flower_grove_max_plots", 6))
	var saved_plot_states = data.get("flower_grove_plot_unlock_states", [])
	if saved_plot_states is Array and saved_plot_states.size() == flower_grove_max_plots:
		flower_grove_plot_unlock_states.clear()
		for value in saved_plot_states:
			flower_grove_plot_unlock_states.append(bool(value))
		flower_grove_active_plots = flower_grove_plot_unlock_states.count(true)
	else:
		_sync_plot_unlock_states()
	var saved_grid_slots = data.get("flower_grove_grid_slots", [])
	if saved_grid_slots is Array and saved_grid_slots.size() == FLOWER_GRID_SLOT_COUNT:
		flower_grove_grid_slots.clear()
		for saved_slot in saved_grid_slots:
			if saved_slot is Dictionary:
				flower_grove_grid_slots.append({
					"Tier": int(saved_slot.get("Tier", FLOWER_TIER_EMPTY)),
					"Locked": bool(saved_slot.get("Locked", false))
				})
			else:
				flower_grove_grid_slots.append({"Tier": FLOWER_TIER_EMPTY, "Locked": false})
		_sync_flower_grid_unlocks()
	else:
		_reset_flower_grid_to_defaults()
	sacred_pond_water_purity = int(data.get("sacred_pond_water_purity", 15))
	sacred_pond_spirit_energy = int(data.get("sacred_pond_spirit_energy", 0))
	sacred_pond_level = int(data.get("sacred_pond_level", 1))
	sacred_pond_restore_cost = int(data.get("sacred_pond_restore_cost", 25))
	sacred_pond_base_restore_amount = int(data.get("sacred_pond_base_restore_amount", 5))
	active_pond_bonus = String(data.get("active_pond_bonus", POND_BONUS_NONE))
	var saved_pond_rewards = data.get("unlocked_pond_rewards", [])
	unlocked_pond_rewards.clear()
	if saved_pond_rewards is Array:
		for reward in saved_pond_rewards:
			unlocked_pond_rewards.append(String(reward))
	_reset_pond_decorations_to_defaults()
	var saved_decorations = data.get("pond_decorations", [])
	if saved_decorations is Array and saved_decorations.size() > 0:
		pond_decorations.clear()
		for saved_decoration in saved_decorations:
			if saved_decoration is Dictionary:
				pond_decorations.append({
					"DecorationName": String(saved_decoration.get("DecorationName", "")),
					"CostMana": int(saved_decoration.get("CostMana", 0)),
					"BeautyValue": int(saved_decoration.get("BeautyValue", 0)),
					"IsUnlocked": bool(saved_decoration.get("IsUnlocked", true)),
					"IsPlaced": bool(saved_decoration.get("IsPlaced", false)),
					"SlotIndex": int(saved_decoration.get("SlotIndex", -1))
				})
	var saved_slots = data.get("pond_decoration_slots", [])
	if saved_slots is Array and saved_slots.size() > 0:
		pond_decoration_slots.clear()
		for slot_name in saved_slots:
			pond_decoration_slots.append(String(slot_name))
	recalculate_pond_beauty()
	grove_restoration = int(data.get("grove_restoration", sacred_pond_water_purity))
	fairy_house_level = int(data.get("fairy_house_level", 1))
	fairy_residents = int(data.get("fairy_residents", 3))
	fairy_max_residents = int(data.get("fairy_max_residents", 3))
	fairy_workers_active = int(data.get("fairy_workers_active", 2))
	var saved_fairies = data.get("fairies", [])
	if saved_fairies is Array and saved_fairies.size() > 0:
		fairies.clear()
		for saved_fairy in saved_fairies:
			if saved_fairy is Dictionary:
				fairies.append({
					"FairyName": String(saved_fairy.get("FairyName", "")),
					"FairyLevel": int(saved_fairy.get("FairyLevel", 1)),
					"FairyRole": String(saved_fairy.get("FairyRole", "Helper")),
					"AssignedArea": String(saved_fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED)),
					"WorkBonus": float(saved_fairy.get("WorkBonus", 1.0)),
					"IsUnlocked": bool(saved_fairy.get("IsUnlocked", true))
				})
	else:
		_reset_fairies_to_defaults()
	recalculate_fairy_bonuses()
	update_sacred_pond_level_and_rewards()
	potion_shop_level = int(data.get("potion_shop_level", 1))
	mana_potion_count = int(data.get("mana_potion_count", 0))
	potion_mana_cost = int(data.get("potion_mana_cost", 25))
	potion_base_craft_time = int(data.get("potion_base_craft_time", 5))
	potion_current_craft_time = float(data.get("potion_current_craft_time", 0.0))
	potion_crafting_active = bool(data.get("potion_crafting_active", false))
	potion_sell_value = int(data.get("potion_sell_value", 50))
	potion_shop_upgrade_cost = int(data.get("potion_shop_upgrade_cost", 100))
	market_reputation = int(data.get("market_reputation", 1))
	market_orders_completed = int(data.get("market_orders_completed", 0))
	ancient_tree_level = int(data.get("ancient_tree_level", 1))
	ancient_tree_restore_cost = int(data.get("ancient_tree_restore_cost", 75))
	ancient_tree_claimed_rewards.clear()
	var saved_tree_rewards = data.get("ancient_tree_claimed_rewards", [])
	if saved_tree_rewards is Array:
		for reward_level in saved_tree_rewards:
			ancient_tree_claimed_rewards.append(int(reward_level))
	forge_level = int(data.get("forge_level", 1))
	forge_flower_focus_level = int(data.get("forge_flower_focus_level", 0))
	forge_potion_gilding_level = int(data.get("forge_potion_gilding_level", 0))
	forge_pond_resonance_level = int(data.get("forge_pond_resonance_level", 0))
	var saved_quests = data.get("quests", [])
	if saved_quests is Array and saved_quests.size() > 0:
		quests.clear()
		for saved_quest in saved_quests:
			if saved_quest is Dictionary:
				quests.append({
					"QuestID": String(saved_quest.get("QuestID", "")),
					"QuestTitle": String(saved_quest.get("QuestTitle", "")),
					"QuestDescription": String(saved_quest.get("QuestDescription", "")),
					"QuestGoalType": String(saved_quest.get("QuestGoalType", "")),
					"CurrentProgress": int(saved_quest.get("CurrentProgress", 0)),
					"RequiredProgress": int(saved_quest.get("RequiredProgress", 1)),
					"RewardType": String(saved_quest.get("RewardType", QUEST_REWARD_COINS)),
					"RewardAmount": int(saved_quest.get("RewardAmount", 0)),
					"IsCompleted": bool(saved_quest.get("IsCompleted", false)),
					"IsClaimed": bool(saved_quest.get("IsClaimed", false))
				})
	else:
		_reset_quests_to_defaults()
	has_completed_onboarding = bool(data.get("has_completed_onboarding", true))
	first_merge_complete = bool(data.get("first_merge_complete", has_completed_onboarding))
	show_tutorial_after_reset = bool(data.get("show_tutorial_after_reset", false))
	has_seen_tutorial = bool(data.get("has_seen_tutorial", has_completed_onboarding))
	tutorial_step = int(data.get("tutorial_step", 0))
	music_volume = clamp(float(data.get("music_volume", 0.75)), 0.0, 1.0)
	sfx_volume = clamp(float(data.get("sfx_volume", 0.75)), 0.0, 1.0)

	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	potion_shop_changed.emit()
	market_stall_changed.emit()
	ancient_tree_changed.emit()
	arcane_forge_changed.emit()
	quests_changed.emit()


func save_game() -> void:
	if _is_test_save_disabled():
		if preserve_feedback_once:
			preserve_feedback_once = false
			return
		save_status_changed.emit("Test save skipped.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_status_changed.emit("Save failed.")
		return

	file.store_string(JSON.stringify(get_save_data()))
	if preserve_feedback_once:
		preserve_feedback_once = false
		return
	save_status_changed.emit("Game saved.")


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	reset_to_defaults()
	show_tutorial_after_reset = true
	save_reset.emit()
	save_status_changed.emit("Save reset.")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		reset_to_defaults()
		save_status_changed.emit("New game started.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		reset_to_defaults()
		save_status_changed.emit("Load failed.")
		return

	var save_text := file.get_as_text()
	if save_text.strip_edges().is_empty():
		reset_to_defaults()
		save_status_changed.emit("Save data reset.")
		return
	var parser := JSON.new()
	if parser.parse(save_text) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		reset_to_defaults()
		save_status_changed.emit("Save data reset.")
		return

	apply_save_data(parser.data)
	save_status_changed.emit("Game loaded.")


func _is_test_save_disabled() -> bool:
	return OS.get_cmdline_user_args().has("--no-save")


func reset_to_defaults() -> void:
	total_mana = 0
	total_coins = 0
	grove_restoration = 15
	flower_grove_level = 1
	flower_grove_stored_mana = 0.0
	flower_grove_max_stored_mana = 100
	flower_grove_base_mana_production_rate = 5.0
	flower_grove_fairy_bonus_production = 0.0
	flower_grove_upgrade_cost = 25
	flower_grove_active_plots = 3
	flower_grove_max_plots = 6
	_sync_plot_unlock_states()
	_reset_flower_grid_to_defaults()
	sacred_pond_water_purity = 15
	sacred_pond_spirit_energy = 0
	sacred_pond_level = 1
	sacred_pond_restore_cost = 25
	sacred_pond_base_restore_amount = 5
	sacred_pond_fairy_restore_bonus = 0
	active_pond_bonus = POND_BONUS_NONE
	unlocked_pond_rewards.clear()
	_reset_pond_decorations_to_defaults()
	fairy_house_level = 1
	fairy_residents = 3
	fairy_max_residents = 3
	fairy_workers_active = 2
	fairy_current_assignment = FAIRY_AREA_FLOWER_GROVE
	_reset_fairies_to_defaults()
	recalculate_fairy_bonuses()
	potion_shop_level = 1
	mana_potion_count = 0
	potion_mana_cost = 25
	potion_base_craft_time = 5
	potion_current_craft_time = 0.0
	potion_crafting_active = false
	potion_sell_value = 50
	potion_shop_upgrade_cost = 100
	market_reputation = 1
	market_orders_completed = 0
	ancient_tree_level = 1
	ancient_tree_restore_cost = 75
	ancient_tree_claimed_rewards.clear()
	forge_level = 1
	forge_flower_focus_level = 0
	forge_potion_gilding_level = 0
	forge_pond_resonance_level = 0
	_reset_quests_to_defaults()
	has_completed_onboarding = false
	first_merge_complete = false
	show_tutorial_after_reset = false
	has_seen_tutorial = false
	tutorial_step = 0
	music_volume = 0.75
	sfx_volume = 0.75
	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	potion_shop_changed.emit()
	market_stall_changed.emit()
	ancient_tree_changed.emit()
	arcane_forge_changed.emit()
	quests_changed.emit()


func mark_tutorial_seen(step: int = 4) -> void:
	show_tutorial_after_reset = false
	has_seen_tutorial = true
	tutorial_step = step
	save_game()


func complete_onboarding_merge() -> void:
	if first_merge_complete:
		return
	first_merge_complete = true
	has_completed_onboarding = true
	if show_tutorial_after_reset:
		has_seen_tutorial = false
		tutorial_step = 0
	else:
		has_seen_tutorial = true
		tutorial_step = 4
	total_mana += 10
	grove_restoration = max(grove_restoration, 5)
	resources_changed.emit()
	save_game()


func _reset_pond_decorations_to_defaults() -> void:
	pond_decoration_slots = [
		"Top Left",
		"Top Right",
		"Bottom Left",
		"Bottom Right",
		"Center Left",
		"Center Right"
	]
	pond_decorations.clear()
	pond_decorations.append(_make_pond_decoration("Moon Lantern", 25, 5))
	pond_decorations.append(_make_pond_decoration("Spirit Stone", 40, 8))
	pond_decorations.append(_make_pond_decoration("Bloom Lilypad", 30, 6))
	pond_decorations.append(_make_pond_decoration("Sacred Bridge", 75, 12))
	recalculate_pond_beauty()


func _reset_flower_grid_to_defaults() -> void:
	flower_grove_grid_slots.clear()
	for index in range(FLOWER_GRID_SLOT_COUNT):
		var tier := FLOWER_TIER_EMPTY
		if index == 0 or index == 1:
			tier = FLOWER_TIER_SEED
		elif index == 2:
			tier = FLOWER_TIER_FLOWER
		flower_grove_grid_slots.append({
			"Tier": tier,
			"Locked": index >= flower_grove_active_plots * 2
		})


func _make_pond_decoration(decoration_name: String, cost_mana: int, beauty_value: int) -> Dictionary:
	return {
		"DecorationName": decoration_name,
		"CostMana": cost_mana,
		"BeautyValue": beauty_value,
		"IsUnlocked": true,
		"IsPlaced": false,
		"SlotIndex": -1
	}


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	save_game()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	save_game()
