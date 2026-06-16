#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMeshActor.h"
#include "MysticBuildingInteractable.generated.h"

class UUserWidget;

UENUM(BlueprintType)
enum class EMysticBuildingType : uint8
{
	FlowerGrove UMETA(DisplayName = "Flower Grove"),
	SacredPond UMETA(DisplayName = "Sacred Pond"),
	FairyHouse UMETA(DisplayName = "Fairy House"),
	PotionShop UMETA(DisplayName = "Potion Shop"),
	AncientTree UMETA(DisplayName = "Ancient Tree")
};

UCLASS(Blueprintable)
class MYSTICGROVE_API AMysticBuildingInteractable : public AStaticMeshActor
{
	GENERATED_BODY()

public:
	AMysticBuildingInteractable();
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building")
	FName BuildingID;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building")
	FText DisplayName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building")
	FName BuildingName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Building")
	EMysticBuildingType BuildingType = EMysticBuildingType::FlowerGrove;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Camera")
	TObjectPtr<AActor> ZoomTarget;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Camera")
	FVector ZoomOffset;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|UI")
	TSubclassOf<UUserWidget> ScreenWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	float StoredMana = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	int32 MaxStoredMana = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	float ManaProductionRate = 5.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	float BaseManaProductionRate = 5.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	int32 FlowerGroveLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	int32 UpgradeCost = 50;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Flower Grove")
	int32 LastUpgradeRemainingMana = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Flower Grove")
	FString LastUpgradeMessage;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 SacredPondWaterPurity = 15;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 MaxWaterPurity = 100;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 SpiritEnergy = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 SacredPondLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 RestoreCost = 25;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 BaseRestorePurityAmount = 5;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Sacred Pond")
	int32 FairyRestorePurityBonus = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Sacred Pond")
	int32 LastRestoreRemainingMana = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Sacred Pond")
	FString LastRestoreMessage;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy House")
	int32 FairyHouseLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy House")
	int32 FairyResidents = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy House")
	int32 FairyWorkersActive = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Worker")
	FString FairyName = TEXT("Luna");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Worker")
	int32 FairyLevel = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Worker")
	FString FairyAssignedTask = TEXT("Flower Grove");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Worker")
	float FairyWorkBonus = 3.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Worker")
	bool bFairyIsAssigned = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	float FairyBonusManaProduction = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	int32 ActivePlots = 3;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Flower Grove")
	int32 MaxPlots = 5;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Flower Grove")
	int32 LastPlotUnlockRemainingMana = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mystic Grove|Flower Grove")
	FString LastPlotUnlockMessage;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	void GenerateManaForSeconds(float Seconds);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	int32 CollectStoredMana();

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	float GetTotalManaProductionRate() const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	bool UpgradeFlowerGroveWithMana(int32 AvailableMana);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	int32 GetNextPlotUnlockCost() const;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Flower Grove")
	bool UnlockNextFlowerPlotWithMana(int32 AvailableMana);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Sacred Pond")
	bool RestoreSacredPondWithMana(int32 AvailableMana);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Fairy Worker")
	void UpdateFairyWorkerBonusFromHouse(const AMysticBuildingInteractable* FairyHouse);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Fairy Worker")
	void UpdateSacredPondFairyBonusFromHouse(const AMysticBuildingInteractable* FairyHouse);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Fairy Worker")
	void AssignLunaToTask(const FString& NewAssignedTask);
};





