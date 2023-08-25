//
// DiscardChangesAlertModifier.swift
// Proton Pass - Created on 16/09/2022.
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

import SwiftUI

public struct DiscardChangesAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDiscard: () -> Void

    public init(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) {
        _isPresented = isPresented
        self.onDiscard = onDiscard
    }

    public func body(content: Content) -> some View {
        content
            .alert("Discard changes?",
                   isPresented: $isPresented,
                   actions: {
                       Button("Keep Editing", role: .cancel, action: {})
                       Button("Discard", role: .destructive, action: onDiscard)
                   },
                   message: {
                       Text("You have unsaved changes, are you sure you want to discard them?")
                   })
    }
}

public extension View {
    func discardChangesAlert(isPresented: Binding<Bool>, onDiscard: @escaping () -> Void) -> some View {
        modifier(DiscardChangesAlertModifier(isPresented: isPresented, onDiscard: onDiscard))
    }
}
