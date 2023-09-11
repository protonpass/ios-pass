//
// ObsoleteItemAlertModifier.swift
// Proton Pass - Created on 28/10/2022.
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

public struct ObsoleteItemAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onAction: () -> Void

    public init(isPresented: Binding<Bool>, onAction: @escaping () -> Void) {
        _isPresented = isPresented
        self.onAction = onAction
    }

    public func body(content: Content) -> some View {
        content
            .alert("This item is obsolete",
                   isPresented: $isPresented,
                   actions: {
                       Button("OK", role: .cancel, action: onAction)
                   }, message: {
                       Text("Some changes happened to this item, heading back to the previous page.")
                   })
    }
}

public extension View {
    func obsoleteItemAlert(isPresented: Binding<Bool>, onAction: @escaping () -> Void) -> some View {
        modifier(ObsoleteItemAlertModifier(isPresented: isPresented, onAction: onAction))
    }
}
