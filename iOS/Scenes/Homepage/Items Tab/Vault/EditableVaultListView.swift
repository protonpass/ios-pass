//
// EditableVaultListView.swift
// Proton Pass - Created on 08/03/2023.
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

import Client
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

enum ActionnableContainer {
    case vault(Share)
    case folder(FolderUiModel)

    var isVault: Bool {
        switch self {
        case .vault:
            true

        case .folder:
            false
        }
    }

    var name: String? {
        switch self {
        case let .vault(share):
            share.vaultName

        case let .folder(folder):
            folder.content.name
        }
    }
}

enum FolderAction: Equatable {
    case createNewFolder(Share, parentFolderId: String?)
    case edit(FolderUiModel)

    var isCreatingNew: Bool {
        switch self {
        case .createNewFolder:
            true

        default:
            false
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .createNewFolder:
            "Enter a folder title"

        case .edit:
            "Enter new folder title"
        }
    }
}

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EditableVaultListViewModel()
    @State private var containerNameConfirmation = ""
    @State private var folderName = ""
    private let onChangeMode: (EditableVaultListViewModel.Mode) -> Void

    init(onChangeMode: @escaping (EditableVaultListViewModel.Mode) -> Void) {
        self.onChangeMode = onChangeMode
    }

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(.spring, value: viewModel.mode)
            .onChange(of: viewModel.mode) {
                onChangeMode(viewModel.mode)
            }
            .alert(viewModel.containerToDelete?.isVault ?? true ? "Delete vault?" : "Delete folder?",
                   isPresented: $viewModel.containerToDelete.mappedToBool(),
                   presenting: viewModel.containerToDelete,
                   actions: { container in
                       TextField(container.isVault ? "Vault name" : "Folder name",
                                 text: $containerNameConfirmation)
                       Button("Delete",
                              role: .destructive,
                              action: {
                                  containerNameConfirmation = ""
                                  viewModel.delete(container: container)
                              })
                              .disabled(containerNameConfirmation != container.name)

                       Button("Cancel", role: .cancel, action: { containerNameConfirmation = "" })
                   },
                   message: { container in
                       Text(verbatim: deleteMessage(for: container))
                   })

            .alert(viewModel.folderAction?.title ?? "New folder",
                   isPresented: $viewModel.folderAction.mappedToBool(),
                   presenting: viewModel.folderAction,
                   actions: { _ in
                       TextField("Title",
                                 text: $folderName)
                       Button("Cancel", action: {
                           viewModel.cleanActions()
                       })

                       Button(viewModel.folderAction?.isCreatingNew ?? true ? "Create" : "Save",
                              action: {
                                  viewModel.folderCreateAndEdition(name: folderName)
                              })
                              .disabled(folderName.isEmpty)
                   },
                   message: { _ in
                       EmptyView()
                   })
            .onChange(of: viewModel.folderAction) { _, newValue in
                switch newValue {
                case let .edit(folder):
                    folderName = folder.content.name

                default:
                    folderName = ""
                }
            }
    }

    var mainContent: some View {
        ZStack {
            if viewModel.mode.isView {
                mainListView
            } else {
                OrganizeVaultListView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    var mainListView: some View {
        VStack(alignment: .leading) {
            if viewModel.shouldUpsell {
                UpsellRow(onUpgrade: viewModel.upgradeSubscription)
            }
            vaultsScrollView
            VaultListBottomBar(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(PassColor.backgroundWeak)
        .showSpinner(viewModel.loading)
    }

    private func selectAndDismiss(_ selection: ShareSelection) {
        dismiss()
        viewModel.select(selection)
    }

    // swiftlint:disable line_length
    func deleteMessage(for container: ActionnableContainer) -> String {
        if container.isVault {
            #localized("This will permanently delete the vault « %@ » and all its contents. Enter the vault name to confirm deletion.",
                       container.name ?? "")
        } else {
            #localized("This will permanently delete the folder « %@ » and all its contents. Enter the folder name to confirm deletion.",
                       container.name ?? "")
        }
    }
    // swiftlint:enable line_length
}

private extension EditableVaultListView {
    var vaultsScrollView: some View {
        LazyVStack(spacing: 0) {
            switch viewModel.state {
            case .error, .loading:
                // Should never happen because we don't allow showing list of vaults
                // when vaults are being loaded or error occurred
                ProgressView()

            case .loaded:
                VaultScopeRow(selection: .all, viewModel: viewModel, onSelect: selectAndDismiss)
                PassDivider()

                ForEach(viewModel.visibleVaults) { content in
                    HStack(spacing: 16) {
                        if viewModel.folderSupported, viewModel.shouldShowToggleArrow(for: content) {
                            Button {
                                withAnimation {
                                    viewModel.toggleDisplayContainerContent(containerId: content.id)
                                }
                            } label: {
                                ExpandRowButtonDisplay(expanded: viewModel.expandedContainerIds
                                    .contains(content.id))
                            }
                            .buttonStyle(.plain)
                        }
                        VaultScopeRow(selection: .precise(.init(share: content.share, folder: nil)),
                                      viewModel: viewModel,
                                      onSelect: selectAndDismiss)
                    }

                    if viewModel.folderSupported,
                       viewModel.expandedContainerIds.contains(content.id) {
                        if let folders = content.folders(in: content.id), !folders.isEmpty {
                            FolderTreeView(content: content,
                                           folders: folders,
                                           shouldDismissOnSelection: true,
                                           expandedContainerIds: $viewModel.expandedContainerIds,
                                           selectedContainer: $viewModel.shareSelection) { folder, content in
                                if !content.isReadOnly {
                                    FolderMenuView(folder: folder, content: content, viewModel: viewModel)
                                }
                            }
                            .equatable()
                            .padding(.leading, 30)
                        } else if content.canAddFolder(in: content.id, limits: viewModel.folderLimits) {
                            HStack {
                                if #available(iOS 26.0, *) {
                                    createFolderButton(content)
                                        .tint(PassColor.interactionNormMinor1)
                                        .buttonStyle(.glassProminent)
                                } else {
                                    createFolderButton(content)
                                        .background(PassColor.interactionNormMinor1)
                                        .clipShape(.capsule)
                                        .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            .padding(.leading, 36)
                            .padding(.bottom, 16)
                        }
                    }
                    PassDivider()
                }

                if viewModel.canSelectVault(selection: .sharedWithMe) {
                    VaultScopeRow(selection: .sharedWithMe, viewModel: viewModel, onSelect: selectAndDismiss)
                    PassDivider()
                }

                if viewModel.canSelectVault(selection: .sharedByMe) {
                    VaultScopeRow(selection: .sharedByMe, viewModel: viewModel, onSelect: selectAndDismiss)
                    PassDivider()
                }

                VaultScopeRow(selection: .trash, viewModel: viewModel, onSelect: selectAndDismiss)
            }
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
    }

    func createFolderButton(_ content: ShareContent) -> some View {
        Button(action: {
            if viewModel.shouldUpsell {
                viewModel.upgradeSubscription()
            } else {
                viewModel.folderAction = .createNewFolder(content.share, parentFolderId: nil)
            }
        }, label: {
            HStack(spacing: 8) {
                IconProvider.folderPlus
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNormMajor2)
                    .frame(height: 20)
                Text("Create folder")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(PassColor.interactionNormMajor2)
                    .padding(.vertical, 2)
                if viewModel.shouldUpsell {
                    PassIcon.passSubscriptionBadge
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
            }
        })
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}

private struct FolderMenuView: View {
    let folder: FolderUiModel
    let content: ShareContent
    let viewModel: EditableVaultListViewModel

    var body: some View {
        Menu {
            Button(action: {
                viewModel.selectedFolderToMove(folderToMove: FolderToMove(folder: folder, shareContent: content))
            }, label: {
                Label(title: {
                    Text("Move folder")
                }, icon: {
                    IconProvider.folderArrowIn
                        .renderingMode(.template)
                        .foregroundStyle(PassColor.textWeak)
                })
            })

            if viewModel.canAddSubFolder(in: folder, content: content) {
                Button(action: {
                    if viewModel.shouldUpsell {
                        viewModel.upgradeSubscription()
                    } else {
                        viewModel.folderAction = .createNewFolder(content.share, parentFolderId: folder.folderId)
                    }
                }, label: {
                    Label(title: {
                        Text("Create sub-folder")
                    }, icon: {
                        IconProvider.folderPlus
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak)
                    })
                })
            }

            Button(action: {
                viewModel.folderAction = .edit(folder)
            }, label: {
                Label(title: {
                    Text("Rename")
                }, icon: {
                    IconProvider.pencil
                        .renderingMode(.template)
                        .foregroundStyle(PassColor.textWeak)
                })
            })

            if viewModel.canMoveItems(folder: folder) {
                Button(action: {
                    viewModel.moveAllItemsInFolder(folder)
                }, label: {
                    Label(title: {
                        Text("Move all items")
                    }, icon: {
                        IconProvider.folderArrowIn
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak)
                    })
                })
            }

            Divider()

            Button(role: .destructive,
                   action: {
                       viewModel.containerToDelete = .folder(folder)
                   }, label: {
                       Label("Delete folder",
                             uiImage: IconProvider.trash)
                   })
        } label: {
            IconProvider.threeDotsVertical
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(PassColor.textWeak)
        }
    }
}
