//
// SwiftUISearchBar.swift
// Proton Pass - Created on 09/08/2022.
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

public struct SwiftUISearchBar: UIViewRepresentable {
    let placeholder: String
    let showsCancelButton: Bool
    let shouldBecomeFirstResponder: Bool
    let onSearch: (String) -> Void
    let onCancel: () -> Void

    public init(placeholder: String,
                showsCancelButton: Bool,
                shouldBecomeFirstResponder: Bool,
                onSearch: @escaping (String) -> Void,
                onCancel: @escaping () -> Void) {
        self.placeholder = placeholder
        self.showsCancelButton = showsCancelButton
        self.shouldBecomeFirstResponder = shouldBecomeFirstResponder
        self.onSearch = onSearch
        self.onCancel = onCancel
    }

    public func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.showsCancelButton = showsCancelButton
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .interactionNorm
        if shouldBecomeFirstResponder {
            searchBar.becomeFirstResponder()
        }
        return searchBar
    }

    public func updateUIView(_ uiView: UISearchBar, context: Context) {}

    public func makeCoordinator() -> Coordinator { .init(self) }

    public final class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SwiftUISearchBar

        public init(_ parent: SwiftUISearchBar) {
            self.parent = parent
        }

        public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.onSearch(searchText)
        }

        public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.onCancel()
        }
    }
}
