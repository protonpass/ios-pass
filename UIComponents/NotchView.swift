//
// NotchView.swift
// Proton Pass - Created on 15/11/2022.
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

public struct NotchView: View {
    public init() {}

    public var body: some View {
        HStack {
            Spacer()
            Color(uiColor: .init(red: 176, green: 176, blue: 176).withAlphaComponent(0.3))
                .frame(width: 36, height: 5)
                .clipShape(Capsule())
            Spacer()
        }
    }
}
