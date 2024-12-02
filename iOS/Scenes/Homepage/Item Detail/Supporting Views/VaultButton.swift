//
// VaultButton.swift
// Proton Pass - Created on 02/08/2023.
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

import DesignSystem
import Entities
import Factory
import SwiftUI

struct VaultButton: View {
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let vault: Share
    let vaultContent: VaultContent

    var body: some View {
        Button { router.present(for: .manageShareVault(vault, .none)) } label: {
            HStack {
                Label(title: {
                    Text(vaultContent.name)
                        .font(.footnote)
                }, icon: {
                    Image(uiImage: vaultContent.vaultSmallIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                })
                .foregroundStyle(vaultContent.mainColor.toColor)
                Text(verbatim: "•")
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(verbatim: "\(vault.members)")
                    .font(.footnote)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(vaultContent.backgroundColor.toColor)
        .clipShape(Capsule())
    }
}
