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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditableVaultListViewModel()
    @State private var vaultNameConfirmation = ""
    @State private var vaultToDelete: Vault?
    @State private var isShowingEmptyTrashAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch viewModel.state {
                    case .error, .loading:
                        // Should never happen
                        ProgressView()
                    case let .loaded(uiModel):
                        vaultRow(for: .all)

                        PassDivider()

                        ForEach(uiModel.vaults, id: \.hashValue) { vault in
                            vaultRow(for: .precise(vault.vault))
                            PassDivider()
                        }

                        vaultRow(for: .trash)

                        PassDivider()
                    }
                }
                .padding(.horizontal)
            }
            HStack {
                CapsuleTextButton(title: #localized("Create vault"),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  action: { viewModel.createNewVault() })
                    .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }
            .padding([.bottom, .horizontal])
        }
        .background(PassColor.backgroundWeak.toColor)
        .showSpinner(viewModel.loading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("Delete vault?",
               isPresented: $vaultToDelete.mappedToBool(),
               presenting: vaultToDelete,
               actions: { vault in
                   TextField("Vault name", text: $vaultNameConfirmation)
                   Button("Delete", action: { viewModel.delete(vault: vault) })
                       .disabled(vaultNameConfirmation != vault.name)
                   Button("Cancel", action: { vaultNameConfirmation = "" })
               },
               message: { vault in
                   // swiftlint:disable:next line_length
                   Text("This will permanently delete the vault « \(vault.name) » and all its contents. Enter the vault name to confirm deletion.")
               })
    }

    @ViewBuilder
    private func vaultRow(for selection: VaultSelection) -> some View {
        let itemCount = viewModel.itemCount(for: selection)
        HStack {
            Button(action: {
                dismiss()
                viewModel.select(selection)
            }, label: {
                VaultRow(thumbnail: {
                             CircleButton(icon: selection.icon,
                                          iconColor: selection.color,
                                          backgroundColor: selection.color.withAlphaComponent(0.16))
                         },
                         title: selection.title,
                         itemCount: itemCount,
                         isShared: selection.shared,
                         isSelected: viewModel.isSelected(selection),
                         showBadge: selection.showBadge,
                         height: 74)
            })
            .buttonStyle(.plain)

            Spacer()

            switch selection {
            case .all:
                EmptyView()
            case let .precise(vault):
                vaultTrailingView(vault, haveItems: itemCount > 0)
            case .trash:
                trashTrailingView
            }
        }
    }

    private func threeDotsIcon() -> some View {
        Image(uiImage: IconProvider.threeDotsVertical)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(PassColor.textWeak.toColor)
    }

    @ViewBuilder
    private func vaultTrailingView(_ vault: Vault, haveItems: Bool) -> some View {
        Menu(content: {
            if viewModel.canEdit(vault: vault) {
                Button(action: {
                    viewModel.edit(vault: vault)
                }, label: {
                    Label(title: {
                        Text("Edit")
                    }, icon: {
                        Image(uiImage: IconProvider.pencil)
                            .renderingMode(.template)
                            .foregroundStyle(PassColor.textWeak.toColor)
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
                    viewModel.router.present(for: .manageShareVault(vault, .none))
                }, label: {
                    Label(title: {
                        Text(vault.isAdmin ? "Manage access" : "View members")
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

            Button(role: .destructive,
                   action: {
                       if vault.isOwner {
                           vaultToDelete = vault
                       } else {
                           viewModel.leaveVault(vault: vault)
                       }
                   },
                   label: {
                       Label(vault.isOwner ? "Delete vault" : "Leave vault",
                             uiImage: IconProvider.trash)
                   })
        }, label: threeDotsIcon)
    }

    @ViewBuilder
    private var trashTrailingView: some View {
        if viewModel.hasTrashItems {
            Menu(content: {
                Button { viewModel.restoreAllTrashedItems() } label: {
                    Label(title: {
                        Text("Restore all items")
                    }, icon: {
                        Image(uiImage: IconProvider.clockRotateLeft)
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
                               Image(uiImage: IconProvider.trashCross)
                           })
                       })
            }, label: threeDotsIcon)
                .alert("Empty trash",
                       isPresented: $isShowingEmptyTrashAlert,
                       actions: {
                           Button(role: .destructive,
                                  action: { viewModel.emptyTrash() },
                                  label: { Text("Empty trash") })

                           Button(role: .cancel, label: { Text("Cancel") })
                       },
                       message: { Text("All items in trash will be permanently deleted") })
        }
    }
}

extension VaultSelection {
    var title: String {
        switch self {
        case .all:
            #localized("All vaults")
        case let .precise(vault):
            vault.name
        case .trash:
            #localized("Trash")
        }
    }

    var icon: UIImage {
        switch self {
        case .all:
            PassIcon.brandPass
        case let .precise(vault):
            vault.displayPreferences.icon.icon.bigImage
        case .trash:
            IconProvider.trash
        }
    }

    var color: UIColor {
        switch self {
        case .all:
            PassColor.interactionNormMajor2
        case let .precise(vault):
            vault.displayPreferences.color.color.color
        case .trash:
            PassColor.textWeak
        }
    }
}
