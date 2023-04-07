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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditableVaultListViewModel
    @State private var isShowingEmptyTrashAlert = false

    var body: some View {
        let vaultsManager = viewModel.vaultsManager
        VStack(alignment: .leading) {
            Handle()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
            ScrollView {
                VStack(spacing: 0) {
                    switch vaultsManager.state {
                    case .loading, .error:
                        // Should never happen
                        ProgressView()
                    case let .loaded(vaults, _):
                        vaultRow(for: .all)

                        PassDivider()

                        ForEach(vaults, id: \.hashValue) { vault in
                            vaultRow(for: .precise(vault.vault))
                            PassDivider()
                        }

                        vaultRow(for: .trash)
                    }
                }
                .padding(.horizontal)
            }
            .animation(.default, value: vaultsManager.state)

            HStack {
                CapsuleTextButton(title: "Create vault",
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  action: viewModel.createNewVault)
                .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }
            .padding([.bottom, .horizontal])
        }
        .background(Color(uiColor: PassColor.backgroundWeak))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func vaultRow(for selection: VaultSelection) -> some View {
        let vaultsManager = viewModel.vaultsManager

        HStack {
            Button(action: {
                dismiss()
                vaultsManager.select(selection)
            }, label: {
                VaultRow(
                    thumbnail: {
                        CircleButton(icon: selection.icon,
                                     iconColor: selection.color,
                                     backgroundColor: selection.color.withAlphaComponent(0.16))
                    },
                    title: selection.title,
                    itemCount: vaultsManager.getItemCount(for: selection),
                    isSelected: vaultsManager.isSelected(selection))
            })
            .buttonStyle(.plain)

            Spacer()

            switch selection {
            case .all:
                // Gimmick view to take up space
                threeDotsIcon().opacity(0)
            case .precise(let vault):
                vaultTrailingView(vault)
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
    private func vaultTrailingView(_ vault: Vault) -> some View {
        Menu(content: {
            Button(action: {
                viewModel.edit(vault: vault)
            }, label: {
                Label(title: {
                    Text("Edit")
                }, icon: {
                    Image(uiImage: IconProvider.pencil)
                })
            })

            Divider()

            Button(
                role: .destructive,
                action: { viewModel.delete(vault: vault) },
                label: {
                    Label(title: {
                        Text("Delete vault")
                    }, icon: {
                        Image(uiImage: IconProvider.trash)
                    })
                })
        }, label: threeDotsIcon)
    }

    @ViewBuilder
    private var trashTrailingView: some View {
        if viewModel.vaultsManager.getItemCount(for: .trash) > 0 {
            Menu(content: {
                Button(action: viewModel.restoreAllTrashedItems) {
                    Label(title: {
                        Text("Restore all items")
                    }, icon: {
                        Image(uiImage: IconProvider.clockRotateLeft)
                    })
                }

                Divider()

                Button(
                    role: .destructive,
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
            .alert(
                "Empty trash",
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
            return "All vaults"
        case .precise(let vault):
            return vault.name
        case .trash:
            return "Trash"
        }
    }

    var icon: UIImage {
        switch self {
        case .all:
            return PassIcon.allVaults
        case .precise(let vault):
            return vault.displayPreferences.icon.icon.image
        case .trash:
            return IconProvider.trash
        }
    }

    var color: UIColor {
        switch self {
        case .all:
            return PassColor.interactionNorm
        case .precise(let vault):
            return vault.displayPreferences.color.color.color
        case .trash:
            return PassColor.textWeak
        }
    }
}
