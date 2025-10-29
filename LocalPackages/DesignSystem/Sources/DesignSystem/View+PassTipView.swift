//
// View+PassTipView.swift
// Proton Pass - Created on 22/03/2024.
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
//

import SwiftUI

public extension View {
    /// Change foreground colors of icon and buttons of a `TipView`
    /// `tint` modifier only affects the icon
    /// `accentColor` though deprecated but needed for tinting buttons. Thanks SwiftUI.
    func passTipView() -> some View {
        tint(PassColor.interactionNormMajor2)
            .accentColor(PassColor.interactionNormMajor2)
    }
}
