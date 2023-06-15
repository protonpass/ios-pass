//
// CreateEditCreditCardView.swift
// Proton Pass - Created on 13/06/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateEditCreditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditCreditCardViewModel
    @FocusState private var focusedField: Field?
    @State private var selectedNumber = 0
    @State private var isShowingDiscardAlert = false

    private var tintColor: UIColor { viewModel.itemContentType().normMajor1Color }

    enum Field {
        case title, cardholderName, cardNumber, verificationNumber, note
    }

    init(viewModel: CreateEditCreditCardViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            content
        }
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }
}

private extension CreateEditCreditCardView {
    var content: some View {
        ScrollViewReader { _ in
            ScrollView {
                VStack {
                    CreateEditItemTitleSection(
                        title: $viewModel.title,
                        focusedField: $focusedField,
                        field: .title,
                        selectedVault: viewModel.selectedVault,
                        itemContentType: viewModel.itemContentType(),
                        isEditMode: viewModel.mode.isEditMode,
                        onChangeVault: viewModel.changeVault,
                        onSubmit: { focusedField = .cardholderName })

                    cardDetailSection

                    NoteEditSection(note: $viewModel.note,
                                    focusedField: $focusedField,
                                    field: .note)
                }
                .padding()
            }
        }
        .background(PassColor.backgroundNorm.toColor)
        .accentColor(tintColor.toColor) // Remove when dropping iOS 15
        .tint(tintColor.toColor)
        .onFirstAppear {
            if case .create = viewModel.mode {
                if #available(iOS 16, *) {
                    focusedField = .title
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        focusedField = .title
                    }
                }
            }
        }
        .toolbar {
            CreateEditItemToolbar(
                saveButtonTitle: viewModel.saveButtonTitle(),
                isSaveable: viewModel.isSaveable,
                isSaving: viewModel.isSaving,
                itemContentType: viewModel.itemContentType(),
                shouldUpgrade: false,
                onGoBack: {
                    if viewModel.didEditSomething {
                        isShowingDiscardAlert.toggle()
                    } else {
                        dismiss()
                    }
                },
                onUpgrade: {},
                onSave: viewModel.save)
        }
    }
}

private extension CreateEditCreditCardView {
    var cardDetailSection: some View {
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
        .roundedEditableSection()
    }

    var cardholderNameRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Cardholder name")
                    .sectionTitleText()
                TextField("Full name", text: $viewModel.cardholderName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .cardholderName)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .cardNumber }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.cardholderName.isEmpty {
                Button(action: {
                    viewModel.cardholderName = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.cardholderName.isEmpty)
    }

    var cardNumberRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Card number")
                    .sectionTitleText()
                TextField("1234 1234 1234 1234", text: $viewModel.cardNumber)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .cardNumber)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .verificationNumber }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.cardNumber.isEmpty {
                Button(action: {
                    viewModel.cardNumber = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.cardNumber.isEmpty)
    }

    var verificationNumberRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Verification number")
                    .sectionTitleText()
                TextField("123", text: $viewModel.verificationNumber)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .verificationNumber)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .note }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.verificationNumber.isEmpty {
                Button(action: {
                    viewModel.verificationNumber = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: viewModel.verificationNumber.isEmpty)
    }

    var expirationDateRow: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Expires on")
                    .sectionTitleText()
                MonthYearTextField(placeholder: "MM/YYYY",
                                   tintColor: tintColor,
                                   month: $viewModel.month,
                                   year: $viewModel.year)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, kItemDetailSectionPadding)
    }
}
