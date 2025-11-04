//
// FittedPresentationDetentModifier.swift
// Proton Pass - Created on 04/11/2025.
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

import SwiftUI

private struct FittedPresentationDetentModifier: ViewModifier {
    @State private var height = 0.0
    let onHeightChanged: ((Double) -> Void)?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: Double.self,
                              of: { $0.size.height },
                              action: { newHeight in
                                  if newHeight != height {
                                      height = newHeight
                                      onHeightChanged?(newHeight)
                                  }
                              })
            .presentationDetents([.height(height)])
    }
}

public extension View {
    /// Automatically adjust sheet detent height base on content size
    /// Optionally report back the height for further processing if necessary
    func fittedPresentationDetent(onHeightChanged: ((Double) -> Void)?) -> some View {
        modifier(FittedPresentationDetentModifier(onHeightChanged: onHeightChanged))
    }
}
