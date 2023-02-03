//
// TOTPCircularTimer.swift
// Proton Pass - Created on 03/02/2023.
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

struct TOTPTimerData: Hashable {
    public let total: Int
    public let remaining: Int

    public init(total: Int, remaining: Int) {
        self.total = total
        self.remaining = remaining
    }
}

struct TOTPCircularTimer: View {
    let percentage: CGFloat
    let data: TOTPTimerData

    init(data: TOTPTimerData) {
        self.data = data
        self.percentage = CGFloat(data.remaining) / CGFloat(data.total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray, style: StrokeStyle(lineWidth: 2, lineCap: .round))

            Circle()
                .trim(from: 0, to: percentage)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                .rotationEffect(.degrees(270))
                .animation(.default, value: data)

            Text("\(data.remaining)")
                .font(.caption2)
                .fontWeight(.bold)
                .transaction { transaction in
                    transaction.animation = nil
                }
        }
    }

    private var color: Color {
        switch data.remaining {
        case 0...10:
            return .red
        default:
            return .green
        }
    }
}
