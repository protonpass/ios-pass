//
// View+AdaptiveScrollDisabled.swift
// Proton Pass - Created on 09/11/2022.
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

struct AdaptiveScrollDisabledModifier: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollDisabled(disabled)
        }
    }
}

public extension View {
    /// Wrapper modifier of `scrollDisabled` modifier. Only apply if iOS 16 and above.
    func adaptiveScrollDisabled(_ disabled: Bool) -> some View {
        modifier(AdaptiveScrollDisabledModifier(disabled: disabled))
    }
}
