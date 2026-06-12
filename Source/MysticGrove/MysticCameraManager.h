#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MysticCameraManager.generated.h"

class AMysticBuildingInteractable;
class UCameraComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMysticCameraZoomComplete, AMysticBuildingInteractable*, Building);

UCLASS(Blueprintable)
class MYSTICGROVE_API AMysticCameraManager : public AActor
{
	GENERATED_BODY()

public:
	AMysticCameraManager();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Camera")
	void FocusBuilding(AMysticBuildingInteractable* Building);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Camera")
	void ZoomToBuilding(AMysticBuildingInteractable* Building);

	UFUNCTION(BlueprintCallable, Category = "Mystic Grove|Camera")
	void ReturnToVillage();

	UFUNCTION(BlueprintPure, Category = "Mystic Grove|Camera")
	bool IsFocusedOnBuilding() const;

	UFUNCTION(BlueprintPure, Category = "Mystic Grove|Camera")
	FText GetFocusedBuildingName() const;

	AMysticBuildingInteractable* GetFocusedBuilding() const;

	UCameraComponent* GetCameraComponent() const;

	UPROPERTY(BlueprintAssignable, Category = "Mystic Grove|Camera")
	FMysticCameraZoomComplete OnZoomToBuildingComplete;

private:
	UPROPERTY(VisibleAnywhere, Category = "Mystic Grove|Camera")
	TObjectPtr<USceneComponent> Root;

	UPROPERTY(VisibleAnywhere, Category = "Mystic Grove|Camera")
	TObjectPtr<UCameraComponent> Camera;

	UPROPERTY(EditAnywhere, Category = "Mystic Grove|Camera")
	float MoveSpeed = 4.5f;

	UPROPERTY(EditAnywhere, Category = "Mystic Grove|Camera")
	float RotateSpeed = 5.0f;

	UPROPERTY(EditAnywhere, Category = "Mystic Grove|Camera")
	float ZoomCompletionSeconds = 1.15f;

	FVector VillageLocation;
	FRotator VillageRotation;
	FVector TargetLocation;
	FRotator TargetRotation;
	FText FocusedBuildingName;
	UPROPERTY()
	TObjectPtr<AMysticBuildingInteractable> FocusedBuilding;
	bool bFocusedOnBuilding = false;
	bool bMovingToBuilding = false;
	bool bZoomCompleteSent = false;
	float ZoomElapsedSeconds = 0.0f;
};
