//
// ThemedForegroundStyleModifier.swift
// Proton Pass - Created on 27/10/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private struct ThemedForegroundStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let dark: Color
    let light: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorScheme == .dark ? dark : light)
    }
}

public extension View {
    func themedForegroundStyle(dark: Color, light: Color) -> some View {
        modifier(ThemedForegroundStyleModifier(dark: dark, light: light))
    }

    #if canImport(UIKit)
    func themedForegroundStyle(dark: Color, light: UIColor) -> some View {
        modifier(ThemedForegroundStyleModifier(dark: dark, light: light.toColor))
    }

    func themedForegroundStyle(dark: UIColor, light: Color) -> some View {
        modifier(ThemedForegroundStyleModifier(dark: dark.toColor, light: light))
    }

    func themedForegroundStyle(dark: UIColor, light: UIColor) -> some View {
        modifier(ThemedForegroundStyleModifier(dark: dark.toColor, light: light.toColor))
    }
    #endif
}
