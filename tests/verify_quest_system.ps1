$ErrorActionPreference = "Stop"

function Assert-FileContains {
    param([string]$Path, [string]$Text)
    if (-not (Select-String -Path $Path -Pattern ([regex]::Escape($Text)) -Quiet)) {
        throw "Missing '$Text' in $Path"
    }
}

$state = "scripts/game_state.gd"
$village = "scripts/main_village.gd"
$panel = "scripts/quest_panel.gd"
$scene = "ui/QuestPanel.tscn"

Assert-FileContains $state "signal quests_changed"
Assert-FileContains $state "var quests: Array[Dictionary]"
Assert-FileContains $state '"QuestID"'
Assert-FileContains $state "first_harvest"
Assert-FileContains $state '"QuestTitle"'
Assert-FileContains $state "First Harvest"
Assert-FileContains $state '"QuestGoalType"'
Assert-FileContains $state '"PrerequisiteQuestID"'
Assert-FileContains $state '"CurrentProgress"'
Assert-FileContains $state '"RequiredProgress"'
Assert-FileContains $state '"RewardType"'
Assert-FileContains $state '"RewardAmount"'
Assert-FileContains $state '"IsCompleted"'
Assert-FileContains $state '"IsClaimed"'
Assert-FileContains $state "func add_quest_progress"
Assert-FileContains $state "func record_building_visit"
Assert-FileContains $state "func get_visible_quests"
Assert-FileContains $state "func get_next_guided_quest_id"
Assert-FileContains $state "func is_quest_unlocked"
Assert-FileContains $state "func claim_quest_reward"
Assert-FileContains $state "func has_claimable_quest_rewards"
Assert-FileContains $state '"quests"'

Assert-FileContains $village "QuestPanelScene"
Assert-FileContains $village "_get_claimable_quest_count"
Assert-FileContains $village 'GameState.record_building_visit("Fairy House")'
Assert-FileContains $village 'GameState.record_building_visit("Market Stall")'
Assert-FileContains $village 'GameState.record_building_visit("Arcane Forge")'
Assert-FileContains $village 'GameState.record_building_visit("Ancient Tree")'
Assert-FileContains $village "_open_quests"

Assert-FileContains $scene "QuestPanel"
Assert-FileContains $scene "quest_panel.gd"

Assert-FileContains $panel "Active quests"
Assert-FileContains $panel "GameState.get_visible_quests()"
Assert-FileContains $panel "Claim Reward"
Assert-FileContains $panel "Back"
Assert-FileContains $panel "Quest Complete!"

Write-Output "MysticGrove_Godot Quest System verification passed"
