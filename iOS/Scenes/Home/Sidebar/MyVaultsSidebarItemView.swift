//
// MyVaultsSidebarItemView.swift
// Proton Pass - Created on 20/07/2022.
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
import Core
import ProtonCore_UIFoundations
import SwiftUI

struct MyVaultsSidebarItemView: View {
    @State private var expanded = false
    @ObservedObject var vaultSelection: VaultSelection

    var body: some View {
        LazyVStack {
            Button(action: {
                vaultSelection.update(selectedVault: nil)
            }, label: {
                HStack {
                    Label(title: {
                        Text("My vaults")
                            .foregroundColor(.white)
                    }, icon: {
                        Image(uiImage: IconProvider.vault)
                            .foregroundColor(.gray)
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .contentShape(Rectangle())

                    if !vaultSelection.vaults.isEmpty {
                        Button(action: {
                            withAnimation {
                                expanded.toggle()
                            }
                        }, label: {
                            Image(uiImage: IconProvider.chevronDown)
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                        })
                        .foregroundColor(.white)
                        .padding()
                        .contentShape(Rectangle())
                    }
                }
            })
            .buttonStyle(.sidebarItem)

            if expanded {
                ForEach(vaultSelection.vaults, id: \.id) { vault in
                    Button(action: {
                        vaultSelection.update(selectedVault: vault)
                    }, label: {
                        Label(title: {
                            Text(vault.name)
                                .foregroundColor(.white)
                        }, icon: {
                            Image(uiImage: IconProvider.vault)
                                .foregroundColor(.gray)
                        })
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 40)
                        .padding()
                        .contentShape(Rectangle())
                    })
                    .buttonStyle(.sidebarItem)
                }
            }
        }
    }
}

/*
struct MyVaultsSidebarItemView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(ColorProvider.SidebarBackground)
                .ignoresSafeArea(.all)
            MyVaultsSidebarItemView(vaultSelection: .preview)
        }
    }
}
*/
