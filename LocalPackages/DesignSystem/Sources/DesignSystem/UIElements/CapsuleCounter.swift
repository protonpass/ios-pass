//
// CapsuleCounter.swift
// Proton Pass - Created on 17/06/2024.
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

import SwiftUI

public struct CapsuleCounter: View {
    let count: Int
    let foregroundStyle: Color
    let background: Color

    public init(count: Int, foregroundStyle: Color, background: Color) {
        self.count = count
        self.foregroundStyle = foregroundStyle
        self.background = background
    }

    public var body: some View {
        Text(verbatim: "\(count)")
            .fontWeight(.medium)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .foregroundStyle(foregroundStyle)
            .background(background)
            .clipShape(Capsule())
    }
}
