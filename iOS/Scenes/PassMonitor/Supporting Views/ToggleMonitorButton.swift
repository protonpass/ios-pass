//
// ToggleMonitorButton.swift
// Proton Pass - Created on 23/04/2024.
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

import Macro
import SwiftUI

struct ToggleMonitorButton: View {
    let monitored: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let label = monitored ? #localized("Disable monitoring") : #localized("Enable monitoring")
            let icon = monitored ? "eye.slash" : "eye"
            Label(label, systemImage: icon)
        }
    }
}