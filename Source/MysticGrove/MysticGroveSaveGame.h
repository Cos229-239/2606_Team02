#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "MysticGroveSaveGame.generated.h"

UCLASS(Blueprintable)
class MYSTICGROVE_API UMysticGroveSaveGame : public USaveGame
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 TotalMana = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 TotalCoins = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	float FlowerGroveStoredMana = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FlowerGroveLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FlowerGroveMaxStoredMana = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	float FlowerGroveManaProductionRate = 5.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	float FlowerGroveBaseManaProductionRate = 5.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FlowerGroveUpgradeCost = 50;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 SacredPondWaterPurity = 15;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 MaxWaterPurity = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 SpiritEnergy = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 SacredPondLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 RestoreCost = 25;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FairyHouseLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FairyResidents = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FairyWorkersActive = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	FString FairyName = TEXT("Luna");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 FairyLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	FString FairyAssignedTask = TEXT("Flower Grove");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	float FairyWorkBonus = 3.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	bool bFairyIsAssigned = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	bool bHasCompletedTutorial = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Save")
	int32 TutorialStep = 0;
};




