//
// UpsellableDetailText.swift
// Proton Pass - Created on 26/06/2023.
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

/// When `shouldUpgrade` is `true`:
/// - Display upgrade button
///
/// When `shouldUpgrade` is `false`:
/// - If `text` is empty, display placeholder
/// - Otherwise display text as normal
struct UpsellableDetailText: View {
    let text: String
    let placeholder: String?
    let shouldUpgrade: Bool
    let upgradeTextColor: Color
    let onUpgrade: () -> Void

    var body: some View {
        if shouldUpgrade {
            UpgradeButtonLite(foregroundColor: upgradeTextColor, action: onUpgrade)
        } else {
            if text.isEmpty, let placeholder {
                Text(placeholder)
                    .placeholderText()
            } else {
                Text(text)
                    .sectionContentText()
            }
        }
    }
}
