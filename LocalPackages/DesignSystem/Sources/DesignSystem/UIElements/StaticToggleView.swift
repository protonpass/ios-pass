//
// StaticToggleView.swift
// Proton Pass - Created on 09/04/2024.
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

public struct StaticToggleView: View {
    private var isOn: Bool

    public init(isOn: Bool) {
        self.isOn = isOn
    }

    public var body: some View {
        HStack {
            Rectangle()
                .foregroundStyle(isOn ? PassColor.interactionNorm.toColor : UIColor.secondarySystemFill.toColor)
                .frame(width: 50, height: 30)
                .cornerRadius(15)
                .overlay(Circle()
                    .foregroundColor(.white)
                    .padding(3)
                    .offset(x: isOn ? 10 : -10))
                .animation(.easeInOut, value: isOn)
        }
    }
}
