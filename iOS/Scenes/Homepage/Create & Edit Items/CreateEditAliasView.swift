//
// CreateEditAliasView.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

struct CreateEditAliasView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditAliasViewModel
    @FocusState private var focusedField: Field?
    @State private var lastFocusedField: Field?
    @Namespace private var fileAttachmentsID
    @Namespace private var noteID
    @State private var isShowingAdvancedOptions = false
    @State private var isShowingSlNoteExplanation = false
    @State private var sheetState: AliasOptionsSheetState?

    private var tintColor: UIColor { viewModel.itemContentType.normMajor1Color }

    init(viewModel: CreateEditAliasViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field: CustomFieldTypes {
        case title, prefix, note, simpleLoginNote, senderName
        case custom(CustomField?)

        var customField: CustomField? {
            if case let .custom(customField) = self {
                customField
            } else {
                nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loaded, .loading:
                    content

                case let .error(error):
                    RetryableErrorView(error: error, onRetry: viewModel.getAliasAndAliasOptions)
                        .padding()
                        .toolbar { closeButtonToolbar }
                }
            }
            .background(PassColor.backgroundNorm.toColor)
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("What is a SimpleLogin note?",
               isPresented: $isShowingSlNoteExplanation,
               actions: { Button("OK", action: {}) },
               message: { Text(verbatim: simpleLoginNoteExplanationMessage) })
    }

    private var closeButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: ItemContentType.alias.normMajor2Color,
                         backgroundColor: ItemContentType.alias.normMinor1Color,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.shouldUpgrade {
                        AliasLimitView(backgroundColor: PassColor.aliasInteractionNormMinor1)
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
                                               onSubmit: {
                                                   if case .create = viewModel.mode, isShowingAdvancedOptions {
                                                       focusedField = .prefix
                                                   } else {
                                                       focusedField = .note
                                                   }
                                               })

                    if case .edit = viewModel.mode {
                        aliasReadonlySection
                    } else {
                        aliasPreviewSection
                        if isShowingAdvancedOptions {
                            PrefixSuffixSection(prefix: $viewModel.prefix,
                                                prefixManuallyEdited: $viewModel.prefixManuallyEdited,
                                                focusedField: $focusedField,
                                                field: .prefix,
                                                isLoading: viewModel.state.isLoading,
                                                tintColor: tintColor,
                                                suffixSelection: viewModel.suffixSelection,
                                                prefixError: viewModel.prefixError,
                                                onSubmitPrefix: { focusedField = .note },
                                                onSelectSuffix: {
                                                    sheetState = .suffix($viewModel.suffixSelection)
                                                })
                        } else if viewModel.showAdvancedOptionsTipBanner {
                            advancedOptionsTipBanner
                        }
                    }

                    if !viewModel.mailboxSelection.selectedMailboxes.isEmpty {
                        MailboxSection(mailboxSelection: viewModel.mailboxSelection,
                                       mode: viewModel.mode.isEditMode ? .edit : .create)
                            .onTapGesture {
                                sheetState = .mailbox($viewModel.mailboxSelection, mailboxSelectionTitle)
                            }
                    }

                    NoteEditSection(note: $viewModel.note,
                                    focusedField: $focusedField,
                                    field: .note)
                        .id(noteID)

                    if viewModel.isAliasOwner {
                        if !viewModel.simpleLoginNote.isEmpty {
                            simpleLoginNoteSection
                        }
                        senderNameRow
                    }

                    if viewModel.customTypeEnabled {
                        EditCustomFieldSections(focusedField: $focusedField,
                                                focusedCustomField: viewModel.recentlyAddedOrEditedField,
                                                contentType: .alias,
                                                fields: $viewModel.customFields,
                                                canAddMore: viewModel.canAddMoreCustomFields,
                                                onAddMore: { viewModel.requestAddCustomField(to: nil) },
                                                onEditTitle: viewModel.requestEditCustomFieldTitle,
                                                onUpgrade: { viewModel.upgrade() })
                    }

                    FileAttachmentsEditSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.isFetchingAttachedFiles,
                                               fetchError: viewModel.fetchAttachedFilesError,
                                               isUploading: viewModel.isUploadingFile,
                                               handler: viewModel)
                        .id(fileAttachmentsID)
                }
                .padding()
                .animation(.default, value: viewModel.shouldUpgrade)
                .animation(.default, value: isShowingAdvancedOptions)
                .animation(.default, value: viewModel.mailboxSelection)
                .animation(.default, value: viewModel.alias)
                .animation(.default, value: viewModel.dismissedFileAttachmentsBanner)
                .animation(.default, value: viewModel.showAdvancedOptionsTipBanner)
            }
            .onChange(of: focusedField) { focusedField in
                if case .note = focusedField {
                    withAnimation {
                        proxy.scrollTo(noteID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.note) { _ in
                withAnimation {
                    proxy.scrollTo(noteID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    focusedField = nil
                }
            }
            .toolbar {
                CreateEditKeyboardToolbar(lastFocusedField: $lastFocusedField,
                                          focusedField: focusedField,
                                          onOpenCodeScanner: viewModel.openCodeScanner,
                                          onPasteTotpUri: { viewModel.handlePastingTotpUri(customField: $0) })
            }
        }
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .itemCreateEditSetUp(viewModel)
        .optionalSheet(binding: $sheetState) { state in
            AliasOptionsSheetContent(module: viewModel.module,
                                     preferencesManager: viewModel.preferencesManager,
                                     state: state,
                                     aliasCount: viewModel.aliasCount,
                                     onAddMailbox: viewModel.addMailbox,
                                     onAddDomain: viewModel.addDomain,
                                     onDismiss: { sheetState = nil },
                                     onError: { viewModel.handle($0) })
                .environment(\.colorScheme, colorScheme)
        }
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

    var senderNameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.cardIdentity)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Display name")
                    .editableSectionTitleText(for: viewModel.senderName)

                TextField("Add display name", text: $viewModel.senderName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .senderName)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .submitLabel(.next)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.senderName)
        }
        .animation(.default, value: viewModel.senderName.isEmpty)
        .animation(.default, value: focusedField)
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    private var aliasReadonlySection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Alias address")
                    .sectionTitleText()
                switch viewModel.state {
                case .loading:
                    ZStack {
                        // Dummy text to make ZStack occupy a correct height
                        Text(verbatim: "Dummy text")
                            .opacity(0)
                        SkeletonBlock(tintColor: tintColor)
                            .clipShape(Capsule())
                            .shimmering()
                    }
                default:
                    Text(AttributedString(viewModel.aliasEmail, attributes: .lineBreakHyphenErasing))
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    private var aliasPreviewSection: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.alias, color: tintColor)

            HStack {
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text("You are about to create")
                        .sectionTitleText()

                    if viewModel.prefixError != nil {
                        Text(viewModel.prefix + viewModel.suffix)
                            .foregroundStyle(PassColor.signalDanger.toColor)
                    } else {
                        switch viewModel.state {
                        case .loading:
                            ZStack {
                                // Dummy text to make ZStack occupy a correct height
                                Text(verbatim: "Dummy text")
                                    .opacity(0)
                                SkeletonBlock(tintColor: tintColor)
                                    .clipShape(Capsule())
                                    .shimmering()
                            }

                        default:
                            Text(viewModel.prefix)
                                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                                Text(viewModel.suffix)
                                .adaptiveForegroundStyle(viewModel.itemContentType.normMajor2Color.toColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isShowingAdvancedOptions {
                    ItemDetailSectionIcon(icon: IconProvider.cogWheel, color: PassColor.textWeak)
                        .buttonEmbeded {
                            isShowingAdvancedOptions.toggle()
                            viewModel.dismissAdvancedOptionsTipBanner()
                        }
                }
            }
        }
        .animation(.default, value: viewModel.prefixError)
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    private var advancedOptionsTipBanner: some View {
        TipBanner(configuration: .init(arrowMode: .topRight(padding: 0),
                                       description: "Tap the gear icon to customize the alias the way you want."),
                  onDismiss: viewModel.dismissAdvancedOptionsTipBanner)
    }
}

private extension CreateEditAliasView {
    var simpleLoginNoteSection: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Label(title: {
                    Text("Note • SimpleLogin")
                        .sectionTitleText()
                }, icon: {
                    Image(uiImage: IconProvider.questionCircle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .onTapGesture {
                            isShowingSlNoteExplanation.toggle()
                        }
                })
                .labelStyle(.rightIcon)

                TextEditorWithPlaceholder(text: $viewModel.simpleLoginNote,
                                          focusedField: $focusedField,
                                          field: .simpleLoginNote,
                                          placeholder: #localized("Add note"))
                    .frame(maxWidth: .infinity, maxHeight: 350, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearTextButton(text: $viewModel.simpleLoginNote)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    var simpleLoginNoteExplanationMessage: String {
        // swiftlint:disable line_length
        let phrase1 =
            #localized("In Pass, an item note is encrypted with the item encryption key and only users who have access to the item can view the note.")
        let phrase2 = #localized("Not even Proton or SimpleLogin can see it.")
        let phrase3 =
            #localized("SimpleLogin note is stored together in the same location with alias address and while it is protected by encryption at rest, it isn't E2E encrypted meaning anyone who has access to SimpleLogin database can read it.")
        return [phrase1, phrase2, phrase3].joined(separator: " ")
        // swiftlint:enable line_length
    }
}

private extension CreateEditAliasView {
    var mailboxSelectionTitle: String {
        (viewModel.mode.isEditMode ? MailboxSection.Mode.edit : MailboxSection.Mode.create).title
    }
}
