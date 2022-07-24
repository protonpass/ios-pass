//
// SidebarView.swift
// Proton Pass - Created on 06/07/2022.
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
import UIComponents

struct SidebarView: View {
    let coordinator: HomeCoordinator
    let width: CGFloat

    var body: some View {
        ZStack {
            Color(ColorProvider.SidebarBackground)
                .ignoresSafeArea(.all)

            let user = coordinator.sessionData.userData.user
            VStack(spacing: 0) {
                SidebarCurrentUserView(
                    userInfoProvider: user,
                    action: coordinator.showUserSwitcher
                )
                .padding(.horizontal, 8)

                ScrollView(showsIndicators: false) {
                    VStack {
                        MyVaultsSidebarItemView(vaultSelection: coordinator.vaultSelection)
                        SidebarItemView(item: .settings,
                                        action: coordinator.handleSidebarItem)
                        SidebarItemView(item: .trash,
                                        action: coordinator.handleSidebarItem)
                        SidebarItemView(item: .help,
                                        action: coordinator.handleSidebarItem)
                        SidebarItemView(item: .signOut,
                                        action: coordinator.handleSidebarItem)
                    }
                    .padding(.vertical)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()
                Text("Proton Pass \(Bundle.main.versionNumber) (\(Bundle.main.buildNumber))")
                    .foregroundColor(.gray)
            }
            .padding(.leading, UIScreen.main.bounds.width - width)
        }
    }
}

private struct SidebarItemView: View {
    let item: SidebarItem
    let action: (SidebarItem) -> Void

    var body: some View {
        Button(action: {
            action(item)
        }, label: {
            Label(title: {
                Text(item.title)
                    .foregroundColor(.white)
            }, icon: {
                Image(uiImage: item.icon)
                    .foregroundColor(.gray)
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .contentShape(Rectangle())
        })
        .buttonStyle(.sidebarItem)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(coordinator: .preview,
                    width: 300)
    }
}

extension Array where Element == Vault {
    static var preview: [Vault] = [
        Vault(id: UUID().uuidString,
              name: "Private",
              description: "Private vault"),
        Vault(id: UUID().uuidString,
              name: "Business",
              description: "Business vault")
    ]
}
