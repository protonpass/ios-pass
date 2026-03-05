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

    private var tintColor: Color {
        viewModel.type.normColor
    }

    init(_ viewModel: CreditCardDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
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

        if !viewModel.item.content.note.isEmpty {
            NoteDetailSection(itemContent: viewModel.item.content,
                              vault: nil)
        }
        CustomFieldSections(itemContentType: viewModel.type,
                            fields: viewModel.customFields,
                            isFreeUser: viewModel.isFreeUser,
                            onSelectHiddenText: viewModel.autofill,
                            onSelectTotpToken: viewModel.autofill,
                            onUpgrade: viewModel.upgrade)
    }
}

private extension CreditCardDetailView {
    var cardholderNameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Cardholder name")
                    .sectionTitleText()

                if viewModel.cardholderName.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.cardholderName)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.cardholderName.isEmpty {
                    viewModel.autofill(viewModel.cardholderName)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    @ViewBuilder
    var cardNumberRow: some View {
        let shouldShowOptions = !viewModel.cardNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()

                Text(showCardNumber ?
                    viewModel.cardNumber.toCreditCardNumber() :
                    viewModel.cardNumber.toMaskedCreditCardNumber())
                    .sectionContentText()
                    .animation(.default, value: showCardNumber)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if shouldShowOptions {
                    viewModel.autofill(viewModel.cardNumber)
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
        let shouldShowOptions = !viewModel.verificationNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security code")
                    .sectionTitleText()

                Text(showVerificationNumber ?
                    viewModel.verificationNumber :
                    String(repeating: "•", count: viewModel.verificationNumber.count))
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if shouldShowOptions {
                    viewModel.autofill(viewModel.verificationNumber)
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
        let shouldShowOptions = !viewModel.pin.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.grid3, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("PIN number")
                    .sectionTitleText()

                Text(showPIN ? viewModel.pin : String(repeating: "•", count: viewModel.pin.count))
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

                if viewModel.expirationDate.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.expirationDate)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.expirationDate.isEmpty {
                    viewModel.autofill(viewModel.expirationDate)
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
