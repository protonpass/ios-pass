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

import Client
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditAliasView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEditAliasViewModel
    @FocusState private var focusedField: Field?
    @Namespace private var noteID
    @State private var isShowingAdvancedOptions = false
    @State private var isShowingDiscardAlert = false

    private var tintColor: UIColor { viewModel.itemContentType().normMajor1Color }

    init(viewModel: CreateEditAliasViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    enum Field {
        case title, prefix, note
    }

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .loaded, .loading:
                    content

                case let .error(error):
                    RetryableErrorView(errorMessage: error.localizedDescription) {
                        viewModel.getAliasAndAliasOptions()
                    }
                    .padding()
                    .toolbar { closeButtonToolbar }
                }
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .obsoleteItemAlert(isPresented: $viewModel.isObsolete, onAction: dismiss.callAsFunction)
        .discardChangesAlert(isPresented: $isShowingDiscardAlert, onDiscard: dismiss.callAsFunction)
    }

    private var closeButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: ItemContentType.alias.normMajor2Color,
                         backgroundColor: ItemContentType.alias.normMinor1Color,
                         action: dismiss.callAsFunction)
        }
    }

    private var content: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.shouldUpgrade {
                        AliasLimitView(backgroundColor: PassColor.aliasInteractionNormMinor1)
                    }

                    CreateEditItemTitleSection(title: $viewModel.title,
                                               focusedField: $focusedField,
                                               field: .title,
                                               selectedVault: viewModel.selectedVault,
                                               itemContentType: viewModel.itemContentType(),
                                               isEditMode: viewModel.mode.isEditMode,
                                               onChangeVault: { viewModel.changeVault() },
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
                        if isShowingAdvancedOptions, let suffixSelection = viewModel.suffixSelection {
                            PrefixSuffixSection(prefix: $viewModel.prefix,
                                                prefixManuallyEdited: $viewModel.prefixManuallyEdited,
                                                focusedField: $focusedField,
                                                field: .prefix,
                                                isLoading: viewModel.state.isLoading,
                                                tintColor: tintColor,
                                                suffixSelection: suffixSelection,
                                                prefixError: viewModel.prefixError,
                                                onSubmitPrefix: { focusedField = .note },
                                                onSelectSuffix: { viewModel.showSuffixSelection() })
                        } else {
                            AdvancedOptionsSection(isShowingAdvancedOptions: $isShowingAdvancedOptions)
                                .padding(.vertical)
                        }
                    }

                    if let mailboxSelection = viewModel.mailboxSelection {
                        MailboxSection(mailboxSelection: mailboxSelection,
                                       mode: viewModel.mode.isEditMode ? .edit : .create)
                            .onTapGesture { viewModel.showMailboxSelection() }
                    }

                    NoteEditSection(note: $viewModel.note,
                                    focusedField: $focusedField,
                                    field: .note)
                        .id(noteID)
                }
                .padding()
                .animation(.default, value: viewModel.shouldUpgrade)
                .animation(.default, value: isShowingAdvancedOptions)
                .animation(.default, value: viewModel.mailboxSelection != nil)
            }
            .onChange(of: focusedField) { focusedField in
                if case .note = focusedField {
                    withAnimation {
                        value.scrollTo(noteID, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.note) { _ in
                withAnimation {
                    value.scrollTo(noteID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isSaving) { isSaving in
                if isSaving {
                    focusedField = nil
                }
            }
        }
        .tint(tintColor.toColor)
        .onFirstAppear {
            if case .create = viewModel.mode {
                focusedField = .title
            }
        }
        .toolbar {
            CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
                                  isSaveable: viewModel.isSaveable,
                                  isSaving: viewModel.isSaving,
                                  itemContentType: viewModel.itemContentType(),
                                  shouldUpgrade: viewModel.shouldUpgrade,
                                  onGoBack: {
                                      if viewModel.didEditSomething {
                                          isShowingDiscardAlert.toggle()
                                      } else {
                                          dismiss()
                                      }
                                  },
                                  onUpgrade: { viewModel.upgrade() },
                                  onScan: { viewModel.openScanner() },
                                  onSave: { viewModel.save() })
        }
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
                    Text(viewModel.aliasEmail)
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

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("You are about to create")
                    .sectionTitleText()

                if viewModel.prefixError != nil {
                    Text(viewModel.prefix + viewModel.suffix)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
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
                            .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                            Text(viewModel.suffix)
                            .foregroundColor(Color(uiColor: viewModel.itemContentType().normMajor2Color))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.default, value: viewModel.prefixError)
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}
