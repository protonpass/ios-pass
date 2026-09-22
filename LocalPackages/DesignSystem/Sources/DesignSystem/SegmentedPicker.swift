//
// SegmentedPicker.swift
// Proton Pass - Created on 15/12/2023.
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
//

import SwiftUI

public struct SegmentedPickerOption<Value: Hashable>: Hashable {
    public let value: Value
    public let title: String

    public init(value: Value, title: String) {
        self.value = value
        self.title = title
    }
}

public struct SegmentedPicker<Selection: Hashable>: View {
    @Binding private var selection: Selection
    private let options: [SegmentedPickerOption<Selection>]
    private let highlightTextColor: Color
    private let mainColor: Color
    private let backgroundColor: Color

    public init(selection: Binding<Selection>,
                options: [SegmentedPickerOption<Selection>],
                highlightTextColor: Color = PassColor.textNorm,
                mainColor: Color = PassColor.interactionNormMajor1,
                backgroundColor: Color = PassColor.interactionNormMinor1) {
        _selection = selection
        self.options = options
        self.mainColor = mainColor
        self.backgroundColor = backgroundColor
        self.highlightTextColor = highlightTextColor
    }

    public var body: some View {
        let selectedIndex = options.firstIndex { $0.value == selection } ?? 0
        ZStack {
            GeometryReader { proxy in
                let thumbWidth = proxy.size.width / CGFloat(options.count)
                mainColor
                    .clipShape(Capsule())
                    .frame(width: thumbWidth)
                    .offset(x: thumbWidth * CGFloat(selectedIndex))
                    .animation(.default, value: selectedIndex)
            }

            HStack {
                ForEach(options, id: \.value) { option in
                    Button(action: {
                        selection = option.value
                    }, label: {
                        Text(option.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(option.value == selection ?
                                highlightTextColor : PassColor.textNorm)
                            .frame(maxWidth: .infinity, alignment: .center)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(5)
        .background(backgroundColor)
        .clipShape(Capsule())
        .frame(height: DesignConstant.defaultPickerHeight)
    }
}

public extension SegmentedPicker where Selection == Int {
    /// Index-based convenience: the position in `options` is the selection.
    init(selectedIndex: Binding<Int>,
         options: [String],
         highlightTextColor: Color = PassColor.textNorm,
         mainColor: Color = PassColor.interactionNormMajor1,
         backgroundColor: Color = PassColor.interactionNormMinor1) {
        self.init(selection: selectedIndex,
                  options: options.enumerated().map { .init(value: $0.offset, title: $0.element) },
                  highlightTextColor: highlightTextColor,
                  mainColor: mainColor,
                  backgroundColor: backgroundColor)
    }
}
