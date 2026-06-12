#include "MysticFairyLoopActor.h"

#include "Components/PointLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "UObject/ConstructorHelpers.h"

AMysticFairyLoopActor::AMysticFairyLoopActor()
{
	PrimaryActorTick.bCanEverTick = true;

	SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
	SetRootComponent(SceneRoot);

	FairyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("FairyMesh"));
	FairyMesh->SetupAttachment(SceneRoot);
	FairyMesh->SetRelativeScale3D(FVector(0.16f, 0.16f, 0.16f));
	FairyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	GlowLight = CreateDefaultSubobject<UPointLightComponent>(TEXT("FairyGlow"));
	GlowLight->SetupAttachment(SceneRoot);
	GlowLight->SetIntensity(160.0f);
	GlowLight->SetAttenuationRadius(170.0f);
	GlowLight->SetLightColor(FColor(255, 220, 120));

	static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	if (SphereMesh.Succeeded())
	{
		FairyMesh->SetStaticMesh(SphereMesh.Object);
	}
}

void AMysticFairyLoopActor::BeginPlay()
{
	Super::BeginPlay();
	BuildPathPoints();
	if (PathPoints.Num() > 0)
	{
		SetActorLocation(PathPoints[0]);
		CurrentPathIndex = 1 % PathPoints.Num();
	}
}

void AMysticFairyLoopActor::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (PathPoints.Num() == 0)
	{
		BuildPathPoints();
		return;
	}

	const FVector TargetLocation = PathPoints[CurrentPathIndex];
	const FVector NewLocation = FMath::VInterpConstantTo(GetActorLocation(), TargetLocation, DeltaSeconds, MoveSpeed);
	SetActorLocation(NewLocation);

	if (FVector::DistSquared(NewLocation, TargetLocation) <= 64.0f)
	{
		CurrentPathIndex = (CurrentPathIndex + 1) % PathPoints.Num();
	}
}

void AMysticFairyLoopActor::BuildPathPoints()
{
	PathPoints.Reset();
	PathPoints.Add(FindLabeledPoint(FairyHouseLabel, FVector(-430.0f, -170.0f, HoverHeight)));
	PathPoints.Add(FindLabeledPoint(FlowerGroveLabel, FVector(520.0f, -180.0f, HoverHeight)));
	PathPoints.Add(FindLabeledPoint(SacredPondLabel, FVector(110.0f, 190.0f, HoverHeight)));
}

FVector AMysticFairyLoopActor::FindLabeledPoint(const FString& TargetActorLabel, const FVector& FallbackLocation) const
{
#if WITH_EDITOR
	if (GetWorld())
	{
		for (TActorIterator<AActor> It(GetWorld()); It; ++It)
		{
			const AActor* Actor = *It;
			if (Actor && Actor->GetActorLabel() == TargetActorLabel)
			{
				return Actor->GetActorLocation() + FVector(0.0f, 0.0f, HoverHeight);
			}
		}
	}
#endif
	return FallbackLocation;
}
