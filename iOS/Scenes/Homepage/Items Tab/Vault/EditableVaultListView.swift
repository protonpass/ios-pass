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

    init(onChangeMode: @escaping (EditableVaultListViewModel.Mode) -> Void) {
        self.onChangeMode = onChangeMode
    }

    var body: some View {
        VStack(alignment: .leading) {
            topView
            upsellRow
            vaultsScrollView
            bottomView
        }
        .animation(.default, value: viewModel.mode)
        .animation(.default, value: viewModel.hiddenShareIds)
        .background(PassColor.backgroundWeak)
        .showSpinner(viewModel.loading)
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

private extension EditableVaultListView {
    @ViewBuilder
    var topView: some View {
        if viewModel.mode.isOrganise {
            HStack {
                Button(action: {
                    viewModel.updateMode(.view)
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(PassColor.interactionNormMajor2)
                })

                Spacer()

                Text("Organize vaults")
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)

                Spacer()

                Button(action: {
                    viewModel.applyVaultsOrganizations()
                }, label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.interactionNormMajor2)
                })
            }
            .padding()
        }
    }

    @ViewBuilder
    var upsellRow: some View {
        if !viewModel.mode.isOrganise, viewModel.shouldUpsell {
            HStack(alignment: .center, spacing: 16) {
                Image(uiImage: PassIcon.diamond)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .scaledToFit()
                    .foregroundStyle(PassColor.interactionNormMajor2)
                Text("Upgrade to Pass Plus")
                    .foregroundStyle(PassColor.textNorm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(uiImage: IconProvider.chevronRight)
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

    @ViewBuilder
    var bottomView: some View {
        if viewModel.mode.isView {
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
                                       action: { viewModel.updateMode(.organise) })
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            .padding([.bottom, .horizontal])
        }
    }

    var vaultsScrollView: some View {
        LazyVStack(spacing: 0) {
            switch viewModel.state {
            case .error, .loading:
                // Should never happen because we don't allow showing list of vaults
                // when vaults are being loaded or error occured
                ProgressView()

            case .loaded:
                if viewModel.mode.isView {
                    vaultRow(for: .all)
                    PassDivider()
                } else {
                    if viewModel.filteredOrderedVaults.count != viewModel.hiddenShareIds.count {
                        Text("Visible vaults")
                            .fontWeight(.semibold)
                            .foregroundStyle(PassColor.textNorm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom)
                    }
                }

                ForEach(viewModel.filteredOrderedVaults) { vault in
                    let shouldShow = if viewModel.mode.isView {
                        !vault.hidden
                    } else {
                        !viewModel.hiddenShareIds.contains(vault.shareId)
                    }

                    if shouldShow {
                        vaultRow(for: .precise(vault))
                        if viewModel.mode.isView ||
                            (viewModel.mode.isOrganise && !viewModel.isLastVisibleVault(vault)) {
                            PassDivider()
                        }
                    }
                }

                if viewModel.mode.isOrganise {
                    if !viewModel.hiddenShareIds.isEmpty {
                        Text("Hidden vaults")
                            .fontWeight(.semibold)
                            .foregroundStyle(PassColor.textNorm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)
                            .padding(.bottom, 4)
                        // swiftlint:disable:next line_length
                        Text("These vaults will not be accessible and their content won't be available to Search or Autofill.")
                            .foregroundStyle(PassColor.textWeak)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom)
                    }

                    ForEach(viewModel.filteredOrderedVaults) { vault in
                        if viewModel.hiddenShareIds.contains(vault.shareId) {
                            vaultRow(for: .precise(vault))
                            if !viewModel.isLastHiddenVault(vault) {
                                PassDivider()
                            }
                        }
                    }
                }

                if viewModel.mode.isView {
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
        }
        .padding(.horizontal)
        .scrollViewEmbeded()
    }

    @ViewBuilder
    func vaultRow(for selection: VaultSelection) -> some View {
        let itemCount = viewModel.itemCount(for: selection)

        let vaultRowMode: VaultRowMode = switch viewModel.mode {
        case .view:
            .view(isSelected: viewModel.isSelected(selection),
                  isHidden: false, // isHidden is not applicable when viewing visible vaults
                  action: { vault in
                      if viewModel.canShare(vault: vault) {
                          viewModel.share(vault: vault)
                      } else {
                          viewModel.router.present(for: .manageSharedShare(.vault(vault), .none))
                      }
                  })

        case .organise:
            .organise(isHidden: viewModel.hiddenShareIds.contains(selection.share?.shareId ?? ""))
        }

        HStack {
            Button(action: {
                switch viewModel.mode {
                case .view:
                    dismiss()
                    viewModel.select(selection)

                case .organise:
                    if let share = selection.share {
                        viewModel.hideOrUnhide(share: share)
                    }
                }
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

            if viewModel.mode.isView {
                Spacer()

                switch selection {
                case .all, .sharedByMe, .sharedWithMe:
                    EmptyView()
                case let .precise(vault):
                    vaultTrailingView(vault, haveItems: itemCount > 0)
                case .trash:
                    trashTrailingView
                }
            }
        }
    }

    func threeDotsIcon() -> some View {
        Image(uiImage: IconProvider.threeDotsVertical)
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
                        Image(uiImage: IconProvider.pencil)
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
    var trashTrailingView: some View {
        let trashedAliasesCount = viewModel.trashedAliasesCount
        let showAliasWarning = trashedAliasesCount > 0
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

extension VaultSelection {
    var title: String {
        switch self {
        case .all:
            #localized("All items")
        case let .precise(vault):
            vault.vaultName ?? ""
        case .trash:
            #localized("Trash")
        case .sharedByMe:
            #localized("Shared by me")
        case .sharedWithMe:
            #localized("Shared with me")
        }
    }

    var icon: UIImage {
        switch self {
        case .all:
            PassIcon.brandPass
        case let .precise(vault):
            vault.vaultBigIcon ?? PassIcon.vaultIcon1Big
        case .trash:
            IconProvider.trash
        case .sharedByMe:
            IconProvider.userArrowRight
        case .sharedWithMe:
            IconProvider.userArrowLeft
        }
    }

    var color: Color {
        switch self {
        case .all, .sharedByMe, .sharedWithMe:
            PassColor.interactionNormMajor2
        case let .precise(vault):
            vault.mainColor ?? PassColor.textWeak
        case .trash:
            PassColor.textWeak
        }
    }

    var share: Share? {
        switch self {
        case let .precise(vault):
            vault
        default:
            nil
        }
    }
}
