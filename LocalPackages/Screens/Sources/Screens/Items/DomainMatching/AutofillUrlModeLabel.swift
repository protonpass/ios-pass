//
// AutofillUrlModeLabel.swift
// Proton Pass - Created on 23/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import DesignSystem
import Entities
import SwiftUI

public struct AutofillUrlModeLabel: View {
    let mode: AutofillUrlMode

    public init(mode: AutofillUrlMode) {
        self.mode = mode
    }

    public var body: some View {
        Text(mode.title)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ItemContentType.login.normMajor2Color)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(PassColor.inputBackgroundNorm)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
