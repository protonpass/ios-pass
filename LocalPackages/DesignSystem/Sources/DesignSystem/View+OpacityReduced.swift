//
// View+OpacityReduced.swift
// Proton Pass - Created on 17/11/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public extension View {
    /// Reduce view's opacity when condition is `true`
    /// - Parameters:
    ///   - condition: Condition to reduce the opacity
    ///   - reducedOpacity: The opacity when `condition` is true. Default is `0.5`
    ///   - disabled: Whether to disable the view when opacity is reduced. Default is `true`
    func opacityReduced(_ condition: Bool,
                        reducedOpacity: Double = 0.5,
                        disabled: Bool = true) -> some View {
        opacity(condition ? reducedOpacity : 1)
            .disabled(disabled && condition)
            .animation(.default, value: condition)
    }
}
