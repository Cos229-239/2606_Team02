#include "MysticTutorialPromptWidget.h"

#include "Styling/CoreStyle.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SConstraintCanvas.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/Text/STextBlock.h"

TSharedRef<SWidget> UMysticTutorialPromptWidget::RebuildWidget()
{
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.86f);
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor ButtonColor(0.025f, 0.035f, 0.07f, 1.0f);
	const FLinearColor GoldText(1.0f, 0.86f, 0.34f, 1.0f);

	auto MakePromptButton = [&](const FText& Label, FOnClicked OnClicked)
	{
		return SNew(SBox)
			.WidthOverride(112.0f)
			.HeightOverride(42.0f)
			[
				SNew(SButton)
				.OnClicked(OnClicked)
				.ButtonColorAndOpacity(ButtonColor)
				.ContentPadding(FMargin(14.0f, 8.0f))
				[
					SNew(STextBlock)
					.Text(Label)
					.Justification(ETextJustify::Center)
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 18))
					.ColorAndOpacity(FLinearColor::White)
				]
			];
	};

	TSharedRef<SWidget> PromptPanel =
		SNew(SBorder)
		.BorderBackgroundColor(BorderColor)
		.Padding(FMargin(2.0f))
		[
			SNew(SBorder)
			.BorderBackgroundColor(PanelColor)
			.Padding(FMargin(20.0f, 16.0f))
			[
				SNew(SVerticalBox)
				+ SVerticalBox::Slot()
				.AutoHeight()
				.Padding(FMargin(0.0f, 0.0f, 0.0f, 14.0f))
				[
					SAssignNew(PromptTextBlock, STextBlock)
					.Text(FText::FromString(PromptText))
					.AutoWrapText(true)
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 19))
					.ColorAndOpacity(GoldText)
				]
				+ SVerticalBox::Slot()
				.AutoHeight()
				.HAlign(HAlign_Right)
				[
					SNew(SHorizontalBox)
					+ SHorizontalBox::Slot()
					.AutoWidth()
					.Padding(FMargin(0.0f, 0.0f, 10.0f, 0.0f))
					[
						SAssignNew(NextButtonBox, SBox)
						[
							MakePromptButton(FText::FromString(TEXT("Next")), BIND_UOBJECT_DELEGATE(FOnClicked, HandleNextClicked))
						]
					]
					+ SHorizontalBox::Slot()
					.AutoWidth()
					[
						MakePromptButton(FText::FromString(TEXT("Skip")), BIND_UOBJECT_DELEGATE(FOnClicked, HandleSkipClicked))
					]
				]
			]
		];

	RefreshSlateContent();

	return SNew(SConstraintCanvas)
		+ SConstraintCanvas::Slot()
		.Anchors(FAnchors(0.5f, 1.0f))
		.Alignment(FVector2D(0.5f, 1.0f))
		.Offset(FMargin(0.0f, -36.0f, 560.0f, 132.0f))
		[
			PromptPanel
		];
}

void UMysticTutorialPromptWidget::SetPrompt(const FString& NewPromptText, bool bNewShowNextButton)
{
	PromptText = NewPromptText;
	bShowNextButton = bNewShowNextButton;
	RefreshSlateContent();
}

FReply UMysticTutorialPromptWidget::HandleNextClicked()
{
	OnNextRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticTutorialPromptWidget::HandleSkipClicked()
{
	OnSkipRequested.Broadcast();
	return FReply::Handled();
}

void UMysticTutorialPromptWidget::RefreshSlateContent()
{
	if (PromptTextBlock)
	{
		PromptTextBlock->SetText(FText::FromString(PromptText));
	}

	if (NextButtonBox)
	{
		NextButtonBox->SetVisibility(bShowNextButton ? EVisibility::Visible : EVisibility::Collapsed);
	}
}
