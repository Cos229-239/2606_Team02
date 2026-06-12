#include "MysticStartScreenWidget.h"

#include "Styling/CoreStyle.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/SOverlay.h"
#include "Widgets/Text/STextBlock.h"

TSharedRef<SWidget> UMysticStartScreenWidget::RebuildWidget()
{
	const FLinearColor BackdropColor(0.0f, 0.012f, 0.026f, 0.88f);
	const FLinearColor PanelColor(0.015f, 0.025f, 0.055f, 0.88f);
	const FLinearColor BorderColor(0.86f, 0.62f, 0.20f, 0.95f);
	const FLinearColor ButtonColor(0.025f, 0.035f, 0.07f, 1.0f);
	const FLinearColor GoldText(1.0f, 0.86f, 0.34f, 1.0f);

	auto MakeStartButton = [&](const FText& Label, FOnClicked OnClicked)
	{
		return SNew(SBox)
			.WidthOverride(260.0f)
			.HeightOverride(58.0f)
			[
				SNew(SButton)
				.OnClicked(OnClicked)
				.ButtonColorAndOpacity(ButtonColor)
				.ContentPadding(FMargin(18.0f, 12.0f))
				[
					SNew(STextBlock)
					.Text(Label)
					.Justification(ETextJustify::Center)
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 24))
					.ColorAndOpacity(FLinearColor::White)
				]
			];
	};

	return SNew(SOverlay)
		+ SOverlay::Slot()
		.HAlign(HAlign_Fill)
		.VAlign(VAlign_Fill)
		[
			SNew(SBorder)
			.BorderBackgroundColor(BackdropColor)
		]
		+ SOverlay::Slot()
		.HAlign(HAlign_Center)
		.VAlign(VAlign_Center)
		[
			SNew(SBorder)
			.BorderBackgroundColor(BorderColor)
			.Padding(FMargin(3.0f))
			[
				SNew(SBorder)
				.BorderBackgroundColor(PanelColor)
				.Padding(FMargin(72.0f, 48.0f))
				[
					SNew(SVerticalBox)
					+ SVerticalBox::Slot()
					.AutoHeight()
					.HAlign(HAlign_Center)
					.Padding(FMargin(0.0f, 0.0f, 0.0f, 10.0f))
					[
						SNew(STextBlock)
						.Text(FText::FromString(TEXT("Mystic Grove")))
						.Font(FCoreStyle::GetDefaultFontStyle("Bold", 44))
						.ColorAndOpacity(GoldText)
					]
					+ SVerticalBox::Slot()
					.AutoHeight()
					.HAlign(HAlign_Center)
					.Padding(FMargin(0.0f, 0.0f, 0.0f, 42.0f))
					[
						SNew(STextBlock)
						.Text(FText::FromString(TEXT("Week 1 Demo")))
						.Font(FCoreStyle::GetDefaultFontStyle("Regular", 18))
						.ColorAndOpacity(FLinearColor::White)
					]
					+ SVerticalBox::Slot()
					.AutoHeight()
					.HAlign(HAlign_Center)
					.Padding(FMargin(0.0f, 0.0f, 0.0f, 18.0f))
					[
						MakeStartButton(FText::FromString(TEXT("Play")), BIND_UOBJECT_DELEGATE(FOnClicked, HandlePlayClicked))
					]
					+ SVerticalBox::Slot()
					.AutoHeight()
					.HAlign(HAlign_Center)
					.Padding(FMargin(0.0f, 0.0f, 0.0f, 18.0f))
					[
						MakeStartButton(FText::FromString(TEXT("Reset Save")), BIND_UOBJECT_DELEGATE(FOnClicked, HandleResetSaveClicked))
					]
					+ SVerticalBox::Slot()
					.AutoHeight()
					.HAlign(HAlign_Center)
					[
						MakeStartButton(FText::FromString(TEXT("Quit")), BIND_UOBJECT_DELEGATE(FOnClicked, HandleQuitClicked))
					]
				]
			]
		];
}

FReply UMysticStartScreenWidget::HandlePlayClicked()
{
	OnPlayRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticStartScreenWidget::HandleResetSaveClicked()
{
	OnResetSaveRequested.Broadcast();
	return FReply::Handled();
}

FReply UMysticStartScreenWidget::HandleQuitClicked()
{
	OnQuitRequested.Broadcast();
	return FReply::Handled();
}
