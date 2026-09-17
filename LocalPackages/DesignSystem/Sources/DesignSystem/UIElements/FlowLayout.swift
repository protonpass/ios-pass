//
// FlowLayout.swift
// Proton Pass - Created on 19/12/2023.
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

public struct FlowLayout: Layout {
    private let spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize,
                             subviews: Subviews,
                             cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        return Self.layout(sizes: Self.sizes(of: subviews, containerWidth: containerWidth),
                           spacing: spacing,
                           containerWidth: containerWidth).size
    }

    public func placeSubviews(in bounds: CGRect,
                              proposal: ProposedViewSize,
                              subviews: Subviews,
                              cache: inout ()) {
        let sizes = Self.sizes(of: subviews, containerWidth: bounds.width)
        let offsets =
            Self.layout(sizes: sizes,
                        spacing: spacing,
                        containerWidth: bounds.width).offsets
        for (index, subview) in zip(offsets.indices, subviews) {
            subview.place(at: .init(x: offsets[index].x + bounds.minX,
                                    y: offsets[index].y + bounds.minY),
                          proposal: .init(sizes[index]))
        }
    }

    private static func sizes(of subviews: Subviews, containerWidth: CGFloat) -> [CGSize] {
        subviews.map { subview in
            let ideal = subview.sizeThatFits(.unspecified)
            guard ideal.width > containerWidth else { return ideal }
            return subview.sizeThatFits(.init(width: containerWidth, height: nil))
        }
    }

    private static func layout(sizes: [CGSize],
                               spacing: CGFloat = 8,
                               containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var result: [CGPoint] = []
        var currentPosition: CGPoint = .zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for size in sizes {
            if currentPosition.x + size.width > containerWidth {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            result.append(currentPosition)
            currentPosition.x += size.width
            maxX = max(maxX, currentPosition.x)
            currentPosition.x += spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (result,
                .init(width: maxX, height: currentPosition.y + lineHeight))
    }
}
