#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "MysticHud.generated.h"

class AMysticCameraManager;
class AMysticBuildingInteractable;

UCLASS()
class MYSTICGROVE_API AMysticHud : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;

	bool IsBackButtonHit(const FVector2D& ScreenPosition) const;
	int32 GetUtilityButtonAction(const FVector2D& ScreenPosition) const;
	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	int32 GetStartScreenButtonAction(const FVector2D& ScreenPosition) const;

	void SetMana(int32 NewMana);
	void SetCameraManager(AMysticCameraManager* NewCameraManager);
	void SetSaveStatusMessage(const FString& NewStatusMessage);
	void SetTutorialPrompt(const FString& NewPromptText, bool bNewVisible, bool bNewShowNextButton);
	int32 GetTutorialButtonAction(const FVector2D& ScreenPosition) const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	void SetStartScreenVisible(bool bNewVisible);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	void ShowDemoFeedback(const FString& NewFeedbackText, float DurationSeconds = 1.6f);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	void ClearDemoFeedback();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Demo")
	int32 GetStartScreenButtonActionForPoint(const FVector2D& ScreenPosition) const;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo")
	bool bShowStartScreen = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo")
	FString DemoFeedbackText;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Demo")
	bool bDemoFeedbackVisible = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	FString TutorialPromptText;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	bool bTutorialPromptVisible = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	bool bTutorialNextButtonVisible = false;

private:
	FVector4 GetBackButtonRect() const;
	FVector4 GetUtilityButtonRect(int32 ActionIndex) const;
	FVector4 GetStartScreenButtonRect(int32 ActionIndex) const;
	FVector4 GetTutorialPanelRect() const;
	FVector4 GetTutorialNextButtonRect() const;
	FVector4 GetTutorialSkipButtonRect() const;
	void DrawUtilityButton(const FString& Text, const FVector4& Rect);
	void DrawStartScreen();
	void DrawDemoFeedback();
	void DrawTutorialPrompt();
	void DrawReadableLabel(const FString& Text, const FVector& WorldLocation, float Width, float Height, float Scale);
	void DrawOverviewLabels();
	void DrawFlowerGroveLabels();
	AActor* FindActorByLabel(const FString& Label) const;

	int32 Mana = 0;
	FString SaveStatusMessage;
	double DemoFeedbackHideTime = 0.0;
	FVector4 LastBackButtonRect = FVector4(24.0f, 92.0f, 148.0f, 56.0f);
	bool bHasDrawnBackButton = false;
	TWeakObjectPtr<AMysticCameraManager> CameraManager;
};

