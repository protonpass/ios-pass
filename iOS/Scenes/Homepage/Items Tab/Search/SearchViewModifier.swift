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
    func searchScreen(searchMode: Binding<SearchMode?>, animationNamespace: Namespace.ID) -> some View {
        modifier(SearchViewModifier(searchMode: searchMode, animationNamespace: animationNamespace))
    }
}

struct SearchViewModifier: ViewModifier {
    @Binding private var searchMode: SearchMode?
    private let animationNamespace: Namespace.ID

    init(searchMode: Binding<SearchMode?>,
         animationNamespace: Namespace.ID) {
        _searchMode = searchMode
        self.animationNamespace = animationNamespace
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                overlayContent
            }
            .animation(.easeInOut(duration: 0.2), value: searchMode)
    }

    @MainActor @ViewBuilder
    var overlayContent: some View {
        if let searchMode {
            SearchView(searchMode: $searchMode,
                       animationNamespace: animationNamespace,
                       viewModel: SearchViewModel(searchMode: searchMode))
        }
    }
}
