//
// AliasTrashAlertModifier.swift
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

import SwiftUI

struct AliasTrashAlertModifier: ViewModifier {
    @Binding var showingTrashAliasAlert: Bool
    let enabled: Bool
    let disableAction: () -> Void
    let trashAction: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("Move to Trash", isPresented: $showingTrashAliasAlert) {
                if enabled {
                    Button("Disable instead") {
                        disableAction()
                    }
                }
                Button("Move to Trash") { trashAction() }
                Button("Cancel", role: .cancel) {}
            } message: {
                if enabled {
                    // swiftlint:disable:next line_length
                    Text("Aliases in Trash will continue forwarding emails. If you want to stop receiving emails on this address, disable it instead.")
                }
            }
    }
}
