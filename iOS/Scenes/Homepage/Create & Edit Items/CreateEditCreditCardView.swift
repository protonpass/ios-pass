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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditCreditCardView: View {
    @StateObject private var viewModel: CreateEditCreditCardViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?
    @Namespace private var fileAttachmentsID

    private var tintColor: UIColor { viewModel.itemContentType.normMajor1Color }

    enum Field: CustomFieldTypes {
        case title, cardholderName, cardNumber, verificationNumber, pin, note
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }
    }

    init(viewModel: CreateEditCreditCardViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
        }
    }
}

private extension CreateEditCreditCardView {
    var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    if viewModel.shouldUpgrade {
                        upsellBanner
                    } else {
                        FileAttachmentsBanner(isShown: !viewModel.dismissedFileAttachmentsBanner,
                                              onTap: {
                                                  viewModel.dismissFileAttachmentsBanner()
                                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                      proxy.scrollTo(fileAttachmentsID, anchor: .bottom)
                                                  }
                                              },
                                              onClose: { viewModel.dismissFileAttachmentsBanner() })
                    }

                    CreateEditItemTitleSection(title: $viewModel.title,
                                               focusedField: $focusedField,
                                               field: .title,
                                               itemContentType: viewModel.itemContentType,
                                               isEditMode: viewModel.mode.isEditMode,
                                               onSubmit: { focusedField = .cardholderName })

                    cardDetailSection

                    NoteEditSection(note: $viewModel.note,
                                    focusedField: $focusedField,
                                    field: .note)

                    EditCustomFieldSections(focusedField: $focusedField,
                                            focusedCustomField: viewModel.recentlyAddedOrEditedField,
                                            contentType: .creditCard,
                                            fields: $viewModel.customFields,
                                            canAddMore: viewModel.canAddMoreCustomFields,
                                            onAddMore: { viewModel.requestAddCustomField(to: nil) },
                                            onEditTitle: viewModel.requestEditCustomFieldTitle,
                                            onUpgrade: { viewModel.upgrade() })

                    FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.isFetchingAttachedFiles,
                                               fetchError: viewModel.fetchAttachedFilesError,
                                               isUploading: viewModel.isUploadingFile,
                                               handler: viewModel)
                        .id(fileAttachmentsID)
                }
                .padding()
                .animation(.default, value: viewModel.dismissedFileAttachmentsBanner)
            }
        }
        .toolbar {
            CreateEditKeyboardToolbar(lastFocusedField: $lastFocusedField,
                                      focusedField: focusedField,
                                      onOpenCodeScanner: viewModel.openCodeScanner,
                                      onPasteTotpUri: { viewModel.handlePastingTotpUri(customField: $0) })
        }
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .itemCreateEditSetUp(viewModel)
        .scannerSheet(isPresented: $viewModel.isShowingScanner,
                      interpreter: viewModel.interpretor,
                      resultStream: viewModel.scanResponsePublisher)
        .sheet(isPresented: $viewModel.isShowingCodeScanner) {
            WrappedCodeScannerView { result in
                switch lastFocusedField {
                case let .custom(value) where value?.type == .totp:
                    viewModel.handleScanResult(result, customField: value)
                default:
                    return
                }
            }
        }
    }

    var upsellBanner: some View {
        Text("Upgrade to create credit cards")
            .padding()
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PassColor.cardInteractionNormMinor1.toColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private extension CreateEditCreditCardView {
    var cardDetailSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            cardholderNameRow
            PassSectionDivider()
            cardNumberRow
            PassSectionDivider()
            expirationDateRow
            PassSectionDivider()
            verificationNumberRow
            PassSectionDivider()
            pinRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    var cardholderNameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Cardholder name")
                    .editableSectionTitleText(for: viewModel.cardholderName)
                TextField("Name on card", text: $viewModel.cardholderName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .cardholderName)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .cardNumber }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.cardholderName)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.cardholderName.isEmpty)
    }

    var cardNumberRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.creditCard)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Card number")
                    .editableSectionTitleText(for: viewModel.cardNumber)
                WrappedUITextField(text: $viewModel.cardNumber,
                                   placeHolder: "1234 1234 1234 1234") { isEditing in
                    guard !isEditing else {
                        return
                    }
                    focusedField = .verificationNumber
                }.focused($focusedField, equals: .cardNumber)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.cardNumber)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.cardNumber.isEmpty)
    }

    var verificationNumberRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.shieldCheck)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Security code")
                    .editableSectionTitleText(for: viewModel.verificationNumber)

                SensitiveTextField(text: $viewModel.verificationNumber,
                                   placeholder: "123",
                                   focusedField: $focusedField,
                                   field: .verificationNumber)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .pin }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.verificationNumber)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.verificationNumber.isEmpty)
    }

    var pinRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.grid3)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("PIN Code")
                    .editableSectionTitleText(for: viewModel.pin)

                SensitiveTextField(text: $viewModel.pin,
                                   placeholder: "123456",
                                   focusedField: $focusedField,
                                   field: .pin)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .note }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.pin)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.verificationNumber.isEmpty)
    }

    var expirationDateRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarDay)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Expiration date")
                    .editableSectionTitleText(for: viewModel.monthYear)
                MonthYearTextField(placeholder: #localized("MM / YY"),
                                   tintColor: tintColor,
                                   month: $viewModel.month,
                                   year: $viewModel.year)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
