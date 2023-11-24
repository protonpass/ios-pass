//
// View+Extensions.swift
// Proton Pass - Created on 30/08/2023.
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

import Combine
import Core
import DocScanner
import SwiftUI

// MARK: - Doc & credit card scanner View extension

extension View {
    func scannerSheet(isPresented: Binding<Bool>,
                      interpreter: ScanInterpreting,
                      resultStream: PassthroughSubject<ScanResult?, Error>) -> some View {
        sheet(isPresented: isPresented) {
            DocScanner(with: interpreter, resultStream: resultStream)
        }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        modifier(ThemeModifier(theme: theme))
            .animation(.default, value: theme)
    }
}

private struct ThemeModifier: ViewModifier {
    let theme: Theme

    func body(content: Content) -> some View {
        if let colorScheme = theme.colorScheme {
            content.environment(\.colorScheme, colorScheme)
        } else {
            content
        }
    }
}
