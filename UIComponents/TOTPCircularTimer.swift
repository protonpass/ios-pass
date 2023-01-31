//
// TOTPCircularTimer.swift
// Proton Pass - Created on 18/01/2023.
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

public struct TOTPTimerData: Hashable {
    let total: Int
    let remaining: Int

    public init(total: Int, remaining: Int) {
        self.total = total
        self.remaining = remaining
    }
}

public struct TOTPCircularTimer: View {
    let percentage: CGFloat
    let data: TOTPTimerData

    public init(data: TOTPTimerData) {
        self.data = data
        self.percentage = CGFloat(data.remaining) / CGFloat(data.total)
    }

    public var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(color,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .rotationEffect(.degrees(270))
                .animation(.default, value: data)

            Text("\(data.remaining)")
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private var color: Color {
        switch percentage {
        case 0.25...0.49:
            return .blue
        case 0.5...:
            return .green
        default:
            return .red
        }
    }
}
