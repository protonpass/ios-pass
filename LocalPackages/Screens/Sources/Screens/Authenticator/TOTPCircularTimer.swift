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

public struct TOTPCircularTimer: View {
    private let total: Double

    public init(data: TOTPTimerData) {
        total = Double(max(data.total, 1))
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = context.date.timeIntervalSince1970.truncatingRemainder(dividingBy: total)
            TOTPCircularTimerContent(remainingSeconds: total - elapsed, total: total)
        }
    }
}

private struct TOTPCircularTimerContent: View {
    let remainingSeconds: Double
    let total: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(PassColor.textHint, style: StrokeStyle(lineWidth: 3))

            Circle()
                .trim(from: 0, to: remainingSeconds / total)
                .stroke(color, style: StrokeStyle(lineWidth: 3))
                .rotationEffect(.degrees(-90))
                .animation(.default, value: remainingSeconds)

            Text(verbatim: "\(Int(remainingSeconds))")
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(PassColor.textWeak)
                .animationsDisabled()
        }
        .frame(width: 32, height: 32)
    }

    private var color: Color {
        remainingSeconds <= 10 ? PassColor.signalDanger : PassColor.signalSuccess
    }
}
