//
// SpinnerButton.swift
// Proton Pass - Created on 17/11/2022.
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

/// A button that can turn itself into a spinner in specific condition.
/// - Parameters:
///  - title: The title of the button.
///  - disabled: If `true`, the button opacity will be reduced to `0.5`.
///  - spinning: If `true`, the button will turn itself into a spinner.
///  - action: The action of the button when tapped.
public struct SpinnerButton: View {
    let title: String
    let disabled: Bool
    let spinning: Bool
    let action: () async -> Void

    public init(title: String,
                disabled: Bool,
                spinning: Bool,
                action: @escaping () async -> Void) {
        self.title = title
        self.disabled = disabled
        self.spinning = spinning
        self.action = action
    }

    public var body: some View {
        if spinning {
            ProgressView()
                .animation(.default, value: spinning)
        } else {
            Button(action: {
                Task { await action() }
            }, label: {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(.interactionNorm)
            })
            .opacityReduced(disabled)
            .animation(.default, value: spinning)
        }
    }
}
