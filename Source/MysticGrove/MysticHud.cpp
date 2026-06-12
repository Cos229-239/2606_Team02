#include "MysticHud.h"

#include "CanvasItem.h"
#include "EngineUtils.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "GameFramework/PlayerController.h"
#include "MysticBuildingInteractable.h"
#include "MysticCameraManager.h"

void AMysticHud::DrawHUD()
{
	Super::DrawHUD();

	if (!Canvas || !GEngine)
	{
		return;
	}

	UFont* Font = GEngine->GetSmallFont();
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.75f);
	const FLinearColor TextColor(1.0f, 0.86f, 0.34f, 1.0f);

	if (bDemoFeedbackVisible && GetWorld() && GetWorld()->GetTimeSeconds() >= DemoFeedbackHideTime)
	{
		ClearDemoFeedback();
	}

	DrawRect(PanelColor, 24.0f, 24.0f, 210.0f, 54.0f);
	DrawText(FString::Printf(TEXT("Mana: %d"), Mana), TextColor, 42.0f, 42.0f, Font, 1.35f);
	if (!bShowStartScreen)
	{
		DrawUtilityButton(TEXT("Save"), GetUtilityButtonRect(1));
		DrawUtilityButton(TEXT("Load"), GetUtilityButtonRect(2));
		DrawUtilityButton(TEXT("Reset Save"), GetUtilityButtonRect(3));
		if (!SaveStatusMessage.IsEmpty())
		{
			DrawText(SaveStatusMessage, TextColor, 42.0f, 144.0f, Font, 0.92f);
		}

		DrawOverviewLabels();
		DrawFlowerGroveLabels();
		DrawTutorialPrompt();
	}

	DrawDemoFeedback();
	DrawStartScreen();

	bHasDrawnBackButton = false;
}

bool AMysticHud::IsBackButtonHit(const FVector2D& ScreenPosition) const
{
	return false;
}

int32 AMysticHud::GetUtilityButtonAction(const FVector2D& ScreenPosition) const
{
	for (int32 ActionIndex = 1; ActionIndex <= 3; ++ActionIndex)
	{
		const FVector4 Rect = GetUtilityButtonRect(ActionIndex);
		const bool bInsideX = ScreenPosition.X >= Rect.X && ScreenPosition.X <= Rect.X + Rect.Z;
		const bool bInsideY = ScreenPosition.Y >= Rect.Y && ScreenPosition.Y <= Rect.Y + Rect.W;
		if (bInsideX && bInsideY)
		{
			return ActionIndex;
		}
	}

	return 0;
}

int32 AMysticHud::GetStartScreenButtonAction(const FVector2D& ScreenPosition) const
{
	if (!bShowStartScreen)
	{
		return 0;
	}

	for (int32 ActionIndex = 1; ActionIndex <= 3; ++ActionIndex)
	{
		const FVector4 Rect = GetStartScreenButtonRect(ActionIndex);
		const bool bInsideX = ScreenPosition.X >= Rect.X && ScreenPosition.X <= Rect.X + Rect.Z;
		const bool bInsideY = ScreenPosition.Y >= Rect.Y && ScreenPosition.Y <= Rect.Y + Rect.W;
		if (bInsideX && bInsideY)
		{
			return ActionIndex;
		}
	}

	return 0;
}

void AMysticHud::SetMana(int32 NewMana)
{
	Mana = NewMana;
}

void AMysticHud::SetCameraManager(AMysticCameraManager* NewCameraManager)
{
	CameraManager = NewCameraManager;
}

void AMysticHud::SetSaveStatusMessage(const FString& NewStatusMessage)
{
	SaveStatusMessage = NewStatusMessage;
}

void AMysticHud::SetTutorialPrompt(const FString& NewPromptText, bool bNewVisible, bool bNewShowNextButton)
{
	TutorialPromptText = NewPromptText;
	bTutorialPromptVisible = bNewVisible;
	bTutorialNextButtonVisible = bNewShowNextButton;
}

void AMysticHud::SetStartScreenVisible(bool bNewVisible)
{
	bShowStartScreen = bNewVisible;
}

void AMysticHud::ShowDemoFeedback(const FString& NewFeedbackText, float DurationSeconds)
{
	DemoFeedbackText = NewFeedbackText;
	bDemoFeedbackVisible = !DemoFeedbackText.IsEmpty();
	DemoFeedbackHideTime = GetWorld() ? GetWorld()->GetTimeSeconds() + FMath::Max(DurationSeconds, 0.1f) : 0.0;
}

void AMysticHud::ClearDemoFeedback()
{
	DemoFeedbackText.Empty();
	bDemoFeedbackVisible = false;
	DemoFeedbackHideTime = 0.0;
}

int32 AMysticHud::GetStartScreenButtonActionForPoint(const FVector2D& ScreenPosition) const
{
	return GetStartScreenButtonAction(ScreenPosition);
}

int32 AMysticHud::GetTutorialButtonAction(const FVector2D& ScreenPosition) const
{
	if (!bTutorialPromptVisible)
	{
		return 0;
	}

	if (bTutorialNextButtonVisible)
	{
		const FVector4 NextRect = GetTutorialNextButtonRect();
		if (ScreenPosition.X >= NextRect.X && ScreenPosition.X <= NextRect.X + NextRect.Z
			&& ScreenPosition.Y >= NextRect.Y && ScreenPosition.Y <= NextRect.Y + NextRect.W)
		{
			return 1;
		}
	}

	const FVector4 SkipRect = GetTutorialSkipButtonRect();
	if (ScreenPosition.X >= SkipRect.X && ScreenPosition.X <= SkipRect.X + SkipRect.Z
		&& ScreenPosition.Y >= SkipRect.Y && ScreenPosition.Y <= SkipRect.Y + SkipRect.W)
	{
		return 2;
	}

	return 0;
}

FVector4 AMysticHud::GetBackButtonRect() const
{
	if (!Canvas)
	{
		return FVector4(40.0f, 40.0f, 132.0f, 52.0f);
	}

	return FVector4(24.0f, 92.0f, 148.0f, 56.0f);
}

FVector4 AMysticHud::GetUtilityButtonRect(int32 ActionIndex) const
{
	const float X = 24.0f + static_cast<float>(ActionIndex - 1) * 96.0f;
	const float Width = ActionIndex == 3 ? 116.0f : 84.0f;
	return FVector4(X, 88.0f, Width, 42.0f);
}

FVector4 AMysticHud::GetStartScreenButtonRect(int32 ActionIndex) const
{
	const float CanvasWidth = Canvas ? Canvas->SizeX : 1280.0f;
	const float CanvasHeight = Canvas ? Canvas->SizeY : 720.0f;
	const float Width = 260.0f;
	const float Height = 58.0f;
	const float X = (CanvasWidth - Width) * 0.5f;
	const float Y = CanvasHeight * 0.48f + static_cast<float>(ActionIndex - 1) * 76.0f;
	return FVector4(X, Y, Width, Height);
}

FVector4 AMysticHud::GetTutorialPanelRect() const
{
	const float CanvasWidth = Canvas ? Canvas->SizeX : 1280.0f;
	const float CanvasHeight = Canvas ? Canvas->SizeY : 720.0f;
	const float Width = FMath::Min(520.0f, CanvasWidth - 48.0f);
	return FVector4((CanvasWidth - Width) * 0.5f, CanvasHeight - 174.0f, Width, 126.0f);
}

FVector4 AMysticHud::GetTutorialNextButtonRect() const
{
	const FVector4 Panel = GetTutorialPanelRect();
	return FVector4(Panel.X + Panel.Z - 214.0f, Panel.Y + Panel.W - 48.0f, 82.0f, 34.0f);
}

FVector4 AMysticHud::GetTutorialSkipButtonRect() const
{
	const FVector4 Panel = GetTutorialPanelRect();
	return FVector4(Panel.X + Panel.Z - 122.0f, Panel.Y + Panel.W - 48.0f, 96.0f, 34.0f);
}

void AMysticHud::DrawTutorialPrompt()
{
	if (!Canvas || !GEngine || !bTutorialPromptVisible || TutorialPromptText.IsEmpty())
	{
		return;
	}

	const FVector4 Panel = GetTutorialPanelRect();
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.84f);
	const FLinearColor TextColor(1.0f, 0.92f, 0.62f, 1.0f);
	UFont* Font = GEngine->GetSmallFont();

	DrawRect(BorderColor, Panel.X - 2.0f, Panel.Y - 2.0f, Panel.Z + 4.0f, Panel.W + 4.0f);
	DrawRect(PanelColor, Panel.X, Panel.Y, Panel.Z, Panel.W);
	DrawText(TutorialPromptText, TextColor, Panel.X + 22.0f, Panel.Y + 18.0f, Font, 1.05f);

	if (bTutorialNextButtonVisible)
	{
		DrawUtilityButton(TEXT("Next"), GetTutorialNextButtonRect());
	}
	DrawUtilityButton(TEXT("Skip"), GetTutorialSkipButtonRect());
}

void AMysticHud::DrawStartScreen()
{
	if (!Canvas || !GEngine || !bShowStartScreen)
	{
		return;
	}

	const float CanvasWidth = Canvas->SizeX;
	const float CanvasHeight = Canvas->SizeY;
	const FLinearColor BackdropColor(0.0f, 0.012f, 0.026f, 0.88f);
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.82f);
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor TitleColor(1.0f, 0.86f, 0.34f, 1.0f);
	UFont* Font = GEngine->GetSmallFont();

	DrawRect(BackdropColor, 0.0f, 0.0f, CanvasWidth, CanvasHeight);
	const float PanelWidth = FMath::Min(560.0f, CanvasWidth - 64.0f);
	const float PanelHeight = 430.0f;
	const float PanelX = (CanvasWidth - PanelWidth) * 0.5f;
	const float PanelY = (CanvasHeight - PanelHeight) * 0.5f;
	DrawRect(BorderColor, PanelX - 3.0f, PanelY - 3.0f, PanelWidth + 6.0f, PanelHeight + 6.0f);
	DrawRect(PanelColor, PanelX, PanelY, PanelWidth, PanelHeight);
	DrawText(TEXT("Mystic Grove"), TitleColor, PanelX + 72.0f, PanelY + 52.0f, Font, 2.2f);
	DrawText(TEXT("Week 1 Demo"), FLinearColor::White, PanelX + 178.0f, PanelY + 116.0f, Font, 1.05f);

	DrawUtilityButton(TEXT("Play"), GetStartScreenButtonRect(1));
	DrawUtilityButton(TEXT("Reset Save"), GetStartScreenButtonRect(2));
	DrawUtilityButton(TEXT("Quit"), GetStartScreenButtonRect(3));
}

void AMysticHud::DrawDemoFeedback()
{
	if (!Canvas || !GEngine || !bDemoFeedbackVisible || DemoFeedbackText.IsEmpty())
	{
		return;
	}

	const float CanvasWidth = Canvas->SizeX;
	const float Width = FMath::Min(380.0f, CanvasWidth - 48.0f);
	const float X = (CanvasWidth - Width) * 0.5f;
	const float Y = 158.0f;
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.82f);
	const FLinearColor TextColor(1.0f, 0.92f, 0.62f, 1.0f);
	UFont* Font = GEngine->GetSmallFont();

	DrawRect(BorderColor, X - 2.0f, Y - 2.0f, Width + 4.0f, 48.0f);
	DrawRect(PanelColor, X, Y, Width, 44.0f);
	DrawText(DemoFeedbackText, TextColor, X + 22.0f, Y + 12.0f, Font, 1.05f);
}

void AMysticHud::DrawUtilityButton(const FString& Text, const FVector4& Rect)
{
	if (!Canvas || !GEngine)
	{
		return;
	}

	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.82f);
	const FLinearColor TextColor(1.0f, 0.86f, 0.34f, 1.0f);
	UFont* Font = GEngine->GetSmallFont();

	DrawRect(BorderColor, Rect.X - 2.0f, Rect.Y - 2.0f, Rect.Z + 4.0f, Rect.W + 4.0f);
	DrawRect(PanelColor, Rect.X, Rect.Y, Rect.Z, Rect.W);
	DrawText(Text, TextColor, Rect.X + 12.0f, Rect.Y + 12.0f, Font, 0.82f);
}

void AMysticHud::DrawReadableLabel(const FString& Text, const FVector& WorldLocation, float Width, float Height, float Scale)
{
	if (!Canvas || !GEngine || !GetOwningPlayerController())
	{
		return;
	}

	FVector2D ScreenPosition;
	if (!GetOwningPlayerController()->ProjectWorldLocationToScreen(WorldLocation, ScreenPosition))
	{
		return;
	}

	const float X = ScreenPosition.X - Width * 0.5f;
	const float Y = ScreenPosition.Y - Height * 0.5f;
	const FLinearColor PanelColor(0.005f, 0.007f, 0.012f, 0.78f);
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.92f);
	const FLinearColor TextColor(1.0f, 0.86f, 0.34f, 1.0f);
	UFont* Font = GEngine->GetSmallFont();

	DrawRect(BorderColor, X - 2.0f, Y - 2.0f, Width + 4.0f, Height + 4.0f);
	DrawRect(PanelColor, X, Y, Width, Height);
	DrawText(Text, FLinearColor::Black, X + 11.0f, Y + 10.0f, Font, Scale);
	DrawText(Text, TextColor, X + 9.0f, Y + 8.0f, Font, Scale);
}

void AMysticHud::DrawOverviewLabels()
{
	if (CameraManager.IsValid() && CameraManager->IsFocusedOnBuilding())
	{
		return;
	}

	const TPair<FString, FString> Labels[] = {
		TPair<FString, FString>(TEXT("Fairy House"), TEXT("Fairy House")),
		TPair<FString, FString>(TEXT("Sacred Koi Pond"), TEXT("Sacred Koi Pond")),
		TPair<FString, FString>(TEXT("Flower Grove"), TEXT("Flower Grove")),
	};

	for (const TPair<FString, FString>& Label : Labels)
	{
		if (AActor* Actor = FindActorByLabel(Label.Key))
		{
			DrawReadableLabel(Label.Value, Actor->GetActorLocation() + FVector(0.0f, 0.0f, 145.0f), 150.0f, 34.0f, 0.95f);
		}
	}
}

void AMysticHud::DrawFlowerGroveLabels()
{
	if (!CameraManager.IsValid() || !CameraManager->IsFocusedOnBuilding())
	{
		return;
	}

	const AMysticBuildingInteractable* FocusedBuilding = CameraManager->GetFocusedBuilding();
	if (!FocusedBuilding || FocusedBuilding->BuildingType != EMysticBuildingType::FlowerGrove)
	{
		return;
	}

	const TPair<FString, FString> Labels[] = {
		TPair<FString, FString>(TEXT("Flower Grove Plot 01"), TEXT("Blue Bloom Lv. 1  +1 Mana/sec")),
		TPair<FString, FString>(TEXT("Flower Grove Plot 02"), TEXT("Purple Bloom Lv. 1  +2 Mana/sec")),
		TPair<FString, FString>(TEXT("Flower Grove Plot 03"), TEXT("Golden Bloom Lv. 1  +2 Mana/sec")),
	};

	for (const TPair<FString, FString>& Label : Labels)
	{
		if (AActor* Actor = FindActorByLabel(Label.Key))
		{
			DrawReadableLabel(Label.Value, Actor->GetActorLocation() + FVector(0.0f, 0.0f, 55.0f), 214.0f, 28.0f, 0.72f);
		}
	}
}

AActor* AMysticHud::FindActorByLabel(const FString& Label) const
{
#if WITH_EDITOR
	if (!GetWorld())
	{
		return nullptr;
	}

	for (TActorIterator<AActor> It(GetWorld()); It; ++It)
	{
		if (It->GetActorLabel() == Label)
		{
			return *It;
		}
	}
#endif
	return nullptr;
}

