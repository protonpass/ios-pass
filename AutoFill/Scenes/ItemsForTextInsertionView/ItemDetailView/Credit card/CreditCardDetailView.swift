//
// CreditCardDetailView.swift
// Proton Pass - Created on 09/10/2024.
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
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreditCardDetailView: View {
    @StateObject private var viewModel: CreditCardDetailViewModel
    @State private var showCardNumber = false
    @State private var showVerificationNumber = false
    @State private var showPIN = false
    let onSelect: (String) -> Void

    private var tintColor: UIColor { viewModel.type.normColor }

    init(item: SelectedItem,
         onSelect: @escaping (String) -> Void) {
        _viewModel = .init(wrappedValue: .init(item: item))
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            cardholderNameRow
            PassSectionDivider()
            cardNumberRow
            PassSectionDivider()
            expirationDateRow
            PassSectionDivider()
            verificationNumberRow
            if !viewModel.pin.isEmpty {
                PassSectionDivider()
                pinRow
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

private extension CreditCardDetailView {
    var cardholderNameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Cardholder name")
                    .sectionTitleText()

                UpsellableDetailText(text: viewModel.cardholderName,
                                     placeholder: #localized("Empty"),
                                     shouldUpgrade: false,
                                     upgradeTextColor: tintColor) {
                    viewModel.upgrade()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.isFreeUser, !viewModel.cardholderName.isEmpty {
                    onSelect(viewModel.cardholderName)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    var cardNumberRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.cardNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()

                UpsellableDetailText(text: showCardNumber ?
                    viewModel.cardNumber.toCreditCardNumber() :
                    viewModel.cardNumber.toMaskedCreditCardNumber(),
                    placeholder: #localized("Empty"),
                    shouldUpgrade: viewModel.isFreeUser,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
                    .animation(.default, value: showCardNumber)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.isFreeUser, !viewModel.cardNumber.isEmpty {
                    onSelect(viewModel.cardNumber)
                }
            }

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: showCardNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.item.content.type.normMajor2Color,
                             backgroundColor: viewModel.item.content.type.normMinor2Color,
                             accessibilityLabel: showCardNumber ? "Hide card number" : "Show card number",
                             action: { showCardNumber.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    var verificationNumberRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.verificationNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security code")
                    .sectionTitleText()

                UpsellableDetailText(text: showVerificationNumber ?
                    viewModel.verificationNumber :
                    String(repeating: "•", count: viewModel.verificationNumber.count),
                    placeholder: #localized("Empty"),
                    shouldUpgrade: viewModel.isFreeUser,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.isFreeUser, !viewModel.verificationNumber.isEmpty {
                    onSelect(viewModel.verificationNumber)
                }
            }
            .animation(.default, value: showVerificationNumber)

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: showVerificationNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.item.content.type.normMajor2Color,
                             backgroundColor: viewModel.item.content.type.normMinor2Color,
                             accessibilityLabel: showVerificationNumber ? "Hide security code" :
                                 "Show security code",
                             action: { showVerificationNumber.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    var pinRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.pin.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.grid3, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("PIN number")
                    .sectionTitleText()

                UpsellableDetailText(text: showPIN ?
                    viewModel.pin : String(repeating: "•", count: viewModel.pin.count),
                    placeholder: nil,
                    shouldUpgrade: false,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .animation(.default, value: showPIN)

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: showPIN ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.item.content.type.normMajor2Color,
                             backgroundColor: viewModel.item.content.type.normMinor2Color,
                             accessibilityLabel: showPIN ? "Hide pin" : "Show pin",
                             action: { showPIN.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var expirationDateRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Expiration date")
                    .sectionTitleText()

                UpsellableDetailText(text: viewModel.expirationDate,
                                     placeholder: nil,
                                     shouldUpgrade: viewModel.isFreeUser,
                                     upgradeTextColor: tintColor) {
                    viewModel.upgrade()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.isFreeUser, !viewModel.expirationDate.isEmpty {
                    onSelect(viewModel.expirationDate)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
