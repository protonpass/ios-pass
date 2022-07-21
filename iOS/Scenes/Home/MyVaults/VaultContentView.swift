//
// VaultContentView.swift
// Proton Pass - Created on 21/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

struct VaultContentView: View {
    @StateObject private var viewModel: VaultContentViewModel

    private var selectedVaultName: String {
        viewModel.selectedVault?.name ?? "All vaults"
    }

    init(viewModel: VaultContentViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            List {
                ForEach(0..<50) { index in
                    Text("\(selectedVaultName) #\(index)")
                }
            }
            VaultSummaryView()
                .frame(height: 250)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ToggleSidebarButton(action: viewModel.toggleSidebarAction)
            }

            ToolbarItem(placement: .principal) {
                Menu(content: {
                    Section {
                        Button(action: {
                            viewModel.update(selectedVault: nil)
                        }, label: {
                            Text("All vaults")
                        })
                    }

                    Section {
                        ForEach(viewModel.vaults, id: \.id) { vault in
                            Button(action: {
                                viewModel.update(selectedVault: vault)
                            }, label: {
                                Label(title: {
                                    Text(vault.name)
                                }, icon: {
                                    Image(uiImage: IconProvider.briefcase)
                                })
                            })
                        }
                    }

                    Section {
                        Button(action: viewModel.createVaultAction) {
                            Label(title: {
                                Text("Add vault")
                            }, icon: {
                                Image(uiImage: IconProvider.plus)
                            })
                        }
                    }
                }, label: {
                    ZStack {
                        Text(selectedVaultName)
                            .fontWeight(.medium)
                            .transaction { transaction in
                                transaction.animation = nil
                            }

                        HStack {
                            Spacer()
                            Image(uiImage: IconProvider.chevronDown)
                        }
                        .padding(.trailing)
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width / 2)
                    .padding(.vertical, 8)
                    .background(Color(ColorProvider.BrandNorm))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                })
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.createItemAction) {
                    Image(uiImage: IconProvider.plus)
                }
                .foregroundColor(Color(.label))
            }
        }
    }
}
