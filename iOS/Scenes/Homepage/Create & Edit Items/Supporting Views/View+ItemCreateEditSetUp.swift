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
import Entities
import Macro
import Screens
import SwiftUI

private struct AddCustomFieldTypePayload {
    let type: CustomFieldType
    let payload: AddCustomFieldPayload
}

/// Set up common UI appearance for item create/edit pages
/// e.g. navigation bar, background color, toolbar, discard changes alert...
struct ItemCreateEditSetUpModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BaseCreateEditItemViewModel
    @State private var addCustomFieldTypePayload: AddCustomFieldTypePayload?
    @State private var customFieldTitle = ""
    @State private var customSectionTitle = ""

    func body(content: Content) -> some View {
        content
            .background(PassColor.backgroundNorm.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .tint(viewModel.itemContentType.normMajor1Color.toColor)
            .disabled(viewModel.isSaving)
            .animation(.default, value: viewModel.customFields)
            .animation(.default, value: viewModel.customSections)
            .animation(.default, value: viewModel.dismissedFileAttachmentsBanner)
            .obsoleteItemAlert(isPresented: $viewModel.isObsolete,
                               onAction: dismiss.callAsFunction)
            .discardChangesAlert(isPresented: $viewModel.isShowingDiscardAlert,
                                 onDiscard: dismiss.callAsFunction)
            .deleteFileAlert(fileToDelete: $viewModel.fileToDelete,
                             onDeleteFile: viewModel.delete(attachment:))
            .addCustomSectionAlert(isPresented: $viewModel.showAddCustomSectionAlert,
                                   title: $customSectionTitle,
                                   onAdd: viewModel.addCustomSection(_:))
            .editSectionTitleAlert(section: $viewModel.customSectionToRename,
                                   title: $customSectionTitle,
                                   onRename: viewModel.renameCustomSection(_:newName:))
            .deleteSectionAlert(section: $viewModel.customSectionToRemove,
                                onRemove: viewModel.removeCustomSection(_:))
            .pickCustomFieldTypeSheet(payload: $viewModel.addCustomFieldPayload,
                                      suppportedTypes: viewModel.supportedCustomFieldTypes,
                                      onAdd: { handleAddCustomField(type: $0) })
            .addCustomFieldAlert(payload: $addCustomFieldTypePayload,
                                 title: $customFieldTitle,
                                 onAdd: { payload in
                                     viewModel.addCustomField(.init(title: customFieldTitle,
                                                                    type: payload.type,
                                                                    content: payload.type.defaultContent),
                                                              to: payload.payload.sectionId)
                                     customFieldTitle = ""
                                 })
            .editCustomFieldTitleAlert(field: $viewModel.customFieldToEditTitle,
                                       title: $customFieldTitle,
                                       onEdit: { field in
                                           viewModel.editCustomField(field,
                                                                     update: .title(customFieldTitle))
                                           customFieldTitle = ""
                                       })
            .sharedCreationAlert(showItemShareAlert: $viewModel.showItemShareAlert,
                                 members: viewModel.selectedVault.members) { action in
                viewModel.alertAction(action: action)
            }
            .sheet(isPresented: $viewModel.isShowingNoCameraPermissionView) {
                NoCameraPermissionView { viewModel.openSettings() }
            }
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
                                      canScanDocuments: viewModel.canScanDocuments,
                                      vault: viewModel.selectedVault,
                                      canChangeVault: viewModel.mode.canChangeVault,
                                      itemContentType: viewModel.itemContentType,
                                      shouldUpgrade: viewModel.shouldUpgrade,
                                      isPhone: viewModel.isPhone,
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
            .task {
                await viewModel.fetchAttachedFiles()
            }
    }
}

private extension ItemCreateEditSetUpModifier {
    func handleAddCustomField(type: CustomFieldType) {
        guard let payload = viewModel.addCustomFieldPayload else { return }
        let showAddCustomFieldAlert: () -> Void = {
            addCustomFieldTypePayload = .init(type: type, payload: payload)
        }
        if #available(iOS 17, *) {
            showAddCustomFieldAlert()
        } else {
            // Manually dismiss custom field type picker
            // Wait for 0.5 sec to make sure it's fully dismissed before showing add custom field alert
            viewModel.addCustomFieldPayload = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAddCustomFieldAlert()
            }
        }
    }
}

// MARK: - Alerts

private extension View {
    func deleteFileAlert(fileToDelete: Binding<FileAttachmentUiModel?>,
                         onDeleteFile: @escaping (FileAttachmentUiModel) -> Void) -> some View {
        alert("Delete file?",
              isPresented: fileToDelete.mappedToBool(),
              actions: {
                  if let file = fileToDelete.wrappedValue {
                      Button("Delete",
                             role: .destructive,
                             action: { onDeleteFile(file) })
                      Button("Cancel", role: .cancel, action: {})
                  }
              },
              message: { Text(verbatim: fileToDelete.wrappedValue?.name ?? "") })
    }

    func addCustomSectionAlert(isPresented: Binding<Bool>,
                               title: Binding<String>,
                               onAdd: @escaping (String) -> Void) -> some View {
        alert("Custom section",
              isPresented: isPresented,
              actions: {
                  TextField("Title", text: title)
                      .autocorrectionDisabled()

                  Button(role: .cancel,
                         action: {
                             title.wrappedValue = ""
                             isPresented.wrappedValue.toggle()
                         },
                         label: { Text("Cancel") })

                  adaptiveDisabledButton(title: "Add",
                                         disabled: title.wrappedValue.isEmpty,
                                         action: {
                                             onAdd(title.wrappedValue)
                                             title.wrappedValue = ""
                                         })
              },
              message: { Text("Enter a section title") })
    }

    func editSectionTitleAlert(section: Binding<CustomSection?>,
                               title: Binding<String>,
                               onRename: @escaping (CustomSection, String) -> Void) -> some View {
        alert("Modify the section name",
              isPresented: section.mappedToBool(),
              actions: {
                  TextField("New title", text: title)
                      .autocorrectionDisabled()
                  Button("Modify") {
                      if let section = section.wrappedValue {
                          onRename(section, title.wrappedValue)
                      }
                      title.wrappedValue = ""
                  }
                  .disabled(title.wrappedValue.isEmpty)
                  Button("Cancel", role: .cancel) { title.wrappedValue = "" }
              },
              message: { Text("Enter a new section title") })
    }

    func deleteSectionAlert(section: Binding<CustomSection?>,
                            onRemove: @escaping (CustomSection) -> Void) -> some View {
        alert("Remove custom section",
              isPresented: section.mappedToBool(),
              actions: {
                  Button(role: .destructive,
                         action: {
                             if let section = section.wrappedValue {
                                 onRemove(section)
                             }
                         },
                         label: { Text("Delete") })

                  Button(role: .cancel, action: {}, label: { Text("Cancel") })
              },
              message: {
                  if let section = section.wrappedValue {
                      Text("Are you sure you want to delete the following section \"\(section.title)\"?")
                  }
              })
    }
}

// MARK: - Custom fields

private extension View {
    func pickCustomFieldTypeSheet(payload: Binding<AddCustomFieldPayload?>,
                                  suppportedTypes: [CustomFieldType],
                                  onAdd: @escaping (CustomFieldType) -> Void) -> some View {
        sheet(isPresented: payload.mappedToBool()) {
            CustomFieldTypesView(supportedTypes: suppportedTypes,
                                 onSelect: onAdd)
                .presentationDetents([.height(OptionRowHeight.short.value * CGFloat(suppportedTypes.count))])
        }
    }

    // Only iOS 17+ support disabling alert's buttons
    @ViewBuilder
    func adaptiveDisabledButton(title: LocalizedStringKey,
                                disabled: Bool,
                                action: @escaping () -> Void) -> some View {
        let button = Button(title, role: nil, action: action)
        if #available(iOS 17, *) {
            button
                .disabled(disabled)
        } else {
            button
        }
    }

    func addCustomFieldAlert(payload: Binding<AddCustomFieldTypePayload?>,
                             title: Binding<String>,
                             onAdd: @escaping (AddCustomFieldTypePayload) -> Void) -> some View {
        alert("Enter a field name",
              isPresented: payload.mappedToBool(),
              actions: {
                  if let payload = payload.wrappedValue {
                      TextField(payload.type.placeholder, text: title)
                      adaptiveDisabledButton(title: "Add",
                                             disabled: title.wrappedValue.isEmpty,
                                             action: { onAdd(payload) })
                  }

                  Button("Cancel", role: .cancel, action: { title.wrappedValue = "" })
              },
              message: {
                  if let type = payload.wrappedValue?.type {
                      Text(type.alertMessage)
                  }
              })
    }

    func editCustomFieldTitleAlert(field: Binding<CustomField?>,
                                   title: Binding<String>,
                                   onEdit: @escaping (CustomField) -> Void) -> some View {
        alert("Edit field name",
              isPresented: field.mappedToBool(),
              actions: {
                  if let field = field.wrappedValue {
                      TextField(field.type.placeholder, text: title)
                      adaptiveDisabledButton(title: "Save",
                                             disabled: title.wrappedValue.isEmpty,
                                             action: { onEdit(field) })
                  }

                  Button("Cancel", role: .cancel, action: { title.wrappedValue = "" })
              },
              message: {
                  if let field = field.wrappedValue {
                      Text(#localized("Enter new name for « %@ »", field.title))
                  }
              })
    }

    func sharedCreationAlert(showItemShareAlert: Binding<Bool>,
                             members: Int,
                             action: @escaping (AlertActions) -> Void) -> some View {
        alert("Item in a shared vault",
              isPresented: showItemShareAlert) {
            Button { action(.dismissAndSave) } label: {
                Text("Ok")
            }
            Button { action(.dismissSaveAndUpdateSettings) } label: {
                Text("Don't remind me again")
            }
            Button(role: .cancel) {
                Text("Cancel")
            }
        } message: {
            Text("You are creating an item in a shared vault and \(members) users will immediately gain access to it.")
        }
    }
}

@MainActor
extension View {
    func itemCreateEditSetUp(_ viewModel: BaseCreateEditItemViewModel) -> some View {
        modifier(ItemCreateEditSetUpModifier(viewModel: viewModel))
    }
}

private extension CustomFieldType {
    var alertMessage: LocalizedStringKey {
        switch self {
        case .text:
            "Text custom field"
        case .totp:
            "2FA secret key (TOTP) custom field"
        case .hidden:
            "Hidden custom field"
        case .timestamp:
            "Date custom field"
        }
    }

    var placeholder: LocalizedStringKey {
        switch self {
        case .text:
            "E.g., User ID, Acct number"
        case .totp:
            "2FA secret key (TOTP)"
        case .hidden:
            "E.g., Recovery key, PIN"
        case .timestamp:
            "Date"
        }
    }
}
