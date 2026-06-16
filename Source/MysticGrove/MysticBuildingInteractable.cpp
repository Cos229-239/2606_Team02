#include "MysticBuildingInteractable.h"

AMysticBuildingInteractable::AMysticBuildingInteractable()
{
	PrimaryActorTick.bCanEverTick = true;
	BuildingID = TEXT("Building");
	DisplayName = FText::FromString(TEXT("Building"));
	BuildingName = TEXT("Building");
	BuildingType = EMysticBuildingType::FlowerGrove;
	ZoomTarget = nullptr;
	ZoomOffset = FVector(0.0f, -420.0f, 380.0f);
	StoredMana = 0.0f;
	MaxStoredMana = 100;
	ManaProductionRate = 5.0f;
	BaseManaProductionRate = 5.0f;
	FlowerGroveLevel = 1;
	UpgradeCost = 25;
	LastUpgradeRemainingMana = 0;
	LastUpgradeMessage = TEXT("");
	SacredPondWaterPurity = 15;
	MaxWaterPurity = 100;
	SpiritEnergy = 0;
	SacredPondLevel = 1;
	RestoreCost = 25;
	BaseRestorePurityAmount = 5;
	FairyRestorePurityBonus = 0;
	LastRestoreRemainingMana = 0;
	LastRestoreMessage = TEXT("");
	FairyHouseLevel = 1;
	FairyResidents = 1;
	FairyWorkersActive = 1;
	FairyName = TEXT("Luna");
	FairyLevel = 1;
	FairyAssignedTask = TEXT("Flower Grove");
	FairyWorkBonus = 3.0f;
	bFairyIsAssigned = true;
	FairyBonusManaProduction = 0.0f;
	ActivePlots = 3;
	MaxPlots = 5;
	LastPlotUnlockRemainingMana = 0;
	LastPlotUnlockMessage = TEXT("");

	UStaticMeshComponent* Mesh = GetStaticMeshComponent();
	if (Mesh)
	{
		Mesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Mesh->SetCollisionObjectType(ECC_WorldDynamic);
		Mesh->SetCollisionResponseToAllChannels(ECR_Block);
	}
}

void AMysticBuildingInteractable::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (BuildingType == EMysticBuildingType::FlowerGrove)
	{
		GenerateManaForSeconds(DeltaSeconds);
	}
}

void AMysticBuildingInteractable::GenerateManaForSeconds(float Seconds)
{
	if (BuildingType != EMysticBuildingType::FlowerGrove || Seconds <= 0.0f)
	{
		return;
	}

	const float MaxMana = static_cast<float>(FMath::Max(MaxStoredMana, 0));
	StoredMana = FMath::Clamp(StoredMana + (Seconds * GetTotalManaProductionRate()), 0.0f, MaxMana);
}

float AMysticBuildingInteractable::GetTotalManaProductionRate() const
{
	return BaseManaProductionRate + FairyBonusManaProduction;
}

bool AMysticBuildingInteractable::UpgradeFlowerGroveWithMana(int32 AvailableMana)
{
	LastUpgradeRemainingMana = AvailableMana;
	LastUpgradeMessage = TEXT("");

	if (BuildingType != EMysticBuildingType::FlowerGrove)
	{
		LastUpgradeMessage = TEXT("Upgrade is only available at the Flower Grove");
		return false;
	}

	if (AvailableMana < UpgradeCost)
	{
		LastUpgradeMessage = TEXT("Not enough mana");
		return false;
	}

	LastUpgradeRemainingMana = AvailableMana - UpgradeCost;
	FlowerGroveLevel += 1;
	BaseManaProductionRate += 2.0f;
	ManaProductionRate = BaseManaProductionRate;
	if (FlowerGroveLevel % 2 == 0)
	{
		MaxStoredMana += 25;
	}
	UpgradeCost = FMath::CeilToInt(static_cast<float>(UpgradeCost) * 1.5f);
	StoredMana = FMath::Clamp(StoredMana, 0.0f, static_cast<float>(MaxStoredMana));
	LastUpgradeMessage = TEXT("Flower Grove upgraded!");
	return true;
}

int32 AMysticBuildingInteractable::GetNextPlotUnlockCost() const
{
	if (BuildingType != EMysticBuildingType::FlowerGrove || ActivePlots >= MaxPlots)
	{
		return 0;
	}

	return ActivePlots <= 3 ? 50 : 100;
}

bool AMysticBuildingInteractable::UnlockNextFlowerPlotWithMana(int32 AvailableMana)
{
	LastPlotUnlockRemainingMana = AvailableMana;
	LastPlotUnlockMessage = TEXT("");

	if (BuildingType != EMysticBuildingType::FlowerGrove)
	{
		LastPlotUnlockMessage = TEXT("Plots can only be unlocked at the Flower Grove");
		return false;
	}

	if (ActivePlots >= MaxPlots)
	{
		LastPlotUnlockMessage = TEXT("All plots unlocked.");
		return false;
	}

	const int32 UnlockCost = GetNextPlotUnlockCost();
	if (AvailableMana < UnlockCost)
	{
		LastPlotUnlockMessage = TEXT("Not enough mana.");
		return false;
	}

	LastPlotUnlockRemainingMana = AvailableMana - UnlockCost;
	ActivePlots = FMath::Clamp(ActivePlots + 1, 0, MaxPlots);
	BaseManaProductionRate += 2.0f;
	ManaProductionRate = BaseManaProductionRate;
	LastPlotUnlockMessage = TEXT("New flower plot unlocked!");
	return true;
}
void AMysticBuildingInteractable::UpdateFairyWorkerBonusFromHouse(const AMysticBuildingInteractable* FairyHouse)
{
	FairyBonusManaProduction = 0.0f;

	if (BuildingType != EMysticBuildingType::FlowerGrove || !FairyHouse || FairyHouse->BuildingType != EMysticBuildingType::FairyHouse)
	{
		return;
	}

	if (FairyHouse->bFairyIsAssigned && FairyHouse->FairyAssignedTask == TEXT("Flower Grove"))
	{
		FairyBonusManaProduction = FMath::Max(FairyHouse->FairyWorkBonus, 0.0f);
	}
}

int32 AMysticBuildingInteractable::CollectStoredMana()
{
	const int32 ManaToCollect = FMath::FloorToInt(StoredMana);
	StoredMana = 0.0f;
	return FMath::Max(ManaToCollect, 0);
}

bool AMysticBuildingInteractable::RestoreSacredPondWithMana(int32 AvailableMana)
{
	LastRestoreRemainingMana = AvailableMana;
	LastRestoreMessage = TEXT("");

	if (BuildingType != EMysticBuildingType::SacredPond)
	{
		LastRestoreMessage = TEXT("Restore is only available at the Sacred Pond");
		return false;
	}

	if (AvailableMana < RestoreCost)
	{
		LastRestoreMessage = TEXT("Not enough mana");
		return false;
	}

	LastRestoreRemainingMana = AvailableMana - RestoreCost;
	SacredPondWaterPurity = FMath::Clamp(SacredPondWaterPurity + BaseRestorePurityAmount + FairyRestorePurityBonus, 0, MaxWaterPurity);
	SpiritEnergy += 10;

	LastRestoreMessage = SacredPondWaterPurity >= MaxWaterPurity
		? TEXT("Pond fully purified for this prototype")
		: TEXT("Pond restored");

	return true;
}




void AMysticBuildingInteractable::UpdateSacredPondFairyBonusFromHouse(const AMysticBuildingInteractable* FairyHouse)
{
	FairyRestorePurityBonus = 0;

	if (BuildingType != EMysticBuildingType::SacredPond || !FairyHouse || FairyHouse->BuildingType != EMysticBuildingType::FairyHouse)
	{
		return;
	}

	if (FairyHouse->bFairyIsAssigned && FairyHouse->FairyAssignedTask == TEXT("Sacred Koi Pond"))
	{
		FairyRestorePurityBonus = 2;
	}
}

void AMysticBuildingInteractable::AssignLunaToTask(const FString& NewAssignedTask)
{
	if (BuildingType != EMysticBuildingType::FairyHouse)
	{
		return;
	}

	if (NewAssignedTask == TEXT("Flower Grove") || NewAssignedTask == TEXT("Sacred Koi Pond"))
	{
		FairyAssignedTask = NewAssignedTask;
		bFairyIsAssigned = true;
		FairyWorkersActive = 1;
		return;
	}

	FairyAssignedTask = TEXT("Unassigned");
	bFairyIsAssigned = false;
	FairyWorkersActive = 0;
}
