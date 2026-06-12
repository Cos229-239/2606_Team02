#include "MysticCameraManager.h"

#include "Camera/CameraComponent.h"
#include "MysticBuildingInteractable.h"

AMysticCameraManager::AMysticCameraManager()
{
	PrimaryActorTick.bCanEverTick = true;

	Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	SetRootComponent(Root);

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("VillageCamera"));
	Camera->SetupAttachment(Root);
	Camera->SetProjectionMode(ECameraProjectionMode::Perspective);
	Camera->SetFieldOfView(45.0f);
}

void AMysticCameraManager::BeginPlay()
{
	Super::BeginPlay();

	VillageLocation = GetActorLocation();
	VillageRotation = GetActorRotation();
	TargetLocation = VillageLocation;
	TargetRotation = VillageRotation;
}

void AMysticCameraManager::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	const FVector NewLocation = FMath::VInterpTo(GetActorLocation(), TargetLocation, DeltaSeconds, MoveSpeed);
	const FRotator NewRotation = FMath::RInterpTo(GetActorRotation(), TargetRotation, DeltaSeconds, RotateSpeed);
	SetActorLocationAndRotation(NewLocation, NewRotation);

	if (bMovingToBuilding && !bZoomCompleteSent)
	{
		ZoomElapsedSeconds += DeltaSeconds;
		const bool bLocationReady = FVector::DistSquared(GetActorLocation(), TargetLocation) <= FMath::Square(8.0f);
		const bool bRotationReady = GetActorRotation().Equals(TargetRotation, 1.5f);
		const bool bTimedOutAtTarget = ZoomElapsedSeconds >= ZoomCompletionSeconds;
		if ((bLocationReady && bRotationReady) || bTimedOutAtTarget)
		{
			SetActorLocationAndRotation(TargetLocation, TargetRotation);
			bZoomCompleteSent = true;
			bMovingToBuilding = false;
			OnZoomToBuildingComplete.Broadcast(FocusedBuilding);
		}
	}
}

void AMysticCameraManager::FocusBuilding(AMysticBuildingInteractable* Building)
{
	ZoomToBuilding(Building);
}

void AMysticCameraManager::ZoomToBuilding(AMysticBuildingInteractable* Building)
{
	if (!Building)
	{
		return;
	}

	bFocusedOnBuilding = true;
	bMovingToBuilding = true;
	bZoomCompleteSent = false;
	ZoomElapsedSeconds = 0.0f;
	FocusedBuilding = Building;
	FocusedBuildingName = Building->DisplayName;
	const AActor* ZoomTargetActor = Building->ZoomTarget ? Building->ZoomTarget.Get() : Building;
	const FVector FocusLocation = ZoomTargetActor->GetActorLocation();
	TargetLocation = FocusLocation + Building->ZoomOffset;
	TargetRotation = Building->ZoomTarget && Building->ZoomTarget != Building
		? Building->ZoomTarget->GetActorRotation()
		: (FocusLocation - TargetLocation).Rotation();
}

void AMysticCameraManager::ReturnToVillage()
{
	bFocusedOnBuilding = false;
	bMovingToBuilding = false;
	bZoomCompleteSent = false;
	ZoomElapsedSeconds = 0.0f;
	FocusedBuilding = nullptr;
	FocusedBuildingName = FText::GetEmpty();
	TargetLocation = VillageLocation;
	TargetRotation = VillageRotation;
}

bool AMysticCameraManager::IsFocusedOnBuilding() const
{
	return bFocusedOnBuilding;
}

FText AMysticCameraManager::GetFocusedBuildingName() const
{
	return FocusedBuildingName;
}

AMysticBuildingInteractable* AMysticCameraManager::GetFocusedBuilding() const
{
	return FocusedBuilding;
}

UCameraComponent* AMysticCameraManager::GetCameraComponent() const
{
	return Camera;
}
