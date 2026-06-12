#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "MysticTutorialPromptWidget.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMysticTutorialActionRequested);

UCLASS(Blueprintable)
class MYSTICGROVE_API UMysticTutorialPromptWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Tutorial")
	void SetPrompt(const FString& NewPromptText, bool bNewShowNextButton);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	FString PromptText;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Tutorial")
	bool bShowNextButton = false;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Tutorial")
	FMysticTutorialActionRequested OnNextRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Tutorial")
	FMysticTutorialActionRequested OnSkipRequested;

private:
	TSharedPtr<class STextBlock> PromptTextBlock;
	TSharedPtr<class SBox> NextButtonBox;

	void HandleNextPressed();
	void HandleSkipPressed();
	void RefreshSlateContent();
};
