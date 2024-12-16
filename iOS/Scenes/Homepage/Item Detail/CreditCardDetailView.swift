//
// CreditCardDetailView.swift
// Proton Pass - Created on 15/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Core
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreditCardDetailView: View {
    @StateObject private var viewModel: CreditCardDetailViewModel
    @State private var isShowingCardNumber = false
    @State private var isShowingVerificationNumber = false
    @State private var isShowingPIN = false
    @Namespace private var bottomID

    private var tintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: CreditCardDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            realBody
        }
    }
}

private extension CreditCardDetailView {
    var realBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent,
                                        vault: viewModel.vault?.vault)
                        .padding(.bottom, 40)

                    detailSection

                    if !viewModel.itemContent.note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault)
                            .padding(.top, 8)
                    }

                    if viewModel.showFileAttachmentsSection {
                        FileAttachmentsViewSection(files: viewModel.files.fetchedObject ?? [],
                                                   isFetching: viewModel.files.isFetching,
                                                   fetchError: viewModel.files.error,
                                                   handler: viewModel)
                            .padding(.top, 8)
                    }

                    ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                             action: { viewModel.showItemHistory() })

                    ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                              itemContent: viewModel.itemContent,
                                              vault: viewModel.vault?.vault,
                                              onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                        .padding(.top, 24)
                        .id(bottomID)
                }
                .padding()
                .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }
        }
        .itemDetailSetUp(viewModel)
    }
}

private extension CreditCardDetailView {
    var detailSection: some View {
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
            .onTapGesture { viewModel.copyCardholderName() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            if !viewModel.isFreeUser, !viewModel.cardholderName.isEmpty {
                Button { viewModel.copyCardholderName() } label: {
                    Text("Copy")
                }

                Button(action: {
                    viewModel.showLarge(.text(viewModel.cardholderName))
                }, label: {
                    Text("Show large")
                })
            }
        }
    }

    @ViewBuilder
    var cardNumberRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.cardNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()

                UpsellableDetailText(text: isShowingCardNumber ?
                    viewModel.cardNumber.toCreditCardNumber() : viewModel.cardNumber
                    .toMaskedCreditCardNumber(),
                    placeholder: #localized("Empty"),
                    shouldUpgrade: viewModel.isFreeUser,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
                    .animation(.default, value: isShowingCardNumber)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyCardNumber() }

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: isShowingCardNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: isShowingCardNumber ? "Hide card number" : "Show card number",
                             action: { isShowingCardNumber.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            if shouldShowOptions {
                Button(action: {
                    withAnimation {
                        isShowingCardNumber.toggle()
                    }
                }, label: {
                    Text(isShowingCardNumber ? "Conceal" : "Reveal")
                })

                Button { viewModel.copyCardNumber() } label: {
                    Text("Copy")
                }
            }
        }
    }

    @ViewBuilder
    var verificationNumberRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.verificationNumber.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security code")
                    .sectionTitleText()

                UpsellableDetailText(text: isShowingVerificationNumber ?
                    viewModel.verificationNumber :
                    String(repeating: "•", count: viewModel.verificationNumber.count),
                    placeholder: #localized("Empty"),
                    shouldUpgrade: false,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyVerificationNumber() }
            .animation(.default, value: isShowingVerificationNumber)

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: isShowingVerificationNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: isShowingVerificationNumber ? "Hide security code" :
                                 "Show security code",
                             action: { isShowingVerificationNumber.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            if shouldShowOptions {
                Button(action: {
                    withAnimation {
                        isShowingVerificationNumber.toggle()
                    }
                }, label: {
                    Text(isShowingVerificationNumber ? "Conceal" : "Reveal")
                })

                Button { viewModel.copyVerificationNumber() } label: {
                    Text("Copy")
                }
            }
        }
    }

    @ViewBuilder
    var pinRow: some View {
        let shouldShowOptions = !viewModel.isFreeUser && !viewModel.pin.isEmpty
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.grid3, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("PIN number")
                    .sectionTitleText()

                UpsellableDetailText(text: isShowingPIN ?
                    viewModel.pin : String(repeating: "•", count: viewModel.pin.count),
                    placeholder: nil,
                    shouldUpgrade: false,
                    upgradeTextColor: tintColor,
                    onUpgrade: { viewModel.upgrade() })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .animation(.default, value: isShowingPIN)

            Spacer()

            if shouldShowOptions {
                CircleButton(icon: isShowingPIN ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             accessibilityLabel: isShowingPIN ? "Hide pin" : "Show pin",
                             action: { isShowingPIN.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            if shouldShowOptions {
                Button(action: {
                    withAnimation {
                        isShowingPIN.toggle()
                    }
                }, label: {
                    Text(isShowingPIN ? "Conceal" : "Reveal")
                })
            }
        }
    }

    var expirationDateRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Expiration date")
                    .sectionTitleText()

                UpsellableDetailText(text: viewModel.expirationDate,
                                     placeholder: nil,
                                     shouldUpgrade: false,
                                     upgradeTextColor: tintColor) {
                    viewModel.upgrade()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyExpirationDate() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            if !viewModel.isFreeUser {
                Button(action: {
                    viewModel.copyExpirationDate()
                }, label: {
                    Text("Copy")
                })
            }
        }
    }
}
