//
// MyVaultsView.swift
// Proton Pass - Created on 07/07/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

protocol VaultProvider {
    var id: Int { get }
    var vaultName: String { get }
}

struct MyVaultsView: View {
    let coordinator: MyVaultsCoordinator
    @State private var selectedVaultId: Int = 0
    private let vaults: [PreviewVault] = [.init(id: 1, vaultName: "Private"),
                                          .init(id: 2, vaultName: "Work")]

    var body: some View {
        VStack {
            List {
                ForEach(0..<50, id: \.self) { index in
                    Text("\(vault(for: selectedVaultId)?.vaultName ?? "All vault") #\(index)")
                }
            }

            VaultSummaryView()
                .frame(height: 250)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ToggleSidebarButton(action: coordinator.showSidebar)
            }

            ToolbarItem(placement: .principal) {
                Menu(content: {
                    Section {
                        Button(action: {
                            selectedVaultId = 0
                        }, label: {
                            Text("All vault")
                        })
                    }

                    Section {
                        Picker("", selection: $selectedVaultId) {
                            ForEach(vaults, id: \.id) { vault in
                                Label(title: {
                                    Text(vault.vaultName)
                                }, icon: {
                                    Image(uiImage: IconProvider.briefcase)
                                })
                                    .tag(vault.id)
                            }
                        }
                        .labelsHidden()
                    }

                    Section {
                        Button(action: {
                            coordinator.showCreateVaultView()
                        }, label: {
                            Label(title: {
                                Text("Add vault")
                            }, icon: {
                                Image(uiImage: IconProvider.plus)
                            })
                        })
                    }
                }, label: {
                    ZStack {
                        Text(vault(for: selectedVaultId)?.vaultName ?? "All vault")
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
                Button(action: coordinator.showCreateItemView) {
                    Image(uiImage: IconProvider.plus)
                }
                .foregroundColor(Color(.label))
            }
        }
    }

    private func vault(for id: Int) -> PreviewVault? {
        vaults.first { $0.id == id }
    }
}

struct MyVaultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyVaultsView(coordinator: .preview)
        }
    }
}

struct PreviewVault: VaultProvider {
    let id: Int
    let vaultName: String
}
