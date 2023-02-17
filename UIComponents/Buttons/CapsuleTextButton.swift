//
// CapsuleTextButton.swift
// Proton Pass - Created on 16/02/2023.
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

/// A capsule button with a text as title
public struct CapsuleTextButton: View {
    let title: String
    let titleColor: UIColor
    let backgroundColor: UIColor
    let disabled: Bool
    let height: CGFloat
    let action: () -> Void

    public init(title: String,
                titleColor: UIColor,
                backgroundColor: UIColor,
                disabled: Bool,
                height: CGFloat = 40,
                action: @escaping () -> Void) {
        self.title = title
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.disabled = disabled
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(disabled ? .textDisabled : Color(uiColor: titleColor))
                .frame(height: height)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: backgroundColor).opacity(disabled ? 0.08 : 1))
                .clipShape(Capsule())
        }
    }
}
