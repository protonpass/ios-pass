//
// NavigationViewComponents.swift
// Proton Pass - Created on 27/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import SwiftUI

// MARK: - Selectable row

/// A single selectable vault/scope row built on the shared `VaultRow`.
/// Shared by `EditableVaultListView` and `OrganizeVaultListView`.
struct MenuVaultSelectionRow: View {
    let selection: ShareSelection
    let itemCount: Int
    let mode: VaultRowMode
    let onTap: () -> Void

    var body: some View {
        Button { onTap() } label: {
            VaultRow(thumbnail: {
                         CircleButton(icon: selection.icon,
                                      iconColor: selection.color,
                                      backgroundColor: selection.color.opacity(0.16))
                     },
                     title: selection.title,
                     itemCount: itemCount,
                     share: selection.share,
                     mode: mode,
                     height: 74)
        }
        .buttonStyle(.plain)
    }
}

struct VaultScopeRow: View {
    let selection: ShareSelection
    let viewModel: VaultsAndFoldersMenuViewModel
    let onSelect: (ShareSelection) -> Void

    var body: some View {
        let itemCount = viewModel.itemCount(for: selection)
        HStack {
            MenuVaultSelectionRow(selection: selection,
                                  itemCount: itemCount,
                                  mode: rowMode,
                                  onTap: { onSelect(selection) })

            Spacer()

            switch selection {
            case .all, .sharedByMe, .sharedWithMe:
                EmptyView()

            case let .precise(payload):
                VaultTrailingMenu(vault: payload.share, haveItems: itemCount > 0, viewModel: viewModel)

            case .trash:
                TrashTrailingMenu(viewModel: viewModel)
            }
        }
    }

    private var rowMode: VaultRowMode {
        .view(isSelected: viewModel.isSelected(selection),
              isHidden: false) { vault in
            if viewModel.canShare(vault: vault) {
                viewModel.share(vault: vault)
            } else {
                viewModel.router.present(for: .manageSharedShare(.vault(vault), .none))
            }
        }
    }
}

// MARK: - Trailing menus

private struct ThreeDotsMenuLabel: View {
    var body: some View {
        IconProvider.threeDotsVertical
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(PassColor.textWeak)
    }
}

private struct VaultTrailingMenu: View {
    let vault: Share
    let haveItems: Bool
    let viewModel: VaultsAndFoldersMenuViewModel

    var body: some View {
        Menu(content: {
            if viewModel.canEdit(vault: vault) {
                Button(action: {
                    viewModel.edit(vault: vault)
                }, label: {
                    Label(title: {
                        Text("Edit", bundle: .module)
                    }, icon: {
                        IconProvider.pencil
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak)
                    })
                })
            }

            if viewModel.canAddFolderAtVaultRoot(for: vault),
               vault.shareRole != .read {
                Button(action: {
                    if viewModel.folderSupportState.canCreateAndModifyFolders {
                        viewModel.folderAction = .createNewFolder(vault, parentFolderId: nil)
                    } else {
                        viewModel.upgradeSubscription()
                    }
                }, label: {
                    Label(title: {
                        Text("Create folder", bundle: .module)
                    }, icon: {
                        IconProvider.folderPlus
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
                        Text("Share", bundle: .module)
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
                        Text(vault.isManager ? "Manage access" : "View members", bundle: .module)
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
                        Text("Move all items", bundle: .module)
                    }, icon: {
                        IconProvider.folderArrowIn
                    })
                })
            }

            Divider()

            if vault.isOwner {
                Button(role: .destructive,
                       action: {
                           viewModel.containerToDelete = .vault(vault)
                       }, label: {
                           Label(title: {
                               Text("Delete vault", bundle: .module)
                           }, icon: {
                               IconProvider.trash
                           })
                       })
            } else if vault.groupID == nil {
                Button(role: .destructive,
                       action: {
                           viewModel.leaveVault(vault: vault)
                       }, label: {
                           Label(title: {
                               Text("Leave vault", bundle: .module)
                           }, icon: {
                               IconProvider.trash
                           })
                       })
            }
        }, label: { ThreeDotsMenuLabel() })
    }
}

private struct TrashTrailingMenu: View {
    let viewModel: VaultsAndFoldersMenuViewModel
    @State private var isShowingEmptyTrashAlert = false

    var body: some View {
        let trashedAliasesCount = viewModel.trashedAliasesCount
        let showAliasWarning = trashedAliasesCount > 0
        if viewModel.hasTrashItems {
            Menu(content: {
                Button { viewModel.restoreAllTrashedItems() } label: {
                    Label(title: {
                        Text("Restore all items", bundle: .module)
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
                               Text("Empty trash", bundle: .module)
                           }, icon: {
                               IconProvider.trashCross
                           })
                       })
            }, label: { ThreeDotsMenuLabel() })
                .alert(showAliasWarning ?
                    #localized("You are about to permanently delete %lld aliases", bundle: .module,
                               trashedAliasesCount) :
                    #localized("Empty trash", bundle: .module),
                    isPresented: $isShowingEmptyTrashAlert,
                    actions: {
                        Button(role: .destructive,
                               action: { viewModel.emptyTrash() },
                               label: {
                                   Text(showAliasWarning ? "Understood, I will never need them" : "Empty trash",
                                        bundle: .module)
                               })

                        Button(role: .cancel, label: { Text("Cancel", bundle: .module) })
                    },
                    message: {
                        Text(showAliasWarning ?
                            "Please note once deleted, the aliases can't be restored" :
                            "All items in trash will be permanently deleted",
                            bundle: .module)
                    })
        }
    }
}

// MARK: - Upsell & bottom bar

struct UpsellRow: View {
    let onUpgrade: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(action: onUpgrade) {
                    content
                }
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button(action: onUpgrade) {
                    content
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .inset(by: 0.5)
                            .stroke(PassColor.inputBorderNorm, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 25)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: 16) {
            PassIcon.diamond
                .resizable()
                .frame(width: 20, height: 20)
                .scaledToFit()
                .foregroundStyle(PassColor.interactionNormMajor2)
            Text("Upgrade to Pass Plus", bundle: .module)
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
        .contentShape(.rect)
    }
}

struct VaultListBottomBar: View {
    let viewModel: VaultsAndFoldersMenuViewModel

    var body: some View {
        ViewThatFits {
            HStack {
                createVaultButton(fixedSize: true)
                Spacer()
                organizeVaultsButton(fixedSize: true)
            }

            VStack {
                createVaultButton(fixedSize: false)
                organizeVaultsButton(fixedSize: false)
            }
        }
        .padding([.bottom, .horizontal])
    }

    private func createVaultButton(fixedSize: Bool) -> some View {
        CapsuleLabelButton(icon: IconProvider.plus,
                           title: #localized("Create vault", bundle: .module),
                           titleColor: PassColor.interactionNormMajor2,
                           backgroundColor: PassColor.interactionNormMinor1,
                           fontWeight: .semibold,
                           action: viewModel.createNewVault)
            .fixedSize(horizontal: fixedSize, vertical: fixedSize)
            .hidden(!viewModel.vaultCreationAllowed)
    }

    private func organizeVaultsButton(fixedSize: Bool) -> some View {
        CapsuleLabelButton(icon: IconProvider.listBullets,
                           title: #localized("Organize vaults", bundle: .module),
                           titleColor: PassColor.interactionNormMajor2,
                           backgroundColor: PassColor.interactionNormMinor1,
                           fontWeight: .semibold,
                           action: { viewModel.updateMode(.organise) })
            .fixedSize(horizontal: fixedSize, vertical: fixedSize)
    }
}
