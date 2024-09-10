//
// AccountsMenu.swift
// Proton Pass - Created on 10/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import DesignSystem
import Entities
import Macro
import SwiftUI

public struct AccountsMenu: View {
    @Binding private var selectedUser: PassUser?
    private let users: [PassUser]

    public init(selectedUser: Binding<PassUser?>,
                users: [PassUser]) {
        _selectedUser = selectedUser
        self.users = users
    }

    public var body: some View {
        let allAccountsMessage = #localized("All %lld accounts", users.count)
        Menu(content: {
            Button(action: {
                selectedUser = nil
            }, label: {
                if selectedUser == nil {
                    Label(allAccountsMessage, systemImage: "checkmark")
                } else {
                    Text(verbatim: allAccountsMessage)
                }
            })

            Section {
                ForEach(users) { user in
                    Button(action: {
                        selectedUser = user
                    }, label: {
                        if user == selectedUser {
                            Label(user.email ?? "?", systemImage: "checkmark")
                        } else {
                            Text(verbatim: user.email ?? "?")
                        }
                    })
                }
            }
        }, label: {
            HStack {
                if let selectedUser {
                    Text(verbatim: selectedUser.displayNameAndEmail)
                        .font(.callout)
                        .foregroundStyle(PassColor.textInvert.toColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PassColor.interactionNormMajor2.toColor)
                        .clipShape(Capsule())
                } else {
                    Text(verbatim: allAccountsMessage)
                        .fontWeight(.medium)
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                }

                Spacer()
            }
        })
    }
}
