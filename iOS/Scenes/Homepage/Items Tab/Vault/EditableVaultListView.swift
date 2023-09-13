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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditableVaultListViewModel
    @State private var isShowingEmptyTrashAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(spacing: 0) {
                    switch viewModel.state {
                    case .error, .loading:
                        // Should never happen
                        ProgressView()
                    case let .loaded(vaults, _):
                        vaultRow(for: .all)

                        PassDivider()

                        ForEach(vaults, id: \.hashValue) { vault in
                            vaultRow(for: .precise(vault.vault), vaultContent: vault)
                            PassDivider()
                        }

                        vaultRow(for: .trash)

                        PassDivider()
                    }
                }
                .padding(.horizontal)
            }
            .animation(.default, value: viewModel.state)
            HStack {
                CapsuleTextButton(title: "Create vault".localized,
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  action: viewModel.createNewVault)
                    .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }
            .padding([.bottom, .horizontal])
        }
        .background(Color(uiColor: PassColor.backgroundWeak))
        .showSpinner(viewModel.loading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("Aliases won't be shared",
               isPresented: $viewModel.showingAliasAlert,
               actions: {
                   Button(action: {
                              viewModel.router.present(for: .sharingFlow)
                          },
                          label: {
                              Text("OK")
                          })
               },
               message: {
                   Text("not shared %d alias(es)".localized(viewModel.numberOfAliasForSharedVault))
               })
    }

    @ViewBuilder
    private func vaultRow(for selection: VaultSelection, vaultContent: VaultContentUiModel? = nil) -> some View {
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
                         itemCount: vaultContent?.itemCount ?? 0,
                         isShared: selection.shared,
                         isSelected: viewModel.isSelected(selection),
                         height: 74)
            })
            .buttonStyle(.plain)

            Spacer()

            switch selection {
            case .all:
                EmptyView()
            case let .precise(vault):
                vaultTrailingView(vault, vaultContent: vaultContent)
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
            .foregroundColor(Color(uiColor: PassColor.textWeak))
    }

    @ViewBuilder
    private func vaultTrailingView(_ vault: Vault, vaultContent: VaultContentUiModel? = nil) -> some View {
        Menu(content: {
            if vault.isOwner {
                Button(action: {
                    viewModel.edit(vault: vault)
                }, label: {
                    Label(title: {
                        Text("Edit")
                    }, icon: {
                        Image(uiImage: IconProvider.pencil)
                            .renderingMode(.template)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    })
                })
            }

            if !vault.isPrimary, vault.isOwner, viewModel.isAllowedToShare, !vault.shared {
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
                    viewModel.router.present(for: .manageShareVault(vault, dismissBeforeShowing: false))
                }, label: {
                    Label(title: {
                        Text(vault.isAdmin ? "Manage access" : "View members")
                    }, icon: {
                        IconProvider.users
                    })
                })
            }

            if let vaultContent, !vaultContent.items.isEmpty {
                Button(action: {
                    viewModel.router.present(for: .moveItemsBetweenVault(currentVault: vault,
                                                                         singleItemToMove: nil))
                }, label: {
                    Label(title: {
                        Text("Move all items to another vault")
                    }, icon: {
                        IconProvider.users
                    })
                })
            }

            Divider()

            Button(role: .destructive,
                   action: { vault.isOwner ? viewModel.delete(vault: vault) : viewModel.leaveVault(vault: vault) },
                   label: {
                       Label(title: {
                           vault.isOwner ? Text("Delete vault") : Text("Leave vault")
                       }, icon: {
                           Image(uiImage: IconProvider.trash)
                       })
                   })
        }, label: threeDotsIcon)
    }

    @ViewBuilder
    private var trashTrailingView: some View {
        if viewModel.hasTrash {
            Menu(content: {
                Button(action: viewModel.restoreAllTrashedItems) {
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
                                  action: viewModel.emptyTrash,
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
            return "All vaults".localized
        case let .precise(vault):
            return vault.name
        case .trash:
            return "Trash".localized
        }
    }

    var icon: UIImage {
        switch self {
        case .all:
            return PassIcon.brandPass
        case let .precise(vault):
            return vault.displayPreferences.icon.icon.bigImage
        case .trash:
            return IconProvider.trash
        }
    }

    var color: UIColor {
        switch self {
        case .all:
            return PassColor.interactionNormMajor2
        case let .precise(vault):
            return vault.displayPreferences.color.color.color
        case .trash:
            return PassColor.textWeak
        }
    }
}
