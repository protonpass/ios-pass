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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreditCardDetailView: View {
    @StateObject private var viewModel: CreditCardDetailViewModel
    @State private var isShowingCardNumber = false
    @State private var isShowingVerificationNumber = false
    @State private var isMoreInfoSectionExpanded = false
    @Namespace private var bottomID

    private var tintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: CreditCardDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationView {
                realBody
            }
            .navigationViewStyle(.stack)
        } else {
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
                                        vault: viewModel.vault,
                                        favIconRepository: viewModel.favIconRepository)
                    .padding(.bottom, 40)

                    detailSection

                    if !viewModel.itemContent.note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault,
                                          theme: viewModel.theme,
                                          favIconRepository: viewModel.favIconRepository)
                        .padding(.top, 8)
                    }

                    ItemDetailMoreInfoSection(isExpanded: $isMoreInfoSectionExpanded,
                                              itemContent: viewModel.itemContent)
                    .padding(.top, 24)
                    .id(bottomID)
                }
                .padding()
                .onChange(of: isMoreInfoSectionExpanded) { _ in
                    withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }
        }
        .animation(.default, value: isMoreInfoSectionExpanded)
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar {
            ItemDetailToolbar(isShownAsSheet: viewModel.isShownAsSheet,
                              itemContent: viewModel.itemContent,
                              onGoBack: viewModel.goBack,
                              onEdit: viewModel.edit,
                              onMoveToAnotherVault: viewModel.moveToAnotherVault,
                              onMoveToTrash: viewModel.moveToTrash,
                              onRestore: viewModel.restore,
                              onPermanentlyDelete: viewModel.permanentlyDelete)
        }
    }
}

private extension CreditCardDetailView {
    var detailSection: some View {
        VStack(spacing: kItemDetailSectionPadding) {
            cardholderNameRow
            PassSectionDivider()
            cardNumberRow
            PassSectionDivider()
            verificationNumberRow
            PassSectionDivider()
            expirationDateRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedDetailSection()
    }

    var cardholderNameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Cardholder name")
                    .sectionTitleText()

                Text(viewModel.cardholderName)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyCardholderName)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: viewModel.copyCardholderName) {
                Text("Copy")
            }

            Button(action: {
                viewModel.showLarge(viewModel.cardholderName)
            }, label: {
                Text("Show large")
            })
        }
    }

    var cardNumberRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()

                if viewModel.cardNumber.isEmpty {
                    Text("Empty credit card number")
                        .placeholderText()
                } else {
                    Text(isShowingCardNumber ?
                         viewModel.cardNumber : viewModel.cardNumber.toMaskedCreditCardNumber())
                        .sectionContentText()
                        .animation(.default, value: isShowingCardNumber)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyCardNumber)

            Spacer()

            if !viewModel.cardNumber.isEmpty {
                CircleButton(icon: isShowingCardNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             action: { isShowingCardNumber.toggle() })
                .fixedSize(horizontal: true, vertical: true)
                .animationsDisabled()
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    isShowingCardNumber.toggle()
                }
            }, label: {
                Text(isShowingCardNumber ? "Conceal" : "Reveal")
            })

            Button(action: viewModel.copyCardNumber) {
                Text("Copy")
            }
        }
    }

    var verificationNumberRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard, color: tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Verification number")
                    .sectionTitleText()

                if viewModel.cardNumber.isEmpty {
                    Text("Empty verification number")
                        .placeholderText()
                } else {
                    if isShowingVerificationNumber {
                        Text(viewModel.verificationNumber)
                            .sectionContentText()
                    } else {
                        Text(String(repeating: "•", count: viewModel.verificationNumber.count))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.copyVerificationNumber)
            .animation(.default, value: isShowingVerificationNumber)

            Spacer()

            if !viewModel.verificationNumber.isEmpty {
                CircleButton(icon: isShowingVerificationNumber ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.itemContent.type.normMajor2Color,
                             backgroundColor: viewModel.itemContent.type.normMinor2Color,
                             action: { isShowingVerificationNumber.toggle() })
                .fixedSize(horizontal: true, vertical: true)
                .animationsDisabled()
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .contextMenu {
            Button(action: {
                withAnimation {
                    isShowingVerificationNumber.toggle()
                }
            }, label: {
                Text(isShowingVerificationNumber ? "Conceal" : "Reveal")
            })

            Button(action: viewModel.copyVerificationNumber) {
                Text("Copy")
            }
        }
    }

    var expirationDateRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay, color: tintColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Expires on")
                    .sectionTitleText()

                Text(viewModel.expirationDate)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }
}
