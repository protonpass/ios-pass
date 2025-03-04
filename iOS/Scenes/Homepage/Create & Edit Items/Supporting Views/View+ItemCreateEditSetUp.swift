//
// View+ItemCreateEditSetUp.swift
// Proton Pass - Created on 19/06/2024.
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
import Screens
import SwiftUI

/// Set up common UI appearance for item create/edit pages
/// e.g. navigation bar, background color, toolbar, discard changes alert...
struct ItemCreateEditSetUpModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BaseCreateEditItemViewModel
    @State private var customSectionTitle = ""

    func body(content: Content) -> some View {
        content
            .background(PassColor.backgroundNorm.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .tint(viewModel.itemContentType.normMajor1Color.toColor)
            .disabled(viewModel.isSaving)
            .animation(.default, value: viewModel.customFieldUiModels)
            .animation(.default, value: viewModel.customSectionUiModels)
            .obsoleteItemAlert(isPresented: $viewModel.isObsolete,
                               onAction: dismiss.callAsFunction)
            .discardChangesAlert(isPresented: $viewModel.isShowingDiscardAlert,
                                 onDiscard: dismiss.callAsFunction)
            .sheet(isPresented: $viewModel.isShowingVaultSelector) {
                // Add more height when free users to make room for upsell banner
                let height = viewModel.vaults.filter(\.canEdit).count * 74 + (viewModel.isFreeUser ? 180 : 50)
                VaultSelectorView(selectedVault: $viewModel.selectedVault,
                                  isFreeUser: viewModel.isFreeUser,
                                  onUpgrade: { viewModel.upgrade() })
                    .presentationDetents([.height(CGFloat(height)), .large])
                    .environment(\.colorScheme, colorScheme)
            }
            .fullScreenCover(item: $viewModel.filePreviewMode) { mode in
                FileAttachmentPreview(mode: mode,
                                      primaryTintColor: viewModel.itemContentType.normMajor2Color,
                                      secondaryTintColor: viewModel.itemContentType.normMinor1Color)
            }
            .toolbar {
                CreateEditItemToolbar(saveButtonTitle: viewModel.saveButtonTitle(),
                                      isSaveable: viewModel.isSaveable,
                                      isSaving: viewModel.isSaving,
                                      fileAttachmentsEnabled: viewModel.fileAttachmentsEnabled,
                                      canScanDocuments: viewModel.canScanDocuments,
                                      vault: viewModel.selectedVault,
                                      canChangeVault: viewModel.mode.canChangeVault,
                                      itemContentType: viewModel.itemContentType,
                                      shouldUpgrade: viewModel.shouldUpgrade,
                                      isPhone: viewModel.isPhone,
                                      fileAttachmentsEditHandler: viewModel,
                                      onSelectVault: { viewModel.isShowingVaultSelector.toggle() },
                                      onGoBack: { viewModel.isShowingDiscardAlert.toggle() },
                                      onUpgrade: {
                                          if viewModel.shouldUpgrade {
                                              viewModel.upgrade()
                                          }
                                      },
                                      onScan: { viewModel.openScanner() },
                                      onSave: { viewModel.save() })
            }
            .alert("Delete file?",
                   isPresented: $viewModel.fileToDelete.mappedToBool(),
                   actions: {
                       if let file = viewModel.fileToDelete {
                           Button("Delete",
                                  role: .destructive,
                                  action: { viewModel.delete(attachment: file) })
                           Button("Cancel", role: .cancel, action: {})
                       }
                   },
                   message: { Text(verbatim: viewModel.fileToDelete?.name ?? "") })
            .alert("Custom section",
                   isPresented: $viewModel.showAddCustomSectionAlert,
                   actions: {
                       TextField("Title", text: $customSectionTitle)
                           .autocorrectionDisabled()

                       Button(role: .cancel,
                              action: {
                                  customSectionTitle = ""
                                  viewModel.showAddCustomSectionAlert.toggle()
                              },
                              label: { Text("Cancel") })

                       Button("Add") {
                           viewModel.addCustomSection(customSectionTitle)
                           customSectionTitle = ""
                       }
                   },
                   message: { Text("Enter a section title") })
            .alert("Modify the section name",
                   isPresented: $viewModel.customSectionToRename.mappedToBool(),
                   actions: {
                       TextField("New title", text: $customSectionTitle)
                           .autocorrectionDisabled()
                       Button("Modify") {
                           if let section = viewModel.customSectionToRename {
                               viewModel.renameCustomSection(section, newName: customSectionTitle)
                           }
                           customSectionTitle = ""
                       }
                       Button("Cancel", role: .cancel) { customSectionTitle = "" }
                   },
                   message: { Text("Enter a new section title") })
            .alert("Remove custom section",
                   isPresented: $viewModel.customSectionToRemove.mappedToBool(),
                   actions: {
                       Button(role: .destructive,
                              action: {
                                  if let section = viewModel.customSectionToRemove {
                                      viewModel.removeCustomSection(section)
                                  }
                              },
                              label: { Text("Delete") })

                       Button(role: .cancel, action: {}, label: { Text("Cancel") })
                   },
                   message: {
                       if let section = viewModel.customSectionToRemove {
                           Text("Are you sure you want to delete the following section \"\(section.title)\"?")
                       }
                   })
            .task {
                await viewModel.fetchAttachedFiles()
            }
    }
}

@MainActor
extension View {
    func itemCreateEditSetUp(_ viewModel: BaseCreateEditItemViewModel) -> some View {
        modifier(ItemCreateEditSetUpModifier(viewModel: viewModel))
    }
}
