//
// NonEditableVaultAlertModifier.swift
// Proton Pass - Created on 10/10/2023.
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

public struct NonEditableVaultAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDiscard: () -> Void

    public init(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) {
        _isPresented = isPresented
        self.onDiscard = onDiscard
    }

    public func body(content: Content) -> some View {
        content
            .alert("Non editable vault",
                   isPresented: $isPresented,
                   actions: {
                       Button("Continue item creation", role: .cancel, action: {})
                       Button("Stop item creation process", role: .destructive, action: onDiscard)
                   },
                   message: {
                       // swiftlint:disable:next line_length
                       Text("You didn't have editable clearance on the selected vault, we have chosen a new one for you")
                   })
    }
}

public extension View {
    func nonEditableVaultAlert(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) -> some View {
        modifier(NonEditableVaultAlertModifier(isPresented: isPresented, onDiscard: onDiscard))
    }
}
