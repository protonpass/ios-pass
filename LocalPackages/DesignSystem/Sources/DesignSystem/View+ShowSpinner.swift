//
// View+ShowSpinner.swift
// Proton Pass - Created on 06/07/2023.
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

import SwiftUI

public extension View {
    /// Dim the background and show a spinner in the middle of the view
    /// - Parameters:
    ///   - isShowing: Whether to show the spinner or not
    ///   - disableWhenShowing: Whether to disable the view while showing the spinner or not
    ///   - size: The size of the spinner
    func showSpinner(_ isShowing: Bool,
                     disableWhenShowing: Bool = true,
                     size: ControlSize = .large) -> some View {
        overlay {
            if isShowing {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .controlSize(size)
            }
        }
        .disabled(disableWhenShowing && isShowing)
        .animation(.default, value: isShowing)
    }
}
