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

@MainActor
public final class TOTPCircularTimerViewModel: ObservableObject {
    @Published private(set) var remainingSeconds = 1.0
    @Published private(set) var percentage = 1.0

    private var timer: Timer?

    private(set) var data: TOTPTimerData

    init(data: TOTPTimerData) {
        self.data = data
        percentage = CGFloat(data.remaining) / CGFloat(data.total)
        remainingSeconds = Double(self.data.remaining)

        startTimer()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func startTimer() {
        timer?.invalidate()
        timer = nil

        // Create a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                remainingSeconds -= 1
                percentage = remainingSeconds / Double(data.total)
            }
        }
    }

    func stopTimer() {
        timer?.invalidate() // Stop the timer
        timer = nil // Clear the timer
    }
}

public struct TOTPCircularTimer: View {
    @ObservedObject var viewModel: TOTPCircularTimerViewModel

    public init(data: TOTPTimerData) {
        _viewModel = .init(wrappedValue: TOTPCircularTimerViewModel(data: data))
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(PassColor.textHint.toColor, style: StrokeStyle(lineWidth: 3))

            Circle()
                .trim(from: 0, to: viewModel.percentage)
                .stroke(color, style: StrokeStyle(lineWidth: 3))
                .rotationEffect(.degrees(-90))
                .animation(.default, value: viewModel.percentage)

            Text(verbatim: "\(Int(viewModel.remainingSeconds))")
                .font(.caption)
                .fontWeight(.light)
                .foregroundStyle(PassColor.textWeak.toColor)
                .animationsDisabled()
        }
        .frame(width: 32, height: 32)
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private var color: Color {
        switch viewModel.remainingSeconds {
        case 0...10:
            PassColor.signalDanger.toColor
        default:
            PassColor.signalSuccess.toColor
        }
    }
}
