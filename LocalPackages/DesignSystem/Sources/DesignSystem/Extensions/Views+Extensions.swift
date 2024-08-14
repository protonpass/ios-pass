//
// Views+Extensions.swift
// Proton Pass - Created on 24/07/2023.
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

// MARK: - ViewBuilders

public extension View {
    func navigationStackEmbeded(_ path: Binding<NavigationPath>? = nil) -> some View {
        if let path {
            NavigationStack(path: path) {
                self
            }
        } else {
            NavigationStack {
                self
            }
        }
    }

    func scrollViewEmbeded(maxWidth: CGFloat? = nil,
                           maxHeight: CGFloat? = nil,
                           showsIndicators: Bool = true) -> some View {
        ScrollView(showsIndicators: showsIndicators) {
            self
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }

    func buttonEmbeded(role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role,
               action: action,
               label: { self.contentShape(.rect) })
            .buttonStyle(.plain)
    }
}
