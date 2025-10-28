//
// PassProgressViewStyle.swift
// Proton Pass - Created on 13/09/2023.
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

/// A progress view with taller height than a standard one
public struct PassProgressViewStyle: ProgressViewStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .frame(height: 8)
            .scaleEffect(x: 1, y: 2, anchor: .center)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accentColor(PassColor.interactionNorm)
            .tint(PassColor.interactionNorm)
    }
}

public extension ProgressViewStyle where Self == PassProgressViewStyle {
    static var pass: PassProgressViewStyle { .init() }
}
