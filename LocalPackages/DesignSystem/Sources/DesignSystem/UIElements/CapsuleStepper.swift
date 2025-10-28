//
// CapsuleStepper.swift
// Proton Pass - Created on 06/06/2024.
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

public struct CapsuleStepper<V: Strideable>: View where V.Stride: Numeric {
    @Binding var value: V
    let step: V.Stride
    let minValue: V?
    let maxValue: V?
    let textColor: Color
    let backgroundColor: Color
    let height: CGFloat

    public init(value: Binding<V>,
                step: V.Stride,
                minValue: V? = nil,
                maxValue: V? = nil,
                textColor: Color,
                backgroundColor: Color,
                height: CGFloat = 44) {
        _value = value
        self.step = step
        self.minValue = minValue
        self.maxValue = maxValue
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.height = height
    }

    public var body: some View {
        HStack(spacing: 24) {
            Button { value = value.advanced(by: -step) } label: { Text(verbatim: "-") }
                .disabled(reachedMinValue)
            Text(verbatim: "\(value)")
                .fontWeight(.bold)
                .monospacedDigit()
            Button { value = value.advanced(by: step) } label: { Text(verbatim: "+") }
                .disabled(reachedMaxValue)
        }
        .font(.title3)
        .foregroundStyle(PassColor.textNorm)
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(height: height)
        .foregroundStyle(PassColor.textNorm)
        .background {
            Capsule()
                .fill(backgroundColor)
        }
    }

    private var reachedMinValue: Bool {
        if let minValue { value <= minValue } else { false }
    }

    private var reachedMaxValue: Bool {
        if let maxValue { value > maxValue } else { false }
    }
}
