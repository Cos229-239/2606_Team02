extends PanelContainer

signal closed

var quest_list: VBoxContainer
var feedback_label: Label


func _ready() -> void:
	_build_panel()
	GameState.quests_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	self_modulate = Color(0.015, 0.02, 0.045, 0.94)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 44)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Active quests"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	layout.add_child(title)

	quest_list = VBoxContainer.new()
	quest_list.add_theme_constant_override("separation", 14)
	layout.add_child(quest_list)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 30)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	feedback_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(feedback_label)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(320, 76)
	back_button.add_theme_font_size_override("font_size", 28)
	back_button.pressed.connect(_on_back_pressed)
	layout.add_child(back_button)


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	for quest in GameState.quests:
		if bool(quest.get("IsClaimed", false)):
			continue
		quest_list.add_child(_make_quest_card(quest))


func _make_quest_card(quest: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.self_modulate = Color(0.03, 0.035, 0.06, 0.88)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var current := int(quest.get("CurrentProgress", 0))
	var required := int(quest.get("RequiredProgress", 1))
	var reward_text := "%d %s" % [int(quest.get("RewardAmount", 0)), String(quest.get("RewardType", ""))]
	var description := Label.new()
	description.text = (
		"%s\n%s\nProgress: %d / %d\nReward: %s"
		% [
			String(quest.get("QuestTitle", "Quest")),
			String(quest.get("QuestDescription", "")),
			current,
			required,
			reward_text
		]
	)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 24)
	description.add_theme_color_override("font_color", Color.WHITE)
	description.add_theme_color_override("font_shadow_color", Color.BLACK)
	description.add_theme_constant_override("shadow_offset_x", 2)
	description.add_theme_constant_override("shadow_offset_y", 2)
	layout.add_child(description)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(860, 34)
	progress.max_value = required
	progress.value = current
	layout.add_child(progress)

	var claim_button := Button.new()
	claim_button.text = "Claim Reward"
	claim_button.custom_minimum_size = Vector2(260, 58)
	claim_button.add_theme_font_size_override("font_size", 22)
	claim_button.disabled = not bool(quest.get("IsCompleted", false))
	var quest_id := String(quest.get("QuestID", ""))
	claim_button.pressed.connect(func() -> void:
		if GameState.claim_quest_reward(quest_id):
			feedback_label.text = "Quest Complete! Reward claimed."
			_refresh()
	)
	layout.add_child(claim_button)

	return card


func _on_back_pressed() -> void:
	GameState.save_game()
	closed.emit()
