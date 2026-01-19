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
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditableVaultListViewModel()
    @State private var vaultNameConfirmation = ""
    @State private var vaultToDelete: Share?
    @State private var isShowingEmptyTrashAlert = false
    private let onChangeMode: (EditableVaultListViewModel.Mode) -> Void
    @Namespace private var contentNamespace

    init(onChangeMode: @escaping (EditableVaultListViewModel.Mode) -> Void) {
        self.onChangeMode = onChangeMode
    }

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .onChange(of: viewModel.mode) { newMode in
                onChangeMode(newMode)
            }
            .alert("Delete vault?",
                   isPresented: $vaultToDelete.mappedToBool(),
                   presenting: vaultToDelete,
                   actions: { vault in
                       TextField("Vault name", text: $vaultNameConfirmation)
                       Button("Delete",
                              action: {
                                  vaultNameConfirmation = ""
                                  viewModel.delete(vault: vault)
                              })
                              .disabled(vaultNameConfirmation != vault.vaultName)
                       Button("Cancel", action: { vaultNameConfirmation = "" })
                   },
                   message: { vault in
                       // swiftlint:disable:next line_length
                       Text("This will permanently delete the vault « \(vault.vaultName ?? "") » and all its contents. Enter the vault name to confirm deletion.")
                   })
    }

    @ViewBuilder
    var mainContent: some View {
        if viewModel.mode.isView {
            mainListView
                .matchedGeometryEffect(id: "content", in: contentNamespace)
        } else {
            OrganizeVaultListView(viewModel: viewModel)
                .matchedGeometryEffect(id: "content", in: contentNamespace)
        }
    }

    var mainListView: some View {
        VStack(alignment: .leading) {
            upsellRow
            vaultsScrollView
            bottomView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(PassColor.backgroundWeak)
        .showSpinner(viewModel.loading)
        .animation(.default, value: viewModel.containersExtended)
    }
}

private extension EditableVaultListView {
    @ViewBuilder
    var upsellRow: some View {
        if viewModel.shouldUpsell {
            HStack(alignment: .center, spacing: 16) {
                PassIcon.diamond
                    .resizable()
                    .frame(width: 20, height: 20)
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNormMajor2)
                Text("Upgrade to Pass Plus")
                    .foregroundStyle(PassColor.textNorm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                IconProvider.chevronRight
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(PassColor.interactionNormMajor2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(PassColor.inputBorderNorm, lineWidth: 1))
            .padding(.horizontal)
            .padding(.top, 25)
            .buttonEmbeded(action: viewModel.upgradeSubscription)
        }
    }

    var bottomView: some View {
        HStack {
            CapsuleLabelButton(icon: IconProvider.plus,
                               title: #localized("Create vault"),
                               titleColor: PassColor.interactionNormMajor2,
                               backgroundColor: PassColor.interactionNormMinor1,
                               fontWeight: .semibold,
                               action: viewModel.createNewVault)
                .fixedSize(horizontal: true, vertical: true)
                .hidden(viewModel.organization?.settings?.vaultCreateMode == .adminsOnly)

            Spacer()

            if viewModel.hideShowVaultSupported {
                CapsuleLabelButton(icon: IconProvider.listBullets,
                                   title: #localized("Organize vaults"),
                                   titleColor: PassColor.interactionNormMajor2,
                                   backgroundColor: PassColor.interactionNormMinor1,
                                   fontWeight: .semibold,
                                   action: {
                                       withAnimation(.spring()) {
                                           viewModel.updateMode(.organise)
                                       }
                                   })
                                   .fixedSize(horizontal: true, vertical: true)
            }
        }
        .padding([.bottom, .horizontal])
    }

    var vaultsScrollView: some View {
        LazyVStack(spacing: 0) {
            switch viewModel.state {
            case .error, .loading:
                // Should never happen because we don't allow showing list of vaults
                // when vaults are being loaded or error occured
                ProgressView()

            case .loaded:
                vaultRow(for: .all)
                PassDivider()

                ForEach(viewModel.filteredOrderedVaults) { content in
                    HStack {
                        if let folders = content.folders(in: content.id), !folders.isEmpty {
                            Button { viewModel.toggleDisplayContainerContent(containerId: content.id) } label: {
                                (viewModel.containersExtended.contains(content.id) ?
                                    IconProvider.chevronDownFilled : IconProvider.chevronRightFilled)
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(PassColor.textWeak)
                            }
                            .buttonStyle(.plain)
                        }
                        vaultRow(for: .precise(content.share, folderId: nil))
                    }

                    if let folders = content.folders(in: content.id),
                       !folders.isEmpty,
                       viewModel.containersExtended.contains(content.id) {
                        FolderTreeRow(content: content, folders: folders, viewModel: viewModel)
                    }
                    PassDivider()
                }

                if viewModel.canSelectVault(selection: .sharedWithMe) {
                    vaultRow(for: .sharedWithMe)
                    PassDivider()
                }

                if viewModel.canSelectVault(selection: .sharedByMe) {
                    vaultRow(for: .sharedByMe)
                    PassDivider()
                }

                vaultRow(for: .trash)
            }
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
    }

    @ViewBuilder
    func vaultRow(for selection: ShareSelection) -> some View {
        let itemCount = viewModel.itemCount(for: selection)

        let vaultRowMode: VaultRowMode = .view(isSelected: viewModel.isSelected(selection),
                                               isHidden: false) { vault in
            if viewModel.canShare(vault: vault) {
                viewModel.share(vault: vault)
            } else {
                viewModel.router.present(for: .manageSharedShare(.vault(vault), .none))
            }
        }

        HStack {
            Button(action: {
                dismiss()
                viewModel.select(selection)
            }, label: {
                VaultRow(thumbnail: {
                             CircleButton(icon: selection.icon,
                                          iconColor: selection.color,
                                          backgroundColor: selection.color.opacity(0.16))
                         },
                         title: selection.title,
                         itemCount: itemCount,
                         share: selection.share,
                         mode: vaultRowMode,
                         height: 74)
            })
            .buttonStyle(.plain)

            Spacer()

            switch selection {
            case .all, .sharedByMe, .sharedWithMe:
                EmptyView()
            case let .precise(vault, _):
                vaultTrailingView(vault, haveItems: itemCount > 0)
            case .trash:
                trashTrailingView
            }
        }
    }

    func threeDotsIcon() -> some View {
        IconProvider.threeDotsVertical
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(PassColor.textWeak)
    }

    @ViewBuilder
    func vaultTrailingView(_ vault: Share, haveItems: Bool) -> some View {
        Menu(content: {
            if viewModel.canEdit(vault: vault) {
                Button(action: {
                    viewModel.edit(vault: vault)
                }, label: {
                    Label(title: {
                        Text("Edit")
                    }, icon: {
                        IconProvider.pencil
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak)
                    })
                })
            }

            if viewModel.canShare(vault: vault) {
                Button(action: {
                    viewModel.share(vault: vault)
                }, label: {
                    Label(title: {
                        Text("Share")
                    }, icon: {
                        IconProvider.userPlus
                    })
                })
            }

            if vault.shared {
                Button(action: {
                    viewModel.router.present(for: .manageSharedShare(.vault(vault), .none))
                }, label: {
                    Label(title: {
                        Text(vault.isManager ? "Manage access" : "View members")
                    }, icon: {
                        IconProvider.users
                    })
                })
            }

            if viewModel.canMoveItems(vault: vault), haveItems {
                Button(action: {
                    viewModel.router.present(for: .moveItemsBetweenVaults(.allItems(vault)))
                }, label: {
                    Label(title: {
                        Text("Move all items to another vault")
                    }, icon: {
                        IconProvider.folderArrowIn
                    })
                })
            }

            Divider()

            if vault.isOwner {
                Button(role: .destructive,
                       action: {
                           vaultToDelete = vault
                       }, label: {
                           Label("Delete vault",
                                 uiImage: IconProvider.trash)
                       })
            } else if vault.groupID == nil {
                Button(role: .destructive,
                       action: {
                           viewModel.leaveVault(vault: vault)
                       }, label: {
                           Label("Leave vault",
                                 uiImage: IconProvider.trash)
                       })
            }
        }, label: threeDotsIcon)
    }

    @ViewBuilder
    var trashTrailingView: some View {
        let trashedAliasesCount = viewModel.trashedAliasesCount
        let showAliasWarning = trashedAliasesCount > 0
        if viewModel.hasTrashItems {
            Menu(content: {
                Button { viewModel.restoreAllTrashedItems() } label: {
                    Label(title: {
                        Text("Restore all items")
                    }, icon: {
                        IconProvider.clockRotateLeft
                    })
                }

                Divider()

                Button(role: .destructive,
                       action: {
                           isShowingEmptyTrashAlert.toggle()
                       },
                       label: {
                           Label(title: {
                               Text("Empty trash")
                           }, icon: {
                               IconProvider.trashCross
                           })
                       })
            }, label: threeDotsIcon)
                .alert(showAliasWarning ?
                    "You are about to permanently delete \(trashedAliasesCount) aliases" :
                    "Empty trash",
                    isPresented: $isShowingEmptyTrashAlert,
                    actions: {
                        Button(role: .destructive,
                               action: { viewModel.emptyTrash() },
                               label: {
                                   Text(showAliasWarning ? "Understood, I will never need them" : "Empty trash")
                               })

                        Button(role: .cancel, label: { Text("Cancel") })
                    },
                    message: {
                        Text(showAliasWarning ?
                            "Please note once deleted, the aliases can't be restored" :
                            "All items in trash will be permanently deleted")
                    })
        }
    }
}

struct FolderTreeRow: View {
    let content: ShareContent
    let folders: [FolderUiModel]
    @ObservedObject var viewModel: EditableVaultListViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(folders) { folder in
                row(for: folder)
                    .padding(.vertical, 12)

                if shouldShowSubfolders(of: folder),
                   let subFolders = content.folders(in: folder.id) {
                    FolderTreeRow(content: content,
                                  folders: subFolders,
                                  viewModel: viewModel)
                }
            }
        }
        .padding(.leading, 8)
    }
}

private extension FolderTreeRow {
    func row(for folder: FolderUiModel) -> some View {
        HStack {
            disclosureButton(for: folder)
            folderButton(for: folder)
        }
    }

    @ViewBuilder
    func disclosureButton(for folder: FolderUiModel) -> some View {
        if let subfolders = content.folders(in: folder.id), !subfolders.isEmpty {
            Button {
                viewModel.toggleDisplayContainerContent(containerId: folder.id)
            } label: {
                (viewModel.containersExtended.contains(folder.id)
                    ? IconProvider.chevronDownFilled
                    : IconProvider.chevronRightFilled)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textWeak)
            }
            .buttonStyle(.plain)
        } else {
            Text("")
                .frame(width: 30, height: 30)
        }
    }

    func folderButton(for folder: FolderUiModel) -> some View {
        HStack {
            Button {} label: {
                HStack {
                    IconProvider.foldersFilled
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color(hex: "#E9A944"))

                    Text(folder.content.name)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Menu {
                Button {} label: {
                    Text("Test")
                }
//                if viewModel.canEdit(vault: vault) {
//                    Button(action: {
//                        viewModel.edit(vault: vault)
//                    }, label: {
//                        Label(title: {
//                            Text("Edit")
//                        }, icon: {
//                            IconProvider.pencil
//                                .renderingMode(.template)
//                                .foregroundStyle(PassColor.textWeak)
//                        })
//                    })
//                }
//
//                if viewModel.canShare(vault: vault) {
//                    Button(action: {
//                        viewModel.share(vault: vault)
//                    }, label: {
//                        Label(title: {
//                            Text("Share")
//                        }, icon: {
//                            IconProvider.userPlus
//                        })
//                    })
//                }
//
//                if vault.shared {
//                    Button(action: {
//                        viewModel.router.present(for: .manageSharedShare(.vault(vault), .none))
//                    }, label: {
//                        Label(title: {
//                            Text(vault.isManager ? "Manage access" : "View members")
//                        }, icon: {
//                            IconProvider.users
//                        })
//                    })
//                }
//
//                if viewModel.canMoveItems(vault: vault), haveItems {
//                    Button(action: {
//                        viewModel.router.present(for: .moveItemsBetweenVaults(.allItems(vault)))
//                    }, label: {
//                        Label(title: {
//                            Text("Move all items to another vault")
//                        }, icon: {
//                            IconProvider.folderArrowIn
//                        })
//                    })
//                }
//
//                Divider()
//
//                if vault.isOwner {
//                    Button(role: .destructive,
//                           action: {
//                               vaultToDelete = vault
//                           }, label: {
//                               Label("Delete vault",
//                                     uiImage: IconProvider.trash)
//                           })
//                } else if vault.groupID == nil {
//                    Button(role: .destructive,
//                           action: {
//                               viewModel.leaveVault(vault: vault)
//                           }, label: {
//                               Label("Leave vault",
//                                     uiImage: IconProvider.trash)
//                           })
//                }
            } label: {
                IconProvider.threeDotsVertical
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(PassColor.textWeak)
            }
        }
    }

    func shouldShowSubfolders(of folder: FolderUiModel) -> Bool {
        viewModel.containersExtended.contains(folder.id)
    }
}
