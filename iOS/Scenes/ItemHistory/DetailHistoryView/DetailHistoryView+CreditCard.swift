//
// DetailHistoryView+CreditCard.swift
// Proton Pass - Created on 16/01/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

extension DetailHistoryView {
    var creditCardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            titleRow(itemContent: itemContent)

            if let item = itemContent.creditCardItem {
                detailSection(creditCardItem: item)
            }

            noteFields(item: itemContent)
                .padding(.top, 8)

            attachmentsSection(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

private extension DetailHistoryView {
    func detailSection(creditCardItem: CreditCardData) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            cardholderNameRow(creditCardItem: creditCardItem)
            PassSectionDivider()
            cardNumberRow(creditCardItem: creditCardItem)
            PassSectionDivider()
            expirationDateRow(creditCardItem: creditCardItem)
            PassSectionDivider()
            verificationNumberRow(creditCardItem: creditCardItem)
            PassSectionDivider()
            pinRow(creditCardItem: creditCardItem)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    func cardholderNameRow(creditCardItem: CreditCardData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Cardholder name")
                    .sectionTitleText()
                Text(creditCardItem.cardholderName)
                    .foregroundStyle(textColor(for: \.creditCardItem?.cardholderName).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyCardholderName() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    func cardNumberRow(creditCardItem: CreditCardData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()

                Text(isShowingCardNumber ? creditCardItem.number.toCreditCardNumber() :
                    creditCardItem.number.toMaskedCreditCardNumber())
                    .foregroundStyle(textColor(for: \.creditCardItem?.number).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyCardNumber() }

            Spacer()

            CircleButton(icon: isShowingCardNumber ? IconProvider.eyeSlash : IconProvider.eye,
                         iconColor: viewModel.currentRevision.type.normMajor2Color,
                         backgroundColor: viewModel.currentRevision.type.normMinor2Color,
                         accessibilityLabel: isShowingCardNumber ? "Hide card number" : "Show card number",
                         action: { isShowingCardNumber.toggle() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    func verificationNumberRow(creditCardItem: CreditCardData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security code")
                    .sectionTitleText()

                Text(isShowingVerificationNumber ? creditCardItem.verificationNumber :
                    String(repeating: "•", count: creditCardItem.verificationNumber.count))
                    .foregroundStyle(textColor(for: \.creditCardItem?.verificationNumber).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .animation(.default, value: isShowingVerificationNumber)
            .onTapGesture { viewModel.copySecurityCode() }

            Spacer()

            CircleButton(icon: isShowingVerificationNumber ? IconProvider.eyeSlash : IconProvider.eye,
                         iconColor: viewModel.currentRevision.type.normMajor2Color,
                         backgroundColor: viewModel.currentRevision.type.normMinor2Color,
                         accessibilityLabel: isShowingVerificationNumber ? "Hide security code" :
                             "Show security code",
                         action: { isShowingVerificationNumber.toggle() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    func pinRow(creditCardItem: CreditCardData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.grid3, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("PIN number")
                    .sectionTitleText()

                Text(isShowingPIN ? creditCardItem.pin :
                    String(repeating: "•", count: creditCardItem.pin.count))
                    .foregroundStyle(textColor(for: \.creditCardItem?.verificationNumber).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .animation(.default, value: isShowingPIN)

            Spacer()

            CircleButton(icon: isShowingPIN ? IconProvider.eyeSlash : IconProvider.eye,
                         iconColor: viewModel.currentRevision.type.normMajor2Color,
                         backgroundColor: viewModel.currentRevision.type.normMinor2Color,
                         accessibilityLabel: isShowingVerificationNumber ? "Hide pin" : "Show pin",
                         action: { isShowingPIN.toggle() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func expirationDateRow(creditCardItem: CreditCardData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Expiration date")
                    .sectionTitleText()

                Text(creditCardItem.displayedExpirationDate)
                    .foregroundStyle(textColor(for: \.creditCardItem?.expirationDate).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyExpirationDate() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
