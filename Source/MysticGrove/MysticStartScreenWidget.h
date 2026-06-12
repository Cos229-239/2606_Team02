#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "MysticStartScreenWidget.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMysticStartScreenActionRequested);

UCLASS(Blueprintable)
class MYSTICGROVE_API UMysticStartScreenWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	virtual TSharedRef<SWidget> RebuildWidget() override;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Start Screen")
	FMysticStartScreenActionRequested OnPlayRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Start Screen")
	FMysticStartScreenActionRequested OnResetSaveRequested;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Start Screen")
	FMysticStartScreenActionRequested OnQuitRequested;

private:
	FReply HandlePlayClicked();
	FReply HandleResetSaveClicked();
	FReply HandleQuitClicked();
};
