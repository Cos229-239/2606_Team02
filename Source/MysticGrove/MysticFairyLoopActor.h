#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MysticFairyLoopActor.generated.h"

class UPointLightComponent;
class UStaticMeshComponent;

UCLASS(Blueprintable)
class MYSTICGROVE_API AMysticFairyLoopActor : public AActor
{
	GENERATED_BODY()

public:
	AMysticFairyLoopActor();
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Loop")
	FString FairyHouseLabel = TEXT("Fairy House");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Loop")
	FString FlowerGroveLabel = TEXT("Flower Grove");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Loop")
	FString SacredPondLabel = TEXT("Sacred Koi Pond");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Loop")
	float MoveSpeed = 110.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mystic Grove|Fairy Loop")
	float HoverHeight = 95.0f;

private:
	UPROPERTY(VisibleAnywhere, Category = "Mystic Grove|Fairy Loop")
	TObjectPtr<USceneComponent> SceneRoot;

	UPROPERTY(VisibleAnywhere, Category = "Mystic Grove|Fairy Loop")
	TObjectPtr<UStaticMeshComponent> FairyMesh;

	UPROPERTY(VisibleAnywhere, Category = "Mystic Grove|Fairy Loop")
	TObjectPtr<UPointLightComponent> GlowLight;

	TArray<FVector> PathPoints;
	int32 CurrentPathIndex = 0;

	void BuildPathPoints();
	FVector FindLabeledPoint(const FString& TargetActorLabel, const FVector& FallbackLocation) const;
};
