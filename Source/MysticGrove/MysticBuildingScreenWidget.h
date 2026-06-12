#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "MysticBuildingScreenWidget.generated.h"

class STextBlock;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMysticBuildingScreenBackRequested);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMysticBuildingScreenActionRequested);

UCLASS(Blueprintable)
class MYSTICGROVE_API UMysticBuildingScreenWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void ReleaseSlateResources(bool bReleaseChildren) override;
	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Building Screen")
	void SetScreenText(const FText& NewTitle, const FText& NewBody);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Building Screen")
	void SetActionButtonText(const FText& FirstActionText, const FText& SecondActionText, const FText& ThirdActionText);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Building Screen")
	void StartFadeOut();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building Screen")
	FText BuildingTitle = FText::FromString(TEXT("Building"));

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building Screen")
	FText PlaceholderContent = FText::FromString(TEXT("Temporary building screen content."));

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building Screen")
	FText FirstActionLabel = FText::FromString(TEXT("Restore"));

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building Screen")
	FText SecondActionLabel = FText::FromString(TEXT("Decorate"));

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building Screen")
	FText ThirdActionLabel = FText::FromString(TEXT(""));

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Building Screen")
	FMysticBuildingScreenBackRequested OnBackRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Building Screen")
	FMysticBuildingScreenActionRequested OnFirstActionRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Building Screen")
	FMysticBuildingScreenActionRequested OnSecondActionRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Building Screen")
	FMysticBuildingScreenActionRequested OnThirdActionRequested;

private:
	FReply HandleFirstActionClicked();
	FReply HandleSecondActionClicked();
	FReply HandleThirdActionClicked();
	FReply HandleBackClicked();

	UPROPERTY(EditAnywhere, Category = "Mystic Grove|Building Screen")
	float FadeInSeconds = 0.28f;

	UPROPERTY(EditAnywhere, Category = "Mystic Grove|Building Screen")
	float FadeOutSeconds = 0.22f;

	float FadeAlpha = 0.0f;
	bool bFadingOut = false;
	bool bFadeOutFinished = false;

	TSharedPtr<STextBlock> TitleText;
	TSharedPtr<STextBlock> BodyText;
	TSharedPtr<STextBlock> FirstActionText;
	TSharedPtr<STextBlock> SecondActionText;
	TSharedPtr<STextBlock> ThirdActionText;
};


