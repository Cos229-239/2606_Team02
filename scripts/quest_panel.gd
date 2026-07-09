extends PanelContainer

signal closed

var quest_list: VBoxContainer
var summary_label: Label
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

	var title := _make_label("Active quests", 46, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	summary_label = _make_label("", 24, Color("#fff2d6"))
	summary_label.name = "QuestSummaryLabel"
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(summary_label)

	var quest_scroll := ScrollContainer.new()
	quest_scroll.name = "QuestScrollContainer"
	quest_scroll.custom_minimum_size = Vector2(940, 1420)
	quest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(quest_scroll)

	quest_list = VBoxContainer.new()
	quest_list.add_theme_constant_override("separation", 14)
	quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_scroll.add_child(quest_list)

	feedback_label = _make_label("", 30, Color("#f5d66f"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)

	var back_button := _make_button("Back")
	back_button.pressed.connect(_on_back_pressed)
	layout.add_child(back_button)


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	var active_quests: Array[Dictionary] = []
	var claimable_count := 0
	var in_progress_count := 0
	for quest in GameState.quests:
		if bool(quest.get("IsClaimed", false)):
			continue
		active_quests.append(quest)
		if bool(quest.get("IsCompleted", false)):
			claimable_count += 1
		else:
			in_progress_count += 1

	active_quests.sort_custom(_sort_quests_for_display)
	if summary_label:
		summary_label.text = "%d ready to claim - %d in progress" % [claimable_count, in_progress_count]

	if active_quests.is_empty():
		quest_list.add_child(_make_empty_state())
		return

	for quest in active_quests:
		quest_list.add_child(_make_quest_card(quest))


func _sort_quests_for_display(a: Dictionary, b: Dictionary) -> bool:
	var a_completed := bool(a.get("IsCompleted", false))
	var b_completed := bool(b.get("IsCompleted", false))
	if a_completed != b_completed:
		return a_completed
	var a_required: int = max(1, int(a.get("RequiredProgress", 1)))
	var b_required: int = max(1, int(b.get("RequiredProgress", 1)))
	var a_progress: float = float(a.get("CurrentProgress", 0)) / float(a_required)
	var b_progress: float = float(b.get("CurrentProgress", 0)) / float(b_required)
	if not is_equal_approx(a_progress, b_progress):
		return a_progress > b_progress
	return String(a.get("QuestTitle", "")) < String(b.get("QuestTitle", ""))


func _make_quest_card(quest: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.9), Color("#b99245"), 2, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var current := int(quest.get("CurrentProgress", 0))
	var required := int(quest.get("RequiredProgress", 1))
	var reward_text := "%d %s" % [int(quest.get("RewardAmount", 0)), String(quest.get("RewardType", ""))]
	var is_completed := bool(quest.get("IsCompleted", false))
	card.name = "QuestCard_%s" % String(quest.get("QuestID", "quest"))
	card.add_theme_stylebox_override("panel", _make_quest_card_style(is_completed))

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)

	var title := _make_label(String(quest.get("QuestTitle", "Quest")), 28, Color("#fff2a8"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)

	header.add_child(_make_status_pill("Ready" if is_completed else "In progress", is_completed))

	var desc := _make_label(String(quest.get("QuestDescription", "")), 22, Color("#e8dfca"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(desc)

	layout.add_child(_make_label("Progress: %d / %d" % [current, required], 22, Color("#f5d66f")))
	layout.add_child(_make_label("Reward: %s" % reward_text, 22, Color("#f5d66f")))

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(860, 34)
	progress.max_value = required
	progress.value = current
	progress.show_percentage = false
	layout.add_child(progress)

	var claim_button := _make_button("Claim Reward" if is_completed else "Keep Going")
	claim_button.name = "ClaimButton_%s" % String(quest.get("QuestID", "quest"))
	claim_button.custom_minimum_size = Vector2(260, 58)
	claim_button.disabled = not is_completed
	var quest_id := String(quest.get("QuestID", ""))
	claim_button.pressed.connect(func() -> void:
		SoundManager.play_collect()
		if GameState.claim_quest_reward(quest_id):
			feedback_label.text = "Quest Complete! Reward claimed."
			_refresh()
	)
	layout.add_child(claim_button)

	return card


func _make_empty_state() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "QuestEmptyState"
	card.add_theme_stylebox_override("panel", _make_style(Color(0.025, 0.03, 0.045, 0.9), Color("#b99245"), 2, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)

	var label := _make_label("All quests claimed. Keep restoring the grove for future goals.", 24, Color("#fff2d6"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)
	return card


func _make_status_pill(text: String, claimable: bool) -> Label:
	var pill := _make_label(text, 20, Color("#102018") if claimable else Color("#fff2d6"))
	pill.name = "QuestStatus_%s" % text.replace(" ", "")
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.custom_minimum_size = Vector2(156, 44)
	pill.add_theme_stylebox_override(
		"normal",
		_make_style(
			Color("#8ef0a6", 0.94) if claimable else Color("#1b243a", 0.94),
			Color("#f5d66f") if claimable else Color("#5b6f99"),
			2,
			8
		)
	)
	return pill


func _make_quest_card_style(claimable: bool) -> StyleBoxFlat:
	return _make_style(
		Color(0.04, 0.052, 0.05, 0.94) if claimable else Color(0.03, 0.035, 0.055, 0.9),
		Color("#8ef0a6") if claimable else Color("#b99245"),
		3 if claimable else 2,
		10
	)


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 74)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()
