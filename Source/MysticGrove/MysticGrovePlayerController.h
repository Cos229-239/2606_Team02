#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "MysticBuildingInteractable.h"
#include "MysticGrovePlayerController.generated.h"

class AMysticCameraManager;
class AMysticHud;
class UMysticGroveSaveGame;
class UMysticBuildingScreenWidget;
class UMysticStartScreenWidget;
class UMysticTutorialPromptWidget;
class USoundBase;
class UUserWidget;

UCLASS()
class MYSTICGROVE_API AMysticGrovePlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	AMysticGrovePlayerController();
	virtual void BeginPlay() override;
	virtual void SetupInputComponent() override;
	virtual void PlayerTick(float DeltaTime) override;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Save")
	bool SaveMysticGroveGame();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Save")
	bool LoadMysticGroveGame();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Save")
	void ResetMysticGroveSave();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Tutorial")
	FString GetTutorialPromptForStep(int32 Step) const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Tutorial")
	int32 GetTutorialButtonActionForPoint(const FVector2D& ScreenPosition, const FVector2D& ViewportSize) const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	void PlayFromStartScreen();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	void QuitMysticGrove();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	FString GetWeek1DemoStateSummary() const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Core Loop")
	int32 GetGroveRestorationPercent() const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Core Loop")
	void RefreshGroveRestorationHud();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Core Loop")
	void UpdateGroveRestorationVisuals();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	bool bHasCompletedTutorial = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	int32 TutorialStep = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo Sounds")
	TObjectPtr<USoundBase> ButtonClickSound;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo Sounds")
	TObjectPtr<USoundBase> CollectManaSound;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo Sounds")
	TObjectPtr<USoundBase> RestorePondSound;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo Sounds")
	TObjectPtr<USoundBase> UpgradeFlowerSound;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo Sounds")
	TObjectPtr<USoundBase> BackButtonSound;

private:
	UFUNCTION()
	void HandleZoomToBuildingComplete(AMysticBuildingInteractable* Building);

	UFUNCTION()
	void HandleBuildingScreenBackRequested();

	UFUNCTION()
	void HandleBuildingScreenFirstActionRequested();

	UFUNCTION()
	void HandleBuildingScreenSecondActionRequested();

	UFUNCTION()
	void HandleBuildingScreenThirdActionRequested();

	UFUNCTION()
	void HandleStartScreenPlayRequested();

	UFUNCTION()
	void HandleStartScreenResetSaveRequested();

	UFUNCTION()
	void HandleStartScreenQuitRequested();

	UFUNCTION()
	void HandleTutorialNextRequested();

	UFUNCTION()
	void HandleTutorialSkipRequested();

	void HandleOpenBuildingScreenDelay();
	void ShowStartScreen();
	void HideStartScreen();
	void ShowTutorialPromptWidget();
	void HideTutorialPromptWidget();
	void HandlePrimaryPressed();
	void HandleTouchPressed(const ETouchIndex::Type FingerIndex, const FVector Location);
	void HandleReturnPressed();
	void HandleScreenPress(const FVector2D& ScreenPosition, bool bUseCursorTrace);
	void OpenBuildingScreen(AMysticBuildingInteractable* Building);
	void CloseBuildingScreen();
	void HideOtherBuildingsForFocusedView(AMysticBuildingInteractable* FocusedBuilding);
	void RestoreHiddenBuildings();
	void RefreshCurrentBuildingScreen();
	FText GetFlowerGroveStatsText() const;
	FText GetSacredPondStatsText() const;
	void CollectFlowerGroveMana();
	void UpgradeFlowerGrove();
	void RestoreSacredPond();
	void ShowFairyAssignmentPanel();
	void AssignLunaToTask(const FString& NewAssignedTask);
	FText GetFairyAssignmentText() const;
	void UpdateFairyAssignmentBonuses();
	void RefreshTutorialPrompt();
	void SetTutorialStep(int32 NewStep);
	void AdvanceTutorialFromAction(const FString& ActionName);
	void SkipTutorial();
	void CompleteTutorial();
	bool HandleTutorialButtonPress(const FVector2D& ScreenPosition);
	bool ShouldShowTutorialNextButton() const;
	void ShowDemoFeedback(const FString& FeedbackText, float DurationSeconds = 1.6f);
	void ShowButtonFlash(const FString& FlashText);
	void PlayDemoSound(USoundBase* Sound) const;
	AMysticBuildingInteractable* FindBuildingByType(EMysticBuildingType BuildingType) const;
	void ApplyDefaultSaveValues();
	void ApplySaveGameValues(const UMysticGroveSaveGame* SaveGame);
	void FillSaveGameValues(UMysticGroveSaveGame* SaveGame) const;
	void UpdateFlowerGroveFairyBonus();
	void SetProgressionActorVisibility(const FString& TargetActorLabel, bool bShouldShow);

	UPROPERTY()
	TObjectPtr<AMysticCameraManager> CameraManager;

	UPROPERTY()
	TObjectPtr<UUserWidget> CurrentBuildingScreen;

	UPROPERTY()
	TObjectPtr<UMysticStartScreenWidget> CurrentStartScreen;

	UPROPERTY()
	TObjectPtr<UMysticTutorialPromptWidget> CurrentTutorialPrompt;

	UPROPERTY()
	TObjectPtr<AMysticBuildingInteractable> PendingBuilding;

	UPROPERTY()
	TArray<TObjectPtr<AActor>> HiddenFocusedViewActors;

	FTimerHandle OpenBuildingScreenTimerHandle;
	int32 TotalMana = 0;
	int32 TotalCoins = 0;
	bool bBuildingClicksEnabled = true;
	FString CurrentBuildingStatusMessage;
	bool bShowingFairyAssignmentPanel = false;
};





