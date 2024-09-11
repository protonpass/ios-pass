//
// View+ConfirmUserDialog.swift
// Proton Pass - Created on 11/09/2024.
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

import Entities
import SwiftUI

private struct ConfirmUserDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let users: [PassUser]
    let onSelect: (PassUser) -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Create",
                                isPresented: $isPresented,
                                actions: {
                                    ForEach(users) { user in
                                        Button(action: {
                                            onSelect(user)
                                        }, label: {
                                            Text(verbatim: user.email ?? user.displayName ?? "?")
                                        })
                                    }
                                    Button("Cancel", role: .cancel, action: {})
                                },
                                message: {
                                    Text("Select account")
                                })
    }
}

extension View {
    func confirmUserDialog(isPresented: Binding<Bool>,
                           users: [PassUser],
                           onSelect: @escaping (PassUser) -> Void) -> some View {
        modifier(ConfirmUserDialogModifier(isPresented: isPresented,
                                           users: users,
                                           onSelect: onSelect))
    }
}
