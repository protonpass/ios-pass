//
// SearchViewModifier.swift
// Proton Pass - Created on 30/07/2024.
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

import Entities
import Foundation
import SwiftUI

enum SearchEffectID: String {
    case searchbar

    var id: String {
        "\(rawValue)"
    }
}

extension View {
    func searchScreen(showSearch: Bool,
                      animationNamespace: Namespace.ID,
                      onCancel: @escaping () -> Void) -> some View {
        modifier(SearchViewModifier(showSearch: showSearch,
                                    animationNamespace: animationNamespace,
                                    onCancel: onCancel))
    }
}

struct SearchViewModifier: ViewModifier {
    private let showSearch: Bool
    private let animationNamespace: Namespace.ID
    private let onCancel: () -> Void

    init(showSearch: Bool,
         animationNamespace: Namespace.ID,
         onCancel: @escaping () -> Void) {
        self.showSearch = showSearch
        self.animationNamespace = animationNamespace
        self.onCancel = onCancel
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                overlayContent
            }
            .animation(.easeInOut(duration: 0.2), value: showSearch)
    }

    @MainActor @ViewBuilder
    var overlayContent: some View {
        if showSearch {
            SearchView(animationNamespace: animationNamespace, onCancel: onCancel)
        }
    }
}
