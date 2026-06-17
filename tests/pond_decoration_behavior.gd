extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.pond_beauty != 0:
		fail("Pond beauty should start at 0")
	if state.get_pond_decoration_restore_bonus() != 0:
		fail("Decoration bonus should start at 0")
	if state.pond_decorations.size() != 4:
		fail("Expected four starting pond decorations")
	if state.pond_decoration_slots.size() != 6:
		fail("Expected six preset decoration slots")

	state.total_mana = 25
	if not state.place_pond_decoration("Moon Lantern", 0):
		fail("Moon Lantern should place with enough mana")
	if state.total_mana != 0:
		fail("Moon Lantern should spend 25 mana")
	if state.pond_beauty != 5:
		fail("Moon Lantern should add 5 beauty")
	if state.get_pond_decoration_restore_bonus() != 0:
		fail("5 beauty should not add restore bonus yet")
	if not state.is_pond_slot_occupied(0):
		fail("Slot 0 should be occupied")

	state.total_mana = 40
	if not state.place_pond_decoration("Spirit Stone", 1):
		fail("Spirit Stone should place with enough mana")
	if state.pond_beauty != 13:
		fail("Two decorations should total 13 beauty")
	if state.get_pond_decoration_restore_bonus() != 1:
		fail("13 beauty should add +1 restore bonus")
	if state.get_sacred_pond_total_restore_amount() != 7:
		fail("Default Pip total restore should include +1 decoration bonus")

	state.total_mana = 0
	if state.place_pond_decoration("Bloom Lilypad", 2):
		fail("Placement should fail without mana")
	if state.last_pond_decoration_message != "Not enough Mana.":
		fail("Expected not enough mana message")

	state.total_mana = 999
	state.place_pond_decoration("Bloom Lilypad", 2)
	state.place_pond_decoration("Sacred Bridge", 3)
	if state.place_pond_decoration("Moon Lantern", 4):
		fail("Already placed decoration should not place twice")

	if not state.remove_pond_decoration("Moon Lantern"):
		fail("Remove should clear placed decoration")
	if state.is_pond_slot_occupied(0):
		fail("Slot should be empty after removal")

	var data: Dictionary = state.get_save_data()
	if not data.has("pond_beauty"):
		fail("Save data should include pond beauty")
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.pond_beauty != state.pond_beauty:
		fail("Loaded pond beauty should persist")
	if loaded_state.get_pond_decoration_restore_bonus() != state.get_pond_decoration_restore_bonus():
		fail("Loaded decoration bonus should persist")

	print("Pond decoration behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
