//
// FullSheetBackgroundModifier.swift
// Proton Pass - Created on 19/12/2024.
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

/// Add background by embeding inside a ZStack to make the background always fill up the whole sheet
struct FullSheetBackgroundModifier: ViewModifier {
    private let color: Color

    init(color: Color) {
        self.color = color
    }

    func body(content: Content) -> some View {
        ZStack {
            color.ignoresSafeArea()
            content
        }
    }
}

public extension View {
    func fullSheetBackground(_ color: Color) -> some View {
        modifier(FullSheetBackgroundModifier(color: color))
    }
}
