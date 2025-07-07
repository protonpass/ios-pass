//
// LabelStyles.swift
// Proton Pass - Created on 26/05/2023.
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

// periphery:ignore:all
import SwiftUI

public struct RightIconLabelStyle: LabelStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

public struct BelowIconLabelStyle: LabelStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.title
            configuration.icon
        }
    }
}

public extension LabelStyle where Self == RightIconLabelStyle {
    static var rightIcon: RightIconLabelStyle {
        RightIconLabelStyle()
    }

    static var belowIcon: BelowIconLabelStyle {
        BelowIconLabelStyle()
    }
}
