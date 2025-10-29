//
// SshKeyDetailView.swift
// Proton Pass - Created on 11/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

public struct SshKeyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let value: String
    let title: LocalizedStringKey

    public init(value: String, title: LocalizedStringKey) {
        self.value = value
        self.title = title
    }

    public var body: some View {
        ScrollView {
            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .monospaced()
                .foregroundStyle(PassColor.textNorm)
                .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .principal) {
                Text(title)
                    .navigationTitleText()
            }
        }
        .fullSheetBackground()
        .navigationStackEmbeded()
    }
}
