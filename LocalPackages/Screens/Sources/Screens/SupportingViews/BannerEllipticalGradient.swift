//
// BannerEllipticalGradient.swift
// Proton Pass - Created on 09/01/2025.
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

struct BannerEllipticalGradient: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        EllipticalGradient(stops:
            [
                Gradient.Stop(color: Color(red: 0.57, green: 0.32, blue: 0.92),
                              location: 0.00),
                Gradient.Stop(color: Color(red: 0.36, green: 0.33, blue: 0.93),
                              location: 1.00)
            ],
            center: UnitPoint(x: 0.85, y: 0.19))
            .overlay(Color.black.opacity(gradientBackgroundOpcacity))
    }
}

private extension BannerEllipticalGradient {
    var gradientBackgroundOpcacity: CGFloat {
        switch colorScheme {
        case .dark:
            0.5
        default:
            0.3
        }
    }
}
