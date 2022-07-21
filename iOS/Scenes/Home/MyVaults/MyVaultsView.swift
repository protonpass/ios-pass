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

import Client
import Combine
import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct MyVaultsView: View {
    let coordinator: MyVaultsCoordinator
    @ObservedObject var vaultSelection: VaultSelection

    private var selectedVaultName: String {
        vaultSelection.selectedVault?.name ?? "All vaults"
    }

    var body: some View {
        VStack {
            List {
                ForEach(0..<50, id: \.self) { index in
                    Text("\(selectedVaultName) #\(index)")
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
                            vaultSelection.update(selectedVault: nil)
                        }, label: {
                            Text("All vaults")
                        })
                    }

                    Section {
                        ForEach(vaultSelection.vaults, id: \.id) { vault in
                            Button(action: {
                                vaultSelection.update(selectedVault: vault)
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
                Button(action: coordinator.showCreateItemView) {
                    Image(uiImage: IconProvider.plus)
                }
                .foregroundColor(Color(.label))
            }
        }
    }
}

struct MyVaultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyVaultsView(coordinator: .preview,
                         vaultSelection: .preview)
        }
    }
}
