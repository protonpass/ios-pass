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

import SwiftUI
import UIComponents

struct EditableVaultListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditableVaultListViewModel

    var body: some View {
        let vaultsManager = viewModel.vaultsManager
        VStack(alignment: .leading) {
            NotchView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
            ScrollView {
                VStack(spacing: 0) {
                    switch vaultsManager.state {
                    case .loading, .error:
                        // Should never happen
                        ProgressView()
                    case .loaded(let vaults):
                        Button(action: {
                            dismiss()
                            vaultsManager.select(vault: nil)
                        }, label: {
                            VaultRow(
                                thumbnail: {
                                    CircleButton(icon: PassIcon.allVaults,
                                                 color: .passBrand,
                                                 backgroundOpacity: 0.16,
                                                 action: {})
                                },
                                title: "All vaults",
                                description: "\(vaultsManager.getItemCount(for: nil)) items",
                                isSelected: vaultsManager.isAllVaultsSelected())
                            .frame(height: 70)
                        })
                        .buttonStyle(.plain)

                        PassDivider()

                        ForEach(vaults, id: \.hashValue) { vault in
                            Button(action: {
                                dismiss()
                                vaultsManager.select(vault: vault.vault)
                            }, label: {
                                VaultRow(
                                    thumbnail: {
                                        CircleButton(
                                            icon: vault.vault.displayPreferences.icon.icon.image,
                                            color: vault.vault.displayPreferences.color.color.color,
                                            backgroundOpacity: 0.16,
                                            action: {})
                                    },
                                    title: vault.vault.name,
                                    description: "\(vaultsManager.getItemCount(for: vault.vault)) items",
                                    isSelected: vaultsManager.isSelected(vault.vault))
                                .frame(height: 70)
                            })
                            .buttonStyle(.plain)

                            PassDivider()
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                CapsuleTextButton(title: "Create vault",
                                  titleColor: .passBrand,
                                  backgroundColor: .passBrand.withAlphaComponent(0.08),
                                  disabled: false,
                                  maxWidth: nil,
                                  action: viewModel.createNewVault)
                Spacer()
            }
            .padding([.bottom, .horizontal])
        }
        .background(Color.passSecondaryBackground)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VaultRow<Thumbnail: View>: View {
    let thumbnail: () -> Thumbnail
    let title: String
    let description: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            thumbnail()

            VStack(alignment: .leading) {
                Text(title)
                Text(description)
                    .font(.callout)
                    .foregroundColor(Color.textWeak)
            }

            Spacer()

            if isSelected {
                Label("", systemImage: "checkmark")
                    .foregroundColor(.passBrand)
                    .padding(.trailing)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .contentShape(Rectangle())
    }
}
