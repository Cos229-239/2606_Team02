#include "MysticBuildingScreenWidget.h"

#include "Widgets/Input/SButton.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/SOverlay.h"
#include "Widgets/SBoxPanel.h"
#include "Styling/AppStyle.h"
#include "Widgets/Text/STextBlock.h"

TSharedRef<SWidget> UMysticBuildingScreenWidget::RebuildWidget()
{
	FadeAlpha = 0.0f;
	bFadingOut = false;
	bFadeOutFinished = false;
	SetRenderOpacity(FadeAlpha);

	return SNew(SOverlay)
		+ SOverlay::Slot()
		.HAlign(HAlign_Fill)
		.VAlign(VAlign_Fill)
		[
			SNew(SBorder)
			.BorderBackgroundColor(FLinearColor(0.0f, 0.0f, 0.0f, 0.12f))
			.Padding(FMargin(0.0f))
		]
		+ SOverlay::Slot()
		.HAlign(HAlign_Fill)
		.VAlign(VAlign_Top)
		.Padding(FMargin(36.0f, 28.0f, 36.0f, 0.0f))
		[
			SNew(SBorder)
			.BorderBackgroundColor(FLinearColor(1.0f, 0.75f, 0.24f, 0.95f))
			.Padding(FMargin(3.0f))
			[
				SNew(SBorder)
				.BorderBackgroundColor(FLinearColor(0.015f, 0.025f, 0.055f, 0.75f))
				.Padding(FMargin(28.0f, 20.0f))
				[
					SNew(SHorizontalBox)
					+ SHorizontalBox::Slot()
					.FillWidth(0.42f)
					.VAlign(VAlign_Center)
					[
						SAssignNew(TitleText, STextBlock)
						.Text(BuildingTitle)
						.Font(FCoreStyle::GetDefaultFontStyle("Bold", 34))
						.Justification(ETextJustify::Left)
						.ColorAndOpacity(FLinearColor(1.0f, 0.86f, 0.34f, 1.0f))
					]
					+ SHorizontalBox::Slot()
					.FillWidth(0.58f)
					.VAlign(VAlign_Center)
					[
						SAssignNew(BodyText, STextBlock)
						.Text(PlaceholderContent)
						.Font(FCoreStyle::GetDefaultFontStyle("Bold", 22))
						.AutoWrapText(true)
						.Justification(ETextJustify::Right)
						.ColorAndOpacity(FLinearColor(0.96f, 0.98f, 1.0f, 1.0f))
					]
				]
			]
		]
		+ SOverlay::Slot()
		.HAlign(HAlign_Center)
		.VAlign(VAlign_Bottom)
		.Padding(FMargin(0.0f, 0.0f, 0.0f, 34.0f))
		[
			SNew(SBorder)
			.BorderBackgroundColor(FLinearColor(1.0f, 0.75f, 0.24f, 0.95f))
			.Padding(FMargin(3.0f))
			[
				SNew(SBorder)
				.BorderBackgroundColor(FLinearColor(0.015f, 0.025f, 0.055f, 0.75f))
				.Padding(FMargin(24.0f, 18.0f))
				[
					SNew(SHorizontalBox)
					+ SHorizontalBox::Slot()
					.AutoWidth()
					.Padding(FMargin(10.0f, 0.0f))
					[
						SNew(SButton)
						.OnClicked(BIND_UOBJECT_DELEGATE(FOnClicked, HandleFirstActionClicked))
						.ButtonColorAndOpacity(FLinearColor(0.025f, 0.035f, 0.07f, 1.0f))
						.ContentPadding(FMargin(48.0f, 20.0f))
								[
									SAssignNew(FirstActionText, STextBlock)
									.Text(FirstActionLabel)
									.Font(FCoreStyle::GetDefaultFontStyle("Bold", 22))
									.ColorAndOpacity(FLinearColor::White)
								]
					]
					+ SHorizontalBox::Slot()
					.AutoWidth()
					.Padding(FMargin(10.0f, 0.0f))
					[
						SNew(SButton)
						.OnClicked(BIND_UOBJECT_DELEGATE(FOnClicked, HandleSecondActionClicked))
						.Visibility_Lambda([this]()
						{
							return SecondActionLabel.IsEmpty() ? EVisibility::Collapsed : EVisibility::Visible;
						})
						.ButtonColorAndOpacity(FLinearColor(0.025f, 0.035f, 0.07f, 1.0f))
						.ContentPadding(FMargin(48.0f, 20.0f))
								[
									SAssignNew(SecondActionText, STextBlock)
									.Text(SecondActionLabel)
									.Font(FCoreStyle::GetDefaultFontStyle("Bold", 22))
									.ColorAndOpacity(FLinearColor::White)
								]
					]
					+ SHorizontalBox::Slot()
					.AutoWidth()
					.Padding(FMargin(10.0f, 0.0f))
					[
						SNew(SButton)
						.OnClicked(BIND_UOBJECT_DELEGATE(FOnClicked, HandleThirdActionClicked))
						.Visibility_Lambda([this]()
						{
							return ThirdActionLabel.IsEmpty() ? EVisibility::Collapsed : EVisibility::Visible;
						})
						.ButtonColorAndOpacity(FLinearColor(0.025f, 0.035f, 0.07f, 1.0f))
						.ContentPadding(FMargin(48.0f, 20.0f))
								[
									SAssignNew(ThirdActionText, STextBlock)
									.Text(ThirdActionLabel)
									.Font(FCoreStyle::GetDefaultFontStyle("Bold", 22))
									.ColorAndOpacity(FLinearColor::White)
								]
					]
					+ SHorizontalBox::Slot()
					.AutoWidth()
					.Padding(FMargin(10.0f, 0.0f))
					[
						SNew(SButton)
						.OnClicked(BIND_UOBJECT_DELEGATE(FOnClicked, HandleBackClicked))
						.ButtonColorAndOpacity(FLinearColor(0.025f, 0.035f, 0.07f, 1.0f))
						.ContentPadding(FMargin(58.0f, 20.0f))
						[
							SNew(STextBlock)
							.Text(FText::FromString(TEXT("Back")))
							.Font(FCoreStyle::GetDefaultFontStyle("Bold", 22))
							.ColorAndOpacity(FLinearColor::White)
						]
					]
				]
			]
		];
}

void UMysticBuildingScreenWidget::ReleaseSlateResources(bool bReleaseChildren)
{
	Super::ReleaseSlateResources(bReleaseChildren);
	TitleText.Reset();
	BodyText.Reset();
	FirstActionText.Reset();
	SecondActionText.Reset();
	ThirdActionText.Reset();
}

void UMysticBuildingScreenWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);

	if (bFadingOut)
	{
		const float Step = FadeOutSeconds > 0.0f ? InDeltaTime / FadeOutSeconds : 1.0f;
		FadeAlpha = FMath::Clamp(FadeAlpha - Step, 0.0f, 1.0f);
		SetRenderOpacity(FadeAlpha);

		if (FadeAlpha <= 0.0f && !bFadeOutFinished)
		{
			bFadeOutFinished = true;
			OnBackRequested.Broadcast();
		}
		return;
	}

	const float Step = FadeInSeconds > 0.0f ? InDeltaTime / FadeInSeconds : 1.0f;
	FadeAlpha = FMath::Clamp(FadeAlpha + Step, 0.0f, 1.0f);
	SetRenderOpacity(FadeAlpha);
}

void UMysticBuildingScreenWidget::SetScreenText(const FText& NewTitle, const FText& NewBody)
{
	BuildingTitle = NewTitle;
	PlaceholderContent = NewBody;

	if (TitleText)
	{
		TitleText->SetText(BuildingTitle);
	}

	if (BodyText)
	{
		BodyText->SetText(PlaceholderContent);
	}
}

void UMysticBuildingScreenWidget::SetActionButtonText(const FText& FirstActionTextValue, const FText& SecondActionTextValue, const FText& ThirdActionTextValue)
{
	FirstActionLabel = FirstActionTextValue;
	SecondActionLabel = SecondActionTextValue;
	ThirdActionLabel = ThirdActionTextValue;

	if (FirstActionText)
	{
		FirstActionText->SetText(FirstActionLabel);
	}

	if (SecondActionText)
	{
		SecondActionText->SetText(SecondActionLabel);
	}

	if (ThirdActionText)
	{
		ThirdActionText->SetText(ThirdActionLabel);
	}
}

void UMysticBuildingScreenWidget::StartFadeOut()
{
	if (bFadingOut)
	{
		return;
	}

	bFadingOut = true;
	bFadeOutFinished = false;
}

FReply UMysticBuildingScreenWidget::HandleFirstActionClicked()
{
	OnFirstActionRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticBuildingScreenWidget::HandleSecondActionClicked()
{
	OnSecondActionRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticBuildingScreenWidget::HandleThirdActionClicked()
{
	OnThirdActionRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticBuildingScreenWidget::HandleBackClicked()
{
	StartFadeOut();
	return FReply::Handled();
}


