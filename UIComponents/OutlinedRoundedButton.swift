//
// OutlinedRoundedButton.swift
// Proton Pass - Created on 16/11/2022.
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

public struct OutlinedRoundedButton: View {
    let title: String
    let tintColor: Color
    let action: () -> Void

    public init(title: String,
                tintColor: Color,
                action: @escaping () -> Void) {
        self.title = title
        self.tintColor = tintColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(tintColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(tintColor, lineWidth: 1))
        }
    }
}

public struct MoveToTrashButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        OutlinedRoundedButton(title: "Move to trash",
                              tintColor: .notificationError,
                              action: action)
    }
}
