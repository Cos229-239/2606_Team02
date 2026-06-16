#include "MysticGrovePlayerController.h"

#include "EngineUtils.h"
#include "InputCoreTypes.h"
#include "Blueprint/UserWidget.h"
#include "UObject/ConstructorHelpers.h"
#include "TimerManager.h"
#include "Engine/TextRenderActor.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "MysticBuildingInteractable.h"
#include "MysticBuildingScreenWidget.h"
#include "MysticCameraManager.h"
#include "MysticGroveSaveGame.h"
#include "MysticHud.h"
#include "MysticStartScreenWidget.h"
#include "MysticTutorialPromptWidget.h"
#include "Sound/SoundBase.h"

namespace
{
const FString MysticGroveSaveSlotName = TEXT("MysticGrove_SaveSlot");

bool ActorLabelStartsWith(const AActor* Actor, const TCHAR* Prefix)
{
#if WITH_EDITOR
	return Actor && Actor->GetActorLabel().StartsWith(Prefix);
#else
	return false;
#endif
}

bool IsSacredPondVisualActor(const AActor* Actor)
{
	return ActorLabelStartsWith(Actor, TEXT("Sacred Pond Stone "))
		|| ActorLabelStartsWith(Actor, TEXT("Sacred Pond Lily "))
		|| ActorLabelStartsWith(Actor, TEXT("Sacred Pond Koi "))
		|| ActorLabelStartsWith(Actor, TEXT("Sacred Pond Lantern "))
		|| ActorLabelStartsWith(Actor, TEXT("Sacred Pond Waterfall "))
		|| ActorLabelStartsWith(Actor, TEXT("Sacred Pond Lantern Light "));
}

bool IsFairyHouseVisualActor(const AActor* Actor)
{
	return ActorLabelStartsWith(Actor, TEXT("Fairy Cottage "))
		|| ActorLabelStartsWith(Actor, TEXT("Fairy House Path "))
		|| ActorLabelStartsWith(Actor, TEXT("Fairy House Fence "))
		|| ActorLabelStartsWith(Actor, TEXT("Fairy House Mushroom "))
		|| ActorLabelStartsWith(Actor, TEXT("Fairy House Flower "))
		|| ActorLabelStartsWith(Actor, TEXT("Fairy House Light "));
}

bool IsFlowerGroveVisualActor(const AActor* Actor)
{
	return ActorLabelStartsWith(Actor, TEXT("Flower Grove Garden "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Plot "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Fence "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Lantern "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Path "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Mana Flower "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Mushroom "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Wildflower "))
		|| ActorLabelStartsWith(Actor, TEXT("Flower Grove Bloom Label "));
}

bool ShouldHideForFocusedView(const AActor* Actor, const AMysticBuildingInteractable* FocusedBuilding)
{
	if (!Actor || !FocusedBuilding)
	{
		return false;
	}

	if (FocusedBuilding->BuildingType != EMysticBuildingType::SacredPond && IsSacredPondVisualActor(Actor))
	{
		return true;
	}

	if (FocusedBuilding->BuildingType != EMysticBuildingType::FairyHouse && IsFairyHouseVisualActor(Actor))
	{
		return true;
	}

	if (FocusedBuilding->BuildingType != EMysticBuildingType::FlowerGrove && IsFlowerGroveVisualActor(Actor))
	{
		return true;
	}

	return false;
}

FText GetPlaceholderStatsText(const AMysticBuildingInteractable* Building)
{
	if (!Building)
	{
		return FText::FromString(TEXT("Placeholder stats"));
	}

	switch (Building->BuildingType)
	{
	case EMysticBuildingType::SacredPond:
		return FText::FromString(FString::Printf(
			TEXT("Heart of the Grove\n\nWater Purity: %d / %d\nRestore Amount: +%d\nSpirit Energy: %d\nPond Level: %d\nSpirit Guardians: 0 / 3"),
			Building->SacredPondWaterPurity,
			Building->MaxWaterPurity,
			Building->BaseRestorePurityAmount + Building->FairyRestorePurityBonus,
			Building->SpiritEnergy,
			Building->SacredPondLevel
		));
	case EMysticBuildingType::FlowerGrove:
		return FText::FromString(TEXT("Mana Production: +5/sec\nStored Mana: 0 / 100"));
	case EMysticBuildingType::FairyHouse:
		return FText::FromString(FString::Printf(
			TEXT("Residents: %d / 3\nWorkers Active: %d\n\nFairy Workers:\n%s\nLevel %d\nCurrent Assignment: %s\nBonus: +%d"),
			Building->FairyResidents,
			Building->FairyWorkersActive,
			*Building->FairyName,
			Building->FairyLevel,
			*Building->FairyAssignedTask,
			FMath::FloorToInt(Building->FairyWorkBonus)
		));
	default:
		return FText::Format(
			FText::FromString(TEXT("Workers Assigned: 0\nResource Output: 0 / min\nUpgrade Level: 1\n\n{0} gameplay will be added later.")),
			Building->DisplayName
		);
	}
}

FText GetBuildingScreenTitle(const AMysticBuildingInteractable* Building)
{
	if (!Building)
	{
		return FText::FromString(TEXT("Building"));
	}

	if (Building->BuildingType == EMysticBuildingType::FairyHouse)
	{
		return FText::FromString(FString::Printf(TEXT("Fairy House\nLevel %d"), Building->FairyHouseLevel));
	}

	if (Building->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		return FText::FromString(FString::Printf(TEXT("Flower Grove\nLevel %d"), Building->FlowerGroveLevel));
	}

	return Building->DisplayName;
}

void GetActionLabels(const AMysticBuildingInteractable* Building, FText& OutFirstAction, FText& OutSecondAction, FText& OutThirdAction)
{
	OutFirstAction = FText::FromString(Building && Building->BuildingType == EMysticBuildingType::SacredPond ? FString::Printf(TEXT("Restore - %d Mana"), Building->RestoreCost) : TEXT("Restore"));
	OutSecondAction = FText::FromString(TEXT("Decorate"));
	OutThirdAction = FText::GetEmpty();

	if (!Building)
	{
		return;
	}

	if (Building->BuildingType == EMysticBuildingType::FairyHouse)
	{
		OutFirstAction = FText::FromString(TEXT("Assign Luna"));
		OutSecondAction = FText::FromString(TEXT("Upgrade House"));
	}

	if (Building->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		OutFirstAction = FText::FromString(TEXT("Collect Mana"));
		OutSecondAction = FText::FromString(TEXT("Upgrade Flower"));
		OutThirdAction = Building->ActivePlots >= Building->MaxPlots ? FText::GetEmpty() : FText::FromString(TEXT("Unlock Plot"));
	}
}
}

AMysticGrovePlayerController::AMysticGrovePlayerController()
{
	static ConstructorHelpers::FObjectFinder<USoundBase> PlaceholderClickSound(TEXT("/Engine/EngineSounds/1kSineTonePing.1kSineTonePing"));
	if (PlaceholderClickSound.Succeeded())
	{
		ButtonClickSound = PlaceholderClickSound.Object;
		CollectManaSound = PlaceholderClickSound.Object;
		RestorePondSound = PlaceholderClickSound.Object;
		UpgradeFlowerSound = PlaceholderClickSound.Object;
		BackButtonSound = PlaceholderClickSound.Object;
	}
}

FString AMysticGrovePlayerController::GetTutorialPromptForStep(int32 Step) const
{
	switch (Step)
	{
	case 0:
		return TEXT("The grove has lost its magic. Grow flowers to collect mana, then use mana to restore the Sacred Pond.");
	case 1:
		return TEXT("Step 1: Tap Flower Grove.");
	case 2:
		return TEXT("Step 2: Wait for Stored Mana to increase.");
	case 3:
		return TEXT("Step 2: Collect Mana.");
	case 4:
		return TEXT("Step 3: Tap Sacred Pond.");
	case 5:
		return TEXT("Step 4: Restore the Pond.");
	case 6:
		return TEXT("Tap the Fairy House.");
	case 7:
		return TEXT("View Luna's assignment.");
	case 8:
		return TEXT("Tutorial complete.");
	default:
		return TEXT("Tutorial complete.");
	}
}

int32 AMysticGrovePlayerController::GetTutorialButtonActionForPoint(const FVector2D& ScreenPosition, const FVector2D& ViewportSize) const
{
	if (bHasCompletedTutorial || ViewportSize.X <= 0.0f || ViewportSize.Y <= 0.0f)
	{
		return 0;
	}

	const float PanelWidth = FMath::Min(560.0f, ViewportSize.X - 48.0f);
	const float PanelHeight = 132.0f;
	const float PanelX = (ViewportSize.X - PanelWidth) * 0.5f;
	const float PanelY = ViewportSize.Y - PanelHeight - 36.0f;
	const float ButtonWidth = 112.0f;
	const float ButtonHeight = 42.0f;
	const float ButtonY = PanelY + PanelHeight - 16.0f - ButtonHeight;
	const float SkipX = PanelX + PanelWidth - 20.0f - ButtonWidth;
	const float NextX = SkipX - 10.0f - ButtonWidth;

	auto IsInside = [&ScreenPosition](float X, float Y, float Width, float Height)
	{
		return ScreenPosition.X >= X && ScreenPosition.X <= X + Width
			&& ScreenPosition.Y >= Y && ScreenPosition.Y <= Y + Height;
	};

	if (ShouldShowTutorialNextButton() && IsInside(NextX, ButtonY, ButtonWidth, ButtonHeight))
	{
		return 1;
	}

	if (IsInside(SkipX, ButtonY, ButtonWidth, ButtonHeight))
	{
		return 2;
	}

	return 0;
}

bool AMysticGrovePlayerController::ShouldShowTutorialNextButton() const
{
	return !bHasCompletedTutorial && (TutorialStep == 0 || TutorialStep == 8);
}

void AMysticGrovePlayerController::RefreshTutorialPrompt()
{
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetTutorialPrompt(GetTutorialPromptForStep(TutorialStep), false, false);
	}

	if (bHasCompletedTutorial)
	{
		HideTutorialPromptWidget();
		return;
	}

	ShowTutorialPromptWidget();
	if (CurrentTutorialPrompt)
	{
		CurrentTutorialPrompt->SetPrompt(GetTutorialPromptForStep(TutorialStep), ShouldShowTutorialNextButton());
	}
}

void AMysticGrovePlayerController::SetTutorialStep(int32 NewStep)
{
	if (bHasCompletedTutorial)
	{
		RefreshTutorialPrompt();
		return;
	}

	TutorialStep = FMath::Clamp(NewStep, 0, 8);
	RefreshTutorialPrompt();
	SaveMysticGroveGame();
}

void AMysticGrovePlayerController::AdvanceTutorialFromAction(const FString& ActionName)
{
	if (bHasCompletedTutorial)
	{
		return;
	}

	if (TutorialStep == 1 && ActionName == TEXT("OpenFlowerGrove"))
	{
		SetTutorialStep(2);
		return;
	}

	if (TutorialStep == 3 && ActionName == TEXT("CollectMana"))
	{
		SetTutorialStep(4);
		return;
	}

	if (TutorialStep == 4 && ActionName == TEXT("OpenSacredPond"))
	{
		SetTutorialStep(5);
		return;
	}

	if (TutorialStep == 5 && ActionName == TEXT("RestorePond"))
	{
		SetTutorialStep(6);
		return;
	}

	if (TutorialStep == 6 && ActionName == TEXT("OpenFairyHouse"))
	{
		SetTutorialStep(7);
		return;
	}

	if (TutorialStep == 7 && ActionName == TEXT("ViewLunaAssignment"))
	{
		SetTutorialStep(8);
	}
}

void AMysticGrovePlayerController::SkipTutorial()
{
	bHasCompletedTutorial = true;
	TutorialStep = 8;
	RefreshTutorialPrompt();
	SaveMysticGroveGame();
}

void AMysticGrovePlayerController::CompleteTutorial()
{
	bHasCompletedTutorial = true;
	TutorialStep = 8;
	RefreshTutorialPrompt();
	SaveMysticGroveGame();
}

bool AMysticGrovePlayerController::HandleTutorialButtonPress(const FVector2D& ScreenPosition)
{
	if (!CurrentTutorialPrompt || bHasCompletedTutorial)
	{
		return false;
	}

	int32 ViewportX = 0;
	int32 ViewportY = 0;
	GetViewportSize(ViewportX, ViewportY);

	switch (GetTutorialButtonActionForPoint(ScreenPosition, FVector2D(static_cast<float>(ViewportX), static_cast<float>(ViewportY))))
	{
	case 1:
		HandleTutorialNextRequested();
		return true;
	case 2:
		HandleTutorialSkipRequested();
		return true;
	default:
		return false;
	}
}

void AMysticGrovePlayerController::ShowDemoFeedback(const FString& FeedbackText, float DurationSeconds)
{
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->ShowDemoFeedback(FeedbackText, DurationSeconds);
	}
}

void AMysticGrovePlayerController::ShowButtonFlash(const FString& FlashText)
{
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->ShowButtonFlash(FlashText);
	}
}

void AMysticGrovePlayerController::PlayDemoSound(USoundBase* Sound) const
{
	if (Sound)
	{
		UGameplayStatics::PlaySound2D(GetWorld(), Sound, 0.65f);
	}
}

void AMysticGrovePlayerController::PlayFromStartScreen()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Play"));
	LoadMysticGroveGame();
	UpdateFairyAssignmentBonuses();
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();
	RefreshTutorialPrompt();
	HideStartScreen();

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetMana(TotalMana);
	}

	FInputModeGameAndUI InputMode;
	InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
	SetInputMode(InputMode);
	bShowMouseCursor = true;
}

void AMysticGrovePlayerController::QuitMysticGrove()
{
	PlayDemoSound(ButtonClickSound);
	UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, true);
}

FString AMysticGrovePlayerController::GetWeek1DemoStateSummary() const
{
	return TEXT("Start Screen: Play Reset Save Quit\nFeedback Popups: Mana Purity Upgrade Not Enough Mana\nSave Load: local MysticGrove_SaveSlot");
}

int32 AMysticGrovePlayerController::GetGroveRestorationPercent() const
{
	if (const AMysticBuildingInteractable* SacredPond = FindBuildingByType(EMysticBuildingType::SacredPond))
	{
		return FMath::Clamp(SacredPond->SacredPondWaterPurity, 0, 100);
	}

	return 15;
}

void AMysticGrovePlayerController::RefreshGroveRestorationHud()
{
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetGroveRestorationPercent(GetGroveRestorationPercent());
	}
}

void AMysticGrovePlayerController::SetProgressionActorVisibility(const FString& TargetActorLabel, bool bShouldShow)
{
#if WITH_EDITOR
	if (!GetWorld())
	{
		return;
	}

	for (TActorIterator<AActor> It(GetWorld()); It; ++It)
	{
		AActor* Actor = *It;
		if (Actor && Actor->GetActorLabel() == TargetActorLabel)
		{
			Actor->SetActorHiddenInGame(!bShouldShow);
			Actor->SetActorEnableCollision(bShouldShow);
			return;
		}
	}
#endif
}

void AMysticGrovePlayerController::UpdateGroveRestorationVisuals()
{
	const int32 Restoration = GetGroveRestorationPercent();
	SetProgressionActorVisibility(TEXT("Core Loop Extra Flowers 25"), Restoration >= 25);
	SetProgressionActorVisibility(TEXT("Core Loop Pond Glow 50"), Restoration >= 50);
	SetProgressionActorVisibility(TEXT("Core Loop Fairy Lights 75"), Restoration >= 75);
	SetProgressionActorVisibility(TEXT("Core Loop Ancient Tree Glow 100"), Restoration >= 100);
}

void AMysticGrovePlayerController::UpdateFlowerGrovePlotVisuals()
{
	const AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove);
	if (!FlowerGrove)
	{
		return;
	}

	SetProgressionActorVisibility(TEXT("Flower Grove Locked Plot 04"), FlowerGrove->ActivePlots < 4);
	SetProgressionActorVisibility(TEXT("Flower Grove Locked Plot 05"), FlowerGrove->ActivePlots < 5);
	SetProgressionActorVisibility(TEXT("Flower Grove Active Plot Glow 04"), FlowerGrove->ActivePlots >= 4);
	SetProgressionActorVisibility(TEXT("Flower Grove Active Plot Glow 05"), FlowerGrove->ActivePlots >= 5);
}

void AMysticGrovePlayerController::ShowFlowerGroveLevelPulse()
{
	SetProgressionActorVisibility(TEXT("Flower Grove Level Up Pulse"), true);
	FTimerHandle PulseTimerHandle;
	GetWorldTimerManager().SetTimer(PulseTimerHandle, [this]()
	{
		SetProgressionActorVisibility(TEXT("Flower Grove Level Up Pulse"), false);
	}, 0.65f, false);
}

void AMysticGrovePlayerController::BeginPlay()
{
	Super::BeginPlay();

	bShowMouseCursor = true;
	bEnableClickEvents = true;
	bEnableTouchEvents = true;
	DefaultMouseCursor = EMouseCursor::Hand;
	SetInputMode(FInputModeGameAndUI());

	for (TActorIterator<AMysticCameraManager> It(GetWorld()); It; ++It)
	{
		CameraManager = *It;
		break;
	}

	if (CameraManager)
	{
		SetViewTarget(CameraManager);
		CameraManager->OnZoomToBuildingComplete.AddDynamic(this, &AMysticGrovePlayerController::HandleZoomToBuildingComplete);
	}

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetCameraManager(CameraManager);
		MysticHud->SetMana(TotalMana);
		MysticHud->SetStartScreenVisible(false);
	}

	LoadMysticGroveGame();
	UpdateFairyAssignmentBonuses();
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();
	UpdateFlowerGrovePlotVisuals();
	RefreshTutorialPrompt();
	ShowStartScreen();
}

bool AMysticGrovePlayerController::SaveMysticGroveGame()
{
	UMysticGroveSaveGame* SaveGame = Cast<UMysticGroveSaveGame>(
		UGameplayStatics::CreateSaveGameObject(UMysticGroveSaveGame::StaticClass())
	);

	if (!SaveGame)
	{
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetSaveStatusMessage(TEXT("Save Failed"));
		}
		return false;
	}

	FillSaveGameValues(SaveGame);
	const bool bSaved = UGameplayStatics::SaveGameToSlot(SaveGame, MysticGroveSaveSlotName, 0);
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetSaveStatusMessage(bSaved ? TEXT("Game Saved") : TEXT("Save Failed"));
	}
	return bSaved;
}

bool AMysticGrovePlayerController::LoadMysticGroveGame()
{
	if (!UGameplayStatics::DoesSaveGameExist(MysticGroveSaveSlotName, 0))
	{
		ApplyDefaultSaveValues();
		RefreshGroveRestorationHud();
		UpdateGroveRestorationVisuals();
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetSaveStatusMessage(TEXT("No Save Found"));
		}
		return false;
	}

	UMysticGroveSaveGame* SaveGame = Cast<UMysticGroveSaveGame>(
		UGameplayStatics::LoadGameFromSlot(MysticGroveSaveSlotName, 0)
	);

	if (!SaveGame)
	{
		ApplyDefaultSaveValues();
		RefreshGroveRestorationHud();
		UpdateGroveRestorationVisuals();
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetSaveStatusMessage(TEXT("Load Failed"));
		}
		return false;
	}

	ApplySaveGameValues(SaveGame);
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetSaveStatusMessage(TEXT("Game Loaded"));
	}
	return true;
}

void AMysticGrovePlayerController::ResetMysticGroveSave()
{
	if (UGameplayStatics::DoesSaveGameExist(MysticGroveSaveSlotName, 0))
	{
		UGameplayStatics::DeleteGameInSlot(MysticGroveSaveSlotName, 0);
	}

	ApplyDefaultSaveValues();
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();
	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetSaveStatusMessage(TEXT("Save Reset"));
	}
	RefreshTutorialPrompt();
}

void AMysticGrovePlayerController::PlayerTick(float DeltaTime)
{
	Super::PlayerTick(DeltaTime);

	RefreshCurrentBuildingScreen();
	if (!bHasCompletedTutorial && TutorialStep == 2)
	{
		if (const AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove))
		{
			if (FlowerGrove->StoredMana >= 1.0f)
			{
				SetTutorialStep(3);
			}
		}
	}
}

void AMysticGrovePlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	InputComponent->BindKey(EKeys::LeftMouseButton, IE_Pressed, this, &AMysticGrovePlayerController::HandlePrimaryPressed);
	InputComponent->BindKey(EKeys::Escape, IE_Pressed, this, &AMysticGrovePlayerController::HandleReturnPressed);
	InputComponent->BindKey(EKeys::BackSpace, IE_Pressed, this, &AMysticGrovePlayerController::HandleReturnPressed);
	InputComponent->BindTouch(IE_Pressed, this, &AMysticGrovePlayerController::HandleTouchPressed);
}

void AMysticGrovePlayerController::HandlePrimaryPressed()
{
	float MouseX = 0.0f;
	float MouseY = 0.0f;
	GetMousePosition(MouseX, MouseY);
	HandleScreenPress(FVector2D(MouseX, MouseY), true);
}

void AMysticGrovePlayerController::HandleTouchPressed(const ETouchIndex::Type FingerIndex, const FVector Location)
{
	HandleScreenPress(FVector2D(Location.X, Location.Y), false);
}

void AMysticGrovePlayerController::ShowStartScreen()
{
	if (CurrentStartScreen)
	{
		return;
	}

	CurrentStartScreen = CreateWidget<UMysticStartScreenWidget>(this, UMysticStartScreenWidget::StaticClass());
	if (!CurrentStartScreen)
	{
		return;
	}

	CurrentStartScreen->OnPlayRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleStartScreenPlayRequested);
	CurrentStartScreen->OnResetSaveRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleStartScreenResetSaveRequested);
	CurrentStartScreen->OnQuitRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleStartScreenQuitRequested);
	CurrentStartScreen->AddToViewport(100);

	FInputModeGameAndUI InputMode;
	InputMode.SetWidgetToFocus(CurrentStartScreen->TakeWidget());
	InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
	SetInputMode(InputMode);
	bShowMouseCursor = true;
}

void AMysticGrovePlayerController::HideStartScreen()
{
	if (!CurrentStartScreen)
	{
		return;
	}

	CurrentStartScreen->OnPlayRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleStartScreenPlayRequested);
	CurrentStartScreen->OnResetSaveRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleStartScreenResetSaveRequested);
	CurrentStartScreen->OnQuitRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleStartScreenQuitRequested);
	CurrentStartScreen->RemoveFromParent();
	CurrentStartScreen = nullptr;
}

void AMysticGrovePlayerController::ShowTutorialPromptWidget()
{
	if (CurrentTutorialPrompt)
	{
		return;
	}

	CurrentTutorialPrompt = CreateWidget<UMysticTutorialPromptWidget>(this, UMysticTutorialPromptWidget::StaticClass());
	if (!CurrentTutorialPrompt)
	{
		return;
	}

	CurrentTutorialPrompt->OnNextRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleTutorialNextRequested);
	CurrentTutorialPrompt->OnSkipRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleTutorialSkipRequested);
	CurrentTutorialPrompt->AddToViewport(80);

	FInputModeGameAndUI InputMode;
	InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
	SetInputMode(InputMode);
	bShowMouseCursor = true;
}

void AMysticGrovePlayerController::HideTutorialPromptWidget()
{
	if (!CurrentTutorialPrompt)
	{
		return;
	}

	CurrentTutorialPrompt->OnNextRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleTutorialNextRequested);
	CurrentTutorialPrompt->OnSkipRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleTutorialSkipRequested);
	CurrentTutorialPrompt->RemoveFromParent();
	CurrentTutorialPrompt = nullptr;
}

void AMysticGrovePlayerController::HandleStartScreenPlayRequested()
{
	PlayFromStartScreen();
}

void AMysticGrovePlayerController::HandleStartScreenResetSaveRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Reset Save"));
	ResetMysticGroveSave();
	HideStartScreen();
	ShowDemoFeedback(TEXT("Save Reset"));
	FInputModeGameAndUI InputMode;
	InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
	SetInputMode(InputMode);
	bShowMouseCursor = true;
}

void AMysticGrovePlayerController::HandleStartScreenQuitRequested()
{
	QuitMysticGrove();
}

void AMysticGrovePlayerController::HandleTutorialNextRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Next"));
	if (TutorialStep == 0)
	{
		SetTutorialStep(1);
	}
	else if (TutorialStep == 8)
	{
		CompleteTutorial();
	}
}

void AMysticGrovePlayerController::HandleTutorialSkipRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Skip"));
	SkipTutorial();
}

void AMysticGrovePlayerController::HandleReturnPressed()
{
	if (CurrentBuildingScreen || PendingBuilding)
	{
		PlayDemoSound(BackButtonSound);
		if (UMysticBuildingScreenWidget* BuildingScreen = Cast<UMysticBuildingScreenWidget>(CurrentBuildingScreen))
		{
			BuildingScreen->StartFadeOut();
		}
		else
		{
			CloseBuildingScreen();
		}
	}
}

void AMysticGrovePlayerController::HandleScreenPress(const FVector2D& ScreenPosition, bool bUseCursorTrace)
{
	if (HandleTutorialButtonPress(ScreenPosition))
	{
		return;
	}

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		switch (MysticHud->GetStartScreenButtonAction(ScreenPosition))
		{
		case 1:
			ShowButtonFlash(TEXT("Play"));
			PlayFromStartScreen();
			return;
		case 2:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Reset Save"));
			ResetMysticGroveSave();
			MysticHud->SetStartScreenVisible(false);
			ShowDemoFeedback(TEXT("Save Reset"));
			return;
		case 3:
			QuitMysticGrove();
			return;
		default:
			break;
		}

		switch (MysticHud->GetTutorialButtonAction(ScreenPosition))
		{
		case 1:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Next"));
			if (TutorialStep == 0)
			{
				SetTutorialStep(1);
			}
			else if (TutorialStep == 8)
			{
				CompleteTutorial();
			}
			return;
		case 2:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Skip"));
			SkipTutorial();
			return;
		default:
			break;
		}

		switch (MysticHud->GetUtilityButtonAction(ScreenPosition))
		{
		case 1:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Save"));
			SaveMysticGroveGame();
			return;
		case 2:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Load"));
			LoadMysticGroveGame();
			return;
		case 3:
			PlayDemoSound(ButtonClickSound);
			ShowButtonFlash(TEXT("Reset Save"));
			ResetMysticGroveSave();
			ShowDemoFeedback(TEXT("Save Reset"));
			return;
		default:
			break;
		}
	}

	if (!CameraManager)
	{
		return;
	}

	if (!bBuildingClicksEnabled)
	{
		return;
	}

	FHitResult Hit;
	const bool bHit = bUseCursorTrace
		? GetHitResultUnderCursor(ECC_Visibility, true, Hit)
		: GetHitResultAtScreenPosition(ScreenPosition, ECC_Visibility, true, Hit);

	if (!bHit)
	{
		return;
	}

	if (AMysticBuildingInteractable* Building = Cast<AMysticBuildingInteractable>(Hit.GetActor()))
	{
		PlayDemoSound(ButtonClickSound);
		bBuildingClicksEnabled = false;
		PendingBuilding = Building;
		CameraManager->ZoomToBuilding(Building);
		GetWorldTimerManager().ClearTimer(OpenBuildingScreenTimerHandle);
		GetWorldTimerManager().SetTimer(OpenBuildingScreenTimerHandle, this, &AMysticGrovePlayerController::HandleOpenBuildingScreenDelay, 1.2f, false);
	}
}

void AMysticGrovePlayerController::HandleZoomToBuildingComplete(AMysticBuildingInteractable* Building)
{
	if (!Building || Building != PendingBuilding)
	{
		return;
	}

	OpenBuildingScreen(Building);
}

void AMysticGrovePlayerController::HandleOpenBuildingScreenDelay()
{
	if (PendingBuilding && !CurrentBuildingScreen)
	{
		OpenBuildingScreen(PendingBuilding);
	}
}

void AMysticGrovePlayerController::HandleBuildingScreenBackRequested()
{
	PlayDemoSound(BackButtonSound);
	ShowButtonFlash(TEXT("Back"));
	if (bShowingFairyAssignmentPanel)
	{
		bShowingFairyAssignmentPanel = false;
		RefreshCurrentBuildingScreen();
		return;
	}

	CloseBuildingScreen();
}

void AMysticGrovePlayerController::HandleBuildingScreenFirstActionRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Action"));
	if (bShowingFairyAssignmentPanel)
	{
		AssignLunaToTask(TEXT("Flower Grove"));
		return;
	}

	if (PendingBuilding && PendingBuilding->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		CollectFlowerGroveMana();
		return;
	}

	if (PendingBuilding && PendingBuilding->BuildingType == EMysticBuildingType::FairyHouse)
	{
		ShowFairyAssignmentPanel();
		return;
	}

	if (PendingBuilding && PendingBuilding->BuildingType == EMysticBuildingType::SacredPond)
	{
		RestoreSacredPond();
	}
}

void AMysticGrovePlayerController::HandleBuildingScreenSecondActionRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Action"));
	if (bShowingFairyAssignmentPanel)
	{
		AssignLunaToTask(TEXT("Sacred Koi Pond"));
		return;
	}

	if (PendingBuilding && PendingBuilding->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		UpgradeFlowerGrove();
	}
}
void AMysticGrovePlayerController::HandleBuildingScreenThirdActionRequested()
{
	PlayDemoSound(ButtonClickSound);
	ShowButtonFlash(TEXT("Action"));
	if (bShowingFairyAssignmentPanel)
	{
		AssignLunaToTask(TEXT("Unassigned"));
		return;
	}

	if (PendingBuilding && PendingBuilding->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		UnlockFlowerGrovePlot();
	}
}
void AMysticGrovePlayerController::OpenBuildingScreen(AMysticBuildingInteractable* Building)
{
	if (!Building)
	{
		bBuildingClicksEnabled = true;
		PendingBuilding = nullptr;
		return;
	}

	if (CurrentBuildingScreen)
	{
		CurrentBuildingScreen->RemoveFromParent();
		CurrentBuildingScreen = nullptr;
	}

	TSubclassOf<UUserWidget> WidgetClass = Building->ScreenWidgetClass;
	if (!WidgetClass)
	{
		WidgetClass = UMysticBuildingScreenWidget::StaticClass();
	}

	CurrentBuildingScreen = CreateWidget<UUserWidget>(this, WidgetClass);
	if (!CurrentBuildingScreen)
	{
		CurrentBuildingScreen = CreateWidget<UUserWidget>(this, UMysticBuildingScreenWidget::StaticClass());
	}

	if (!CurrentBuildingScreen)
	{
		bBuildingClicksEnabled = true;
		PendingBuilding = nullptr;
		return;
	}

	if (UMysticBuildingScreenWidget* BuildingScreen = Cast<UMysticBuildingScreenWidget>(CurrentBuildingScreen))
	{
		const FText BodyText = bShowingFairyAssignmentPanel
			? GetFairyAssignmentText()
			: (Building->BuildingType == EMysticBuildingType::FlowerGrove
				? GetFlowerGroveStatsText()
				: (Building->BuildingType == EMysticBuildingType::SacredPond ? GetSacredPondStatsText() : GetPlaceholderStatsText(Building)));
		FText FirstAction;
		FText SecondAction;
		FText ThirdAction;
		if (bShowingFairyAssignmentPanel)
		{
			FirstAction = FText::FromString(TEXT("Assign to Flower Grove"));
			SecondAction = FText::FromString(TEXT("Assign to Sacred Koi Pond"));
			ThirdAction = FText::FromString(TEXT("Set Unassigned"));
		}
		else
		{
			GetActionLabels(Building, FirstAction, SecondAction, ThirdAction);
		}
		BuildingScreen->SetScreenText(GetBuildingScreenTitle(Building), BodyText);
		BuildingScreen->SetActionButtonText(FirstAction, SecondAction, ThirdAction);
		BuildingScreen->OnBackRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenBackRequested);
		BuildingScreen->OnFirstActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenFirstActionRequested);
		BuildingScreen->OnSecondActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenSecondActionRequested);
		BuildingScreen->OnThirdActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenThirdActionRequested);
	}
	else
	{
		CurrentBuildingScreen->RemoveFromParent();
		CurrentBuildingScreen = CreateWidget<UMysticBuildingScreenWidget>(this, UMysticBuildingScreenWidget::StaticClass());
		UMysticBuildingScreenWidget* FallbackScreen = Cast<UMysticBuildingScreenWidget>(CurrentBuildingScreen);
		if (FallbackScreen)
		{
			const FText BodyText = bShowingFairyAssignmentPanel
			? GetFairyAssignmentText()
			: (Building->BuildingType == EMysticBuildingType::FlowerGrove
				? GetFlowerGroveStatsText()
				: (Building->BuildingType == EMysticBuildingType::SacredPond ? GetSacredPondStatsText() : GetPlaceholderStatsText(Building)));
			FText FirstAction;
			FText SecondAction;
			FText ThirdAction;
			if (bShowingFairyAssignmentPanel)
		{
			FirstAction = FText::FromString(TEXT("Assign to Flower Grove"));
			SecondAction = FText::FromString(TEXT("Assign to Sacred Koi Pond"));
			ThirdAction = FText::FromString(TEXT("Set Unassigned"));
		}
		else
		{
			GetActionLabels(Building, FirstAction, SecondAction, ThirdAction);
		}
			FallbackScreen->SetScreenText(GetBuildingScreenTitle(Building), BodyText);
			FallbackScreen->SetActionButtonText(FirstAction, SecondAction, ThirdAction);
			FallbackScreen->OnBackRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenBackRequested);
			FallbackScreen->OnFirstActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenFirstActionRequested);
			FallbackScreen->OnSecondActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenSecondActionRequested);
			FallbackScreen->OnThirdActionRequested.AddDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenThirdActionRequested);
		}
	}

	CurrentBuildingStatusMessage.Empty();
	bShowingFairyAssignmentPanel = false;
	CurrentBuildingScreen->AddToViewport(10);
	HideOtherBuildingsForFocusedView(Building);
	SetInputMode(FInputModeGameAndUI());
	bShowMouseCursor = true;

	if (Building->BuildingType == EMysticBuildingType::FlowerGrove)
	{
		AdvanceTutorialFromAction(TEXT("OpenFlowerGrove"));
	}
	else if (Building->BuildingType == EMysticBuildingType::SacredPond)
	{
		AdvanceTutorialFromAction(TEXT("OpenSacredPond"));
	}
	else if (Building->BuildingType == EMysticBuildingType::FairyHouse)
	{
		AdvanceTutorialFromAction(TEXT("OpenFairyHouse"));
	}
}

void AMysticGrovePlayerController::CloseBuildingScreen()
{
	SaveMysticGroveGame();

	if (CurrentBuildingScreen)
	{
		if (UMysticBuildingScreenWidget* BuildingScreen = Cast<UMysticBuildingScreenWidget>(CurrentBuildingScreen))
		{
			BuildingScreen->OnBackRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenBackRequested);
			BuildingScreen->OnFirstActionRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenFirstActionRequested);
			BuildingScreen->OnSecondActionRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenSecondActionRequested);
			BuildingScreen->OnThirdActionRequested.RemoveDynamic(this, &AMysticGrovePlayerController::HandleBuildingScreenThirdActionRequested);
		}
		CurrentBuildingScreen->RemoveFromParent();
		CurrentBuildingScreen = nullptr;
	}

	PendingBuilding = nullptr;
	bBuildingClicksEnabled = true;
	GetWorldTimerManager().ClearTimer(OpenBuildingScreenTimerHandle);
	SetInputMode(FInputModeGameOnly());
	bShowMouseCursor = true;
	RestoreHiddenBuildings();

	if (CameraManager)
	{
		CameraManager->ReturnToVillage();
	}
}

void AMysticGrovePlayerController::RefreshCurrentBuildingScreen()
{
	if (!PendingBuilding)
	{
		return;
	}

	UMysticBuildingScreenWidget* BuildingScreen = Cast<UMysticBuildingScreenWidget>(CurrentBuildingScreen);
	if (!BuildingScreen)
	{
		return;
	}

	const FText BodyText = bShowingFairyAssignmentPanel
		? GetFairyAssignmentText()
		: (PendingBuilding->BuildingType == EMysticBuildingType::FlowerGrove
			? GetFlowerGroveStatsText()
			: (PendingBuilding->BuildingType == EMysticBuildingType::SacredPond ? GetSacredPondStatsText() : GetPlaceholderStatsText(PendingBuilding)));
	BuildingScreen->SetScreenText(bShowingFairyAssignmentPanel ? FText::FromString(TEXT("Assign Luna")) : GetBuildingScreenTitle(PendingBuilding), BodyText);
	if (bShowingFairyAssignmentPanel)
	{
		BuildingScreen->SetActionButtonText(FText::FromString(TEXT("Assign to Flower Grove")), FText::FromString(TEXT("Assign to Sacred Koi Pond")), FText::FromString(TEXT("Set Unassigned")));
	}
	else
	{
		FText FirstAction;
		FText SecondAction;
		FText ThirdAction;
		GetActionLabels(PendingBuilding, FirstAction, SecondAction, ThirdAction);
		BuildingScreen->SetActionButtonText(FirstAction, SecondAction, ThirdAction);
	}
}

FText AMysticGrovePlayerController::GetFlowerGroveStatsText() const
{
	const AMysticBuildingInteractable* FlowerGrove = PendingBuilding;
	if (!FlowerGrove || FlowerGrove->BuildingType != EMysticBuildingType::FlowerGrove)
	{
		return FText::FromString(TEXT("Mana Production: +5/sec\nStored Mana: 0 / 100"));
	}

	FString Stats = FString::Printf(
		TEXT("Stored Mana: %d / %d\nBase Production: +%d/sec\nFairy Bonus: +%d/sec\nTotal Production: +%d/sec\nActive Plots: %d / %d\nUpgrade Cost: %d Mana\nUnlock Plot Cost: %s"),
		FMath::FloorToInt(FlowerGrove->StoredMana),
		FlowerGrove->MaxStoredMana,
		FMath::FloorToInt(FlowerGrove->BaseManaProductionRate),
		FMath::FloorToInt(FlowerGrove->FairyBonusManaProduction),
		FMath::FloorToInt(FlowerGrove->GetTotalManaProductionRate()),
		FlowerGrove->ActivePlots,
		FlowerGrove->MaxPlots,
		FlowerGrove->UpgradeCost,
		FlowerGrove->GetNextPlotUnlockCost() > 0 ? *FString::Printf(TEXT("%d Mana"), FlowerGrove->GetNextPlotUnlockCost()) : TEXT("All plots unlocked")
	);
	if (!CurrentBuildingStatusMessage.IsEmpty())
	{
		Stats += FString::Printf(TEXT("\n\n%s"), *CurrentBuildingStatusMessage);
	}

	return FText::FromString(Stats);
}

FText AMysticGrovePlayerController::GetSacredPondStatsText() const
{
	const AMysticBuildingInteractable* SacredPond = PendingBuilding;
	if (!SacredPond || SacredPond->BuildingType != EMysticBuildingType::SacredPond)
	{
		return FText::FromString(TEXT("Heart of the Grove\n\nWater Purity: 15 / 100\nSpirit Energy: 0\nPond Level: 1\nSpirit Guardians: 0 / 3"));
	}

	FString Stats = FString::Printf(
		TEXT("Heart of the Grove\n\nWater Purity: %d / %d\nRestore Amount: +%d\nSpirit Energy: %d\nPond Level: %d\nSpirit Guardians: 0 / 3"),
		SacredPond->SacredPondWaterPurity,
		SacredPond->MaxWaterPurity,
		SacredPond->BaseRestorePurityAmount + SacredPond->FairyRestorePurityBonus,
		SacredPond->SpiritEnergy,
		SacredPond->SacredPondLevel
	);

	if (!CurrentBuildingStatusMessage.IsEmpty())
	{
		Stats += FString::Printf(TEXT("\n\n%s"), *CurrentBuildingStatusMessage);
	}

	return FText::FromString(Stats);
}
FText AMysticGrovePlayerController::GetFairyAssignmentText() const
{
	const AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse);
	const FString CurrentTask = FairyHouse ? FairyHouse->FairyAssignedTask : TEXT("Flower Grove");
	return FText::FromString(FString::Printf(
		TEXT("Available Tasks:\n- Flower Grove\n- Sacred Koi Pond\n- Unassigned\n\nCurrent Assignment: %s"),
		*CurrentTask
	));
}

void AMysticGrovePlayerController::ShowFairyAssignmentPanel()
{
	bShowingFairyAssignmentPanel = true;
	CurrentBuildingStatusMessage.Empty();
	RefreshCurrentBuildingScreen();
}

void AMysticGrovePlayerController::AssignLunaToTask(const FString& NewAssignedTask)
{
	AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse);
	if (!FairyHouse)
	{
		return;
	}

	FairyHouse->AssignLunaToTask(NewAssignedTask);
	UpdateFairyAssignmentBonuses();
	SaveMysticGroveGame();
	AdvanceTutorialFromAction(TEXT("ViewLunaAssignment"));
	bShowingFairyAssignmentPanel = false;
	RefreshCurrentBuildingScreen();
}

void AMysticGrovePlayerController::UpdateFairyAssignmentBonuses()
{
	AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse);

	if (AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove))
	{
		FlowerGrove->UpdateFairyWorkerBonusFromHouse(FairyHouse);
	}

	if (AMysticBuildingInteractable* SacredPond = FindBuildingByType(EMysticBuildingType::SacredPond))
	{
		SacredPond->UpdateSacredPondFairyBonusFromHouse(FairyHouse);
	}
}
void AMysticGrovePlayerController::CollectFlowerGroveMana()
{
	AMysticBuildingInteractable* FlowerGrove = PendingBuilding;
	if (!FlowerGrove || FlowerGrove->BuildingType != EMysticBuildingType::FlowerGrove)
	{
		return;
	}

	const int32 ManaToCollect = FlowerGrove->CollectStoredMana();
	if (ManaToCollect <= 0)
	{
		ShowDemoFeedback(TEXT("No Mana Ready"));
		RefreshCurrentBuildingScreen();
		return;
	}

	TotalMana += ManaToCollect;
	PlayDemoSound(CollectManaSound);
	ShowDemoFeedback(FString::Printf(TEXT("+%d Mana"), ManaToCollect));
	ShowButtonFlash(TEXT("Collect Mana"));

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetMana(TotalMana);
	}

	RefreshCurrentBuildingScreen();
	AdvanceTutorialFromAction(TEXT("CollectMana"));
	SaveMysticGroveGame();
}

void AMysticGrovePlayerController::RestoreSacredPond()
{
	AMysticBuildingInteractable* SacredPond = PendingBuilding;
	if (!SacredPond || SacredPond->BuildingType != EMysticBuildingType::SacredPond)
	{
		return;
	}

	const int32 PreviousPurity = SacredPond->SacredPondWaterPurity;
	const bool bRestored = SacredPond->RestoreSacredPondWithMana(TotalMana);
	CurrentBuildingStatusMessage = SacredPond->LastRestoreMessage;

	if (bRestored)
	{
		TotalMana = SacredPond->LastRestoreRemainingMana;
		const int32 PurityGained = SacredPond->SacredPondWaterPurity - PreviousPurity;
		PlayDemoSound(RestorePondSound);
		ShowDemoFeedback(FString::Printf(TEXT("Water Purity +%d%%"), PurityGained));
		ShowButtonFlash(TEXT("Restore"));
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetMana(TotalMana);
		}
		RefreshGroveRestorationHud();
		UpdateGroveRestorationVisuals();
		SaveMysticGroveGame();
	}
	else
	{
		ShowDemoFeedback(CurrentBuildingStatusMessage.IsEmpty() ? TEXT("Not enough mana") : CurrentBuildingStatusMessage);
	}

	RefreshCurrentBuildingScreen();
	AdvanceTutorialFromAction(TEXT("RestorePond"));
}
void AMysticGrovePlayerController::UpgradeFlowerGrove()
{
	AMysticBuildingInteractable* FlowerGrove = PendingBuilding;
	if (!FlowerGrove || FlowerGrove->BuildingType != EMysticBuildingType::FlowerGrove)
	{
		return;
	}

	const bool bUpgraded = FlowerGrove->UpgradeFlowerGroveWithMana(TotalMana);
	CurrentBuildingStatusMessage = FlowerGrove->LastUpgradeMessage;

	if (bUpgraded)
	{
		TotalMana = FlowerGrove->LastUpgradeRemainingMana;
		PlayDemoSound(UpgradeFlowerSound);
		ShowDemoFeedback(TEXT("Flower Grove upgraded!"));
		ShowButtonFlash(TEXT("Upgrade Flower"));
		ShowFlowerGroveLevelPulse();
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetMana(TotalMana);
		}
		SaveMysticGroveGame();
	}
	else
	{
		ShowDemoFeedback(CurrentBuildingStatusMessage.IsEmpty() ? TEXT("Not enough mana") : CurrentBuildingStatusMessage);
	}

	RefreshCurrentBuildingScreen();
}

void AMysticGrovePlayerController::UnlockFlowerGrovePlot()
{
	AMysticBuildingInteractable* FlowerGrove = PendingBuilding;
	if (!FlowerGrove || FlowerGrove->BuildingType != EMysticBuildingType::FlowerGrove)
	{
		return;
	}

	const bool bUnlocked = FlowerGrove->UnlockNextFlowerPlotWithMana(TotalMana);
	CurrentBuildingStatusMessage = FlowerGrove->LastPlotUnlockMessage;

	if (bUnlocked)
	{
		TotalMana = FlowerGrove->LastPlotUnlockRemainingMana;
		PlayDemoSound(UpgradeFlowerSound);
		ShowDemoFeedback(TEXT("New flower plot unlocked!"));
		ShowButtonFlash(TEXT("Unlock Plot"));
		UpdateFlowerGrovePlotVisuals();
		if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
		{
			MysticHud->SetMana(TotalMana);
		}
		SaveMysticGroveGame();
	}
	else
	{
		ShowDemoFeedback(CurrentBuildingStatusMessage.IsEmpty() ? TEXT("Not enough mana.") : CurrentBuildingStatusMessage);
	}

	RefreshCurrentBuildingScreen();
}
AMysticBuildingInteractable* AMysticGrovePlayerController::FindBuildingByType(EMysticBuildingType BuildingType) const
{
	if (!GetWorld())
	{
		return nullptr;
	}

	for (TActorIterator<AMysticBuildingInteractable> It(GetWorld()); It; ++It)
	{
		AMysticBuildingInteractable* Building = *It;
		if (Building && Building->BuildingType == BuildingType)
		{
			return Building;
		}
	}

	return nullptr;
}

void AMysticGrovePlayerController::ApplyDefaultSaveValues()
{
	TotalMana = 0;
	TotalCoins = 0;
	bHasCompletedTutorial = false;
	TutorialStep = 0;

	if (AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove))
	{
		FlowerGrove->StoredMana = 0.0f;
		FlowerGrove->FlowerGroveLevel = 1;
		FlowerGrove->MaxStoredMana = 100;
		FlowerGrove->BaseManaProductionRate = 5.0f;
		FlowerGrove->ManaProductionRate = 5.0f;
		FlowerGrove->FairyBonusManaProduction = 0.0f;
		FlowerGrove->UpgradeCost = 25;
		FlowerGrove->ActivePlots = 3;
		FlowerGrove->MaxPlots = 5;
	}

	if (AMysticBuildingInteractable* SacredPond = FindBuildingByType(EMysticBuildingType::SacredPond))
	{
		SacredPond->SacredPondWaterPurity = 15;
		SacredPond->MaxWaterPurity = 100;
		SacredPond->SpiritEnergy = 0;
		SacredPond->SacredPondLevel = 1;
		SacredPond->RestoreCost = 25;
		SacredPond->BaseRestorePurityAmount = 5;
		SacredPond->FairyRestorePurityBonus = 0;
	}

	if (AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse))
	{
		FairyHouse->FairyHouseLevel = 1;
		FairyHouse->FairyResidents = 1;
		FairyHouse->FairyWorkersActive = 1;
		FairyHouse->FairyName = TEXT("Luna");
		FairyHouse->FairyLevel = 1;
		FairyHouse->FairyAssignedTask = TEXT("Flower Grove");
		FairyHouse->FairyWorkBonus = 3.0f;
		FairyHouse->bFairyIsAssigned = true;
	}

	UpdateFairyAssignmentBonuses();
	UpdateFlowerGrovePlotVisuals();

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetMana(TotalMana);
	}
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();

	RefreshCurrentBuildingScreen();
}

void AMysticGrovePlayerController::ApplySaveGameValues(const UMysticGroveSaveGame* SaveGame)
{
	if (!SaveGame)
	{
		ApplyDefaultSaveValues();
		return;
	}

	TotalMana = SaveGame->TotalMana;
	TotalCoins = SaveGame->TotalCoins;
	bHasCompletedTutorial = SaveGame->bHasCompletedTutorial;
	TutorialStep = bHasCompletedTutorial ? 8 : FMath::Clamp(SaveGame->TutorialStep, 0, 8);

	if (AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove))
	{
		FlowerGrove->StoredMana = SaveGame->FlowerGroveStoredMana;
		FlowerGrove->FlowerGroveLevel = SaveGame->FlowerGroveLevel;
		FlowerGrove->MaxStoredMana = SaveGame->FlowerGroveMaxStoredMana;
		FlowerGrove->BaseManaProductionRate = SaveGame->FlowerGroveBaseManaProductionRate;
		FlowerGrove->ManaProductionRate = FlowerGrove->BaseManaProductionRate;
		FlowerGrove->UpgradeCost = SaveGame->FlowerGroveUpgradeCost;
		FlowerGrove->FairyBonusManaProduction = SaveGame->FlowerGroveFairyBonusProduction;
		FlowerGrove->ActivePlots = SaveGame->FlowerGroveActivePlots;
		FlowerGrove->MaxPlots = SaveGame->FlowerGroveMaxPlots;
	}

	if (AMysticBuildingInteractable* SacredPond = FindBuildingByType(EMysticBuildingType::SacredPond))
	{
		SacredPond->SacredPondWaterPurity = SaveGame->SacredPondWaterPurity;
		SacredPond->MaxWaterPurity = SaveGame->MaxWaterPurity;
		SacredPond->SpiritEnergy = SaveGame->SpiritEnergy;
		SacredPond->SacredPondLevel = SaveGame->SacredPondLevel;
		SacredPond->RestoreCost = SaveGame->RestoreCost;
	}

	if (AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse))
	{
		FairyHouse->FairyHouseLevel = SaveGame->FairyHouseLevel;
		FairyHouse->FairyResidents = SaveGame->FairyResidents;
		FairyHouse->FairyWorkersActive = SaveGame->FairyWorkersActive;
		FairyHouse->FairyName = SaveGame->FairyName;
		FairyHouse->FairyLevel = SaveGame->FairyLevel;
		FairyHouse->FairyAssignedTask = SaveGame->FairyAssignedTask;
		FairyHouse->FairyWorkBonus = SaveGame->FairyWorkBonus;
		FairyHouse->bFairyIsAssigned = SaveGame->bFairyIsAssigned;
	}

	UpdateFairyAssignmentBonuses();
	UpdateFlowerGrovePlotVisuals();

	if (AMysticHud* MysticHud = Cast<AMysticHud>(GetHUD()))
	{
		MysticHud->SetMana(TotalMana);
	}
	RefreshGroveRestorationHud();
	UpdateGroveRestorationVisuals();

	RefreshCurrentBuildingScreen();
}

void AMysticGrovePlayerController::FillSaveGameValues(UMysticGroveSaveGame* SaveGame) const
{
	if (!SaveGame)
	{
		return;
	}

	SaveGame->TotalMana = TotalMana;
	SaveGame->TotalCoins = TotalCoins;

	if (const AMysticBuildingInteractable* FlowerGrove = FindBuildingByType(EMysticBuildingType::FlowerGrove))
	{
		SaveGame->FlowerGroveStoredMana = FlowerGrove->StoredMana;
		SaveGame->FlowerGroveLevel = FlowerGrove->FlowerGroveLevel;
		SaveGame->FlowerGroveMaxStoredMana = FlowerGrove->MaxStoredMana;
		SaveGame->FlowerGroveManaProductionRate = FlowerGrove->BaseManaProductionRate;
		SaveGame->FlowerGroveBaseManaProductionRate = FlowerGrove->BaseManaProductionRate;
		SaveGame->FlowerGroveUpgradeCost = FlowerGrove->UpgradeCost;
		SaveGame->FlowerGroveFairyBonusProduction = FlowerGrove->FairyBonusManaProduction;
		SaveGame->FlowerGroveActivePlots = FlowerGrove->ActivePlots;
		SaveGame->FlowerGroveMaxPlots = FlowerGrove->MaxPlots;
	}

	if (const AMysticBuildingInteractable* SacredPond = FindBuildingByType(EMysticBuildingType::SacredPond))
	{
		SaveGame->SacredPondWaterPurity = SacredPond->SacredPondWaterPurity;
		SaveGame->MaxWaterPurity = SacredPond->MaxWaterPurity;
		SaveGame->SpiritEnergy = SacredPond->SpiritEnergy;
		SaveGame->SacredPondLevel = SacredPond->SacredPondLevel;
		SaveGame->RestoreCost = SacredPond->RestoreCost;
	}

	if (const AMysticBuildingInteractable* FairyHouse = FindBuildingByType(EMysticBuildingType::FairyHouse))
	{
		SaveGame->FairyHouseLevel = FairyHouse->FairyHouseLevel;
		SaveGame->FairyResidents = FairyHouse->FairyResidents;
		SaveGame->FairyWorkersActive = FairyHouse->FairyWorkersActive;
		SaveGame->FairyName = FairyHouse->FairyName;
		SaveGame->FairyLevel = FairyHouse->FairyLevel;
		SaveGame->FairyAssignedTask = FairyHouse->FairyAssignedTask;
		SaveGame->FairyWorkBonus = FairyHouse->FairyWorkBonus;
		SaveGame->bFairyIsAssigned = FairyHouse->bFairyIsAssigned;
	}

	SaveGame->bHasCompletedTutorial = bHasCompletedTutorial;
	SaveGame->TutorialStep = TutorialStep;
}

void AMysticGrovePlayerController::UpdateFlowerGroveFairyBonus()
{
	UpdateFairyAssignmentBonuses();
}

void AMysticGrovePlayerController::HideOtherBuildingsForFocusedView(AMysticBuildingInteractable* FocusedBuilding)
{
	RestoreHiddenBuildings();

	if (!FocusedBuilding)
	{
		return;
	}

	for (TActorIterator<AMysticBuildingInteractable> It(GetWorld()); It; ++It)
	{
		AMysticBuildingInteractable* Building = *It;
		if (!Building || Building == FocusedBuilding)
		{
			continue;
		}

		Building->SetActorHiddenInGame(true);
		HiddenFocusedViewActors.Add(Building);
	}

	for (TActorIterator<ATextRenderActor> It(GetWorld()); It; ++It)
	{
		ATextRenderActor* LabelActor = *It;
		if (!LabelActor)
		{
			continue;
		}

		if (FocusedBuilding->BuildingType == EMysticBuildingType::FlowerGrove && IsFlowerGroveVisualActor(LabelActor))
		{
			continue;
		}

		LabelActor->SetActorHiddenInGame(true);
		HiddenFocusedViewActors.Add(LabelActor);
	}

	for (TActorIterator<AActor> It(GetWorld()); It; ++It)
	{
		AActor* Actor = *It;
		if (!ShouldHideForFocusedView(Actor, FocusedBuilding) || HiddenFocusedViewActors.Contains(Actor))
		{
			continue;
		}

		Actor->SetActorHiddenInGame(true);
		HiddenFocusedViewActors.Add(Actor);
	}
}

void AMysticGrovePlayerController::RestoreHiddenBuildings()
{
	for (AActor* Actor : HiddenFocusedViewActors)
	{
		if (Actor)
		{
			Actor->SetActorHiddenInGame(false);
		}
	}

	HiddenFocusedViewActors.Reset();
}








