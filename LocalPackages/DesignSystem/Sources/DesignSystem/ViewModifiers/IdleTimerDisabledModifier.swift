//
// IdleTimerDisabledModifier.swift
// Proton Pass - Created on 06/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

private struct IdleTimerDisabledModifier: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: disabled, initial: true) {
                UIApplication.shared.isIdleTimerDisabled = disabled
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
    }
}

public extension View {
    /// Keeps the device from auto-locking while `disabled` is true.
    /// The idle timer is app-global: the last writer wins, and disappearing resets it to enabled.
    func idleTimerDisabled(_ disabled: Bool) -> some View {
        modifier(IdleTimerDisabledModifier(disabled: disabled))
    }
}
