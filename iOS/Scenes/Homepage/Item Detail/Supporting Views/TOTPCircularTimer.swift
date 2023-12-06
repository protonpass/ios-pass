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

import DesignSystem
import Entities
import SwiftUI

struct TOTPCircularTimer: View {
    let percentage: CGFloat
    let data: TOTPTimerData

    init(data: TOTPTimerData) {
        self.data = data
        percentage = CGFloat(data.remaining) / CGFloat(data.total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: PassColor.textHint), style: StrokeStyle(lineWidth: 3))

            Circle()
                .trim(from: 0, to: percentage)
                .stroke(color, style: StrokeStyle(lineWidth: 3))
                .rotationEffect(.degrees(-90))
                .transaction { transaction in
                    // Do not animate when closing the ring and start a new loop
                    if data.remaining == data.total {
                        transaction.animation = nil
                    }
                }
                .animation(.default, value: data)

            Text(verbatim: "\(data.remaining)")
                .font(.caption)
                .fontWeight(.light)
                .foregroundColor(Color(uiColor: PassColor.textWeak))
                .animationsDisabled()
        }
        .frame(width: 32, height: 32)
    }

    private var color: Color {
        switch data.remaining {
        case 0...10:
            Color(uiColor: PassColor.signalDanger)
        default:
            Color(uiColor: PassColor.signalSuccess)
        }
    }
}
