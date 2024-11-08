//
// AliasContactsSkeletonView.swift
// Proton Pass - Created on 05/11/2024.
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

import DesignSystem
import SwiftUI

struct AliasContactsSkeletonView: View {
    var body: some View {
        HStack {
            SkeletonBlock()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()

            SkeletonBlock()
                .frame(height: 24)
                .clipShape(Capsule())

            Spacer()

            SkeletonBlock()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .shimmering()
    }
}
