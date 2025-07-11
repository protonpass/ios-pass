//
// View+OnReceiveBoolean.swift
// Proton Pass - Created on 16/11/2022.
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

// periphery:ignore:all
import Combine
import SwiftUI

public extension View {
    /// Receive a boolean publisher and perform an action if the boolean is `true`
    func onReceiveBoolean<P>(_ publisher: P, perform action: @escaping () -> Void)
        -> some View where P: Publisher, P.Output == Bool, P.Failure == Never {
        onReceive(publisher) { condition in
            if condition {
                action()
            }
        }
    }
}
