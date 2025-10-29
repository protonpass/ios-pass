//
// RoundedCircleCheckbox.swift
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

import ProtonCoreUIFoundations
import SwiftUI

public struct RoundedCircleCheckbox: View {
    private let isChecked: Bool
    private let width: CGFloat

    public init(isChecked: Bool, width: CGFloat = 24) {
        self.isChecked = isChecked
        self.width = width
    }

    public var body: some View {
        ZStack {
            if isChecked {
                PassColor.interactionNormMajor1
                    .clipShape(RoundedRectangle(cornerRadius: width / 4))
                IconProvider.checkmark
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * 3 / 4)
                    .foregroundStyle(PassColor.textInvert)
            } else {
                Color.clear
                    .overlay(RoundedRectangle(cornerRadius: width / 4)
                        .stroke(PassColor.inputBorderNorm, lineWidth: width / 12))
            }
        }
        .animation(.default, value: isChecked)
        .frame(width: width, height: width)
    }
}
