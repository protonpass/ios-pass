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

@MainActor
public struct FlowLayout<T: Hashable, V: View>: View {
    private let items: [T]
    private let viewMapping: (T) -> V
    @State private var totalHeight: CGFloat

    public init(items: [T], viewMapping: @escaping (T) -> V) {
        self.items = items
        self.viewMapping = viewMapping
        _totalHeight = State(initialValue: .zero)
    }

    public var body: some View {
        let stack = VStack {
            GeometryReader { geometry in
                content(in: geometry)
            }
        }
        return Group {
            stack.frame(height: totalHeight)
        }
    }
}

extension FlowLayout {
    private func content(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                viewMapping(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .readSize { size in
            totalHeight = size.height
        }
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(GeometryReader { geometryProxy in
            Color.clear
                .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
        })
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// @available(iOS 16.0, *)
// struct FlowLayout: Layout {
//    var spacing: CGFloat
//
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let arranger = Arranger(containerSize: proposal.replacingUnspecifiedDimensions(),
//                                subviews: subviews,
//                                spacing: spacing)
//        let result = arranger.arrange()
//        return result.size
//    }
//
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let arranger = Arranger(containerSize: proposal.replacingUnspecifiedDimensions(),
//                                subviews: subviews,
//                                spacing: spacing)
//        let result = arranger.arrange()
//
//        for (index, cell) in result.cells.enumerated() {
//            let point = CGPoint(x: bounds.minX + cell.frame.origin.x,
//                                y: bounds.minY + cell.frame.origin.y)
//
//            subviews[index].place(at: point,
//                                  anchor: .topLeading,
//                                  proposal: ProposedViewSize(cell.frame.size))
//        }
//    }
// }
//
// @available(iOS 16.0, *)
// struct Arranger {
//    var containerSize: CGSize
//    var subviews: LayoutSubviews
//    var spacing: CGFloat
//
//    func arrange() -> TestResult {
//        var cells: [Cell] = []
//
//        var maxY: CGFloat = 0
//        var previousFrame: CGRect = .zero
//
//        for (index, subview) in subviews.enumerated() {
//            let size = subview.sizeThatFits(ProposedViewSize(containerSize))
//
//            let origin: CGPoint = if index == 0 {
//                .zero
//            } else if previousFrame.maxX + spacing + size.width > containerSize.width {
//                CGPoint(x: 0, y: maxY + spacing)
//            } else {
//                CGPoint(x: previousFrame.maxX + spacing, y: previousFrame.minY)
//            }
//
//            let frame = CGRect(origin: origin, size: size)
//            let cell = Cell(frame: frame)
//            cells.append(cell)
//
//            previousFrame = frame
//            maxY = max(maxY, frame.maxY)
//        }
//
//        let maxWidth = cells.reduce(0) { max($0, $1.frame.maxX) }
//        return TestResult(size: CGSize(width: maxWidth, height: previousFrame.maxY),
//                          cells: cells)
//    }
// }
//
// struct TestResult {
//    var size: CGSize
//    var cells: [Cell]
// }
//
// struct Cell {
//    var frame: CGRect
// }
