//
// Button+ConvenientInitializers.swift
// Proton Pass - Created on 24/11/2022.
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

public extension Button {
    init(role: ButtonRole?,
         action: @escaping @Sendable () async -> Void,
         @ViewBuilder label: () -> Label) {
        self = Button(role: role,
                      action: { Task { await action() } },
                      label: label)
    }

    init(role: ButtonRole?, @ViewBuilder label: () -> Label) {
        self = Button(role: role, action: {}, label: label)
    }
}
