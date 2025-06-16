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

// swiftlint:disable:next type_body_length
struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditableVaultListViewModel()
    @State private var mode: Mode = .view
    @State private var vaultNameConfirmation = ""
    @State private var vaultToDelete: Share?
    @State private var isShowingEmptyTrashAlert = false

    enum Mode {
        case view, organise

        var isView: Bool {
            if case .view = self {
                true
            } else {
                false
            }
        }

        var isOrganise: Bool {
            if case .organise = self {
                true
            } else {
                false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch viewModel.state {
                    case .error, .loading:
                        // Should never happen
                        ProgressView()
                    case let .loaded(uiModel):
                        if mode.isOrganise {
                            hiddenVaultsBanner
                        } else {
                            vaultRow(for: .all)
                            PassDivider()
                        }

                        ForEach(uiModel.filteredOrderedVaults.filter {
                            if mode.isView {
                                !$0.hidden
                            } else {
                                true
                            }
                        }) { vault in
                            vaultRow(for: .precise(vault))
                            PassDivider()
                        }

                        if mode.isView {
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
            }
            HStack {
                switch mode {
                case .view:
                    CapsuleLabelButton(icon: IconProvider.plus,
                                       title: #localized("Create vault"),
                                       titleColor: PassColor.interactionNormMajor2,
                                       backgroundColor: PassColor.interactionNormMinor1,
                                       fontWeight: .semibold,
                                       action: viewModel.createNewVault)
                        .fixedSize(horizontal: true, vertical: true)
                        .hidden(viewModel.organization?.settings?.vaultCreateMode == .adminsOnly)

                case .organise:
                    CapsuleTextButton(title: #localized("Cancel"),
                                      titleColor: PassColor.interactionNormMajor2,
                                      fontWeight: .semibold,
                                      backgroundColor: PassColor.interactionNormMinor1,
                                      horizontalPadding: DesignConstant.sectionPadding * 2,
                                      action: { mode = .view; viewModel.resetHiddenShareIds() })
                        .fixedSize(horizontal: true, vertical: true)
                }

                Spacer()

                if viewModel.hideShowVaultSupported {
                    switch mode {
                    case .view:
                        CapsuleLabelButton(icon: IconProvider.listBullets,
                                           title: #localized("Organise vaults"),
                                           titleColor: PassColor.interactionNormMajor2,
                                           backgroundColor: PassColor.interactionNormMinor1,
                                           fontWeight: .semibold,
                                           action: { mode = .organise })
                            .fixedSize(horizontal: true, vertical: true)

                    case .organise:
                        CapsuleTextButton(title: #localized("Done"),
                                          titleColor: PassColor.interactionNormMajor2,
                                          fontWeight: .semibold,
                                          backgroundColor: PassColor.interactionNormMinor1,
                                          horizontalPadding: DesignConstant.sectionPadding * 2,
                                          action: viewModel.applyVaultsOrganizations)
                            .fixedSize(horizontal: true, vertical: true)
                    }
                }
            }
            .padding([.bottom, .horizontal])
        }
        .animation(.default, value: mode)
        .background(PassColor.backgroundWeak.toColor)
        .showSpinner(viewModel.loading)
        .onChange(of: viewModel.exitOrganiseMode) { _ in
            mode = .view
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var hiddenVaultsBanner: some View {
        Text("Hidden vaults won’t be visible during search and autofill.")
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .foregroundStyle(PassColor.textNorm.toColor)
            .padding()
            .background(PassColor.interactionNormMinor1.toColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstant.sectionPadding))
            .padding(.vertical)
    }

    @ViewBuilder
    private func vaultRow(for selection: VaultSelection) -> some View {
        let itemCount = viewModel.itemCount(for: selection)

        let vaultRowMode: VaultRowMode = switch mode {
        case .view:
            .view(isSelected: viewModel.isSelected(selection),
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
                switch mode {
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
                                          backgroundColor: selection.color.withAlphaComponent(0.16))
                         },
                         title: selection.title,
                         itemCount: itemCount,
                         share: selection.share,
                         mode: vaultRowMode,
                         height: 74)
            })
            .buttonStyle(.plain)

            if mode.isView {
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

    private func threeDotsIcon() -> some View {
        Image(uiImage: IconProvider.threeDotsVertical)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(PassColor.textWeak.toColor)
    }

    @ViewBuilder
    private func vaultTrailingView(_ vault: Share, haveItems: Bool) -> some View {
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
    private var trashTrailingView: some View {
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

    var color: UIColor {
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
