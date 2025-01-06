//
// RoundedRectangleWithArrow.swift
// Proton Pass - Created on 06/01/2025.
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
//

import SwiftUI

public struct RoundedRectangleWithArrow: Shape {
    private let cornerRadius: CGFloat
    private let arrowPosition: ArrowPosition
    private let arrowSize: CGSize
    private let arrowPadding: CGFloat

    public enum ArrowPosition: Sendable {
        case topLeft, topRight
    }

    public init(cornerRadius: CGFloat = 16,
                arrowPosition: ArrowPosition,
                arrowSize: CGSize = .init(width: 20, height: 10),
                arrowPadding: CGFloat = 25) {
        self.cornerRadius = cornerRadius
        self.arrowPosition = arrowPosition
        self.arrowSize = arrowSize
        self.arrowPadding = arrowPadding
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: cornerRadius, y: arrowSize.height))

        switch arrowPosition {
        case .topLeft:
            path.addLine(to: CGPoint(x: cornerRadius + arrowPadding,
                                     y: arrowSize.height))

            path.addLine(to: CGPoint(x: cornerRadius + arrowPadding + arrowSize.width / 2,
                                     y: 0))

            path.addLine(to: CGPoint(x: cornerRadius + arrowPadding + arrowSize.width,
                                     y: arrowSize.height))

        case .topRight:
            path.addLine(to: CGPoint(x: rect.width - cornerRadius - arrowPadding - arrowSize.width,
                                     y: arrowSize.height))

            path.addLine(to: CGPoint(x: rect.width - cornerRadius - arrowPadding - arrowSize.width / 2,
                                     y: 0))

            path.addLine(to: CGPoint(x: rect.width - cornerRadius - arrowPadding,
                                     y: arrowSize.height))
        }

        path.addArc(center: CGPoint(x: rect.width - cornerRadius,
                                    y: arrowSize.height + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.width,
                                 y: rect.height - cornerRadius))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius,
                                    y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(center: CGPoint(x: cornerRadius,
                                    y: rect.height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: arrowSize.height + cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius,
                                    y: arrowSize.height + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)

        return path
    }
}
