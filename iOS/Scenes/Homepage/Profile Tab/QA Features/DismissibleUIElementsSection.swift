//
// DismissibleUIElementsSection.swift
// Proton Pass - Created on 13/10/2025.
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

// var dismissedUIElements = preferencesManager.appPreferences.unwrapped().dismissedElements
// dismissedUIElements.dismissedElements[.itemCreationInSharedVaultAlert] = true
// try await preferencesManager.updateAppPreferences(\.dismissedElements,
//                                                  value: dismissedUIElements)

import Combine
import Core
import DesignSystem
import Entities
import FactoryKit
import SwiftUI

private let kNavTitle = "Dismissable UI elements"

struct DismissibleUIElementsSection: View {
    var body: some View {
        NavigationLink(destination: { DismissibleUIElementsView() },
                       label: { Text(verbatim: kNavTitle) })
    }
}

private struct DismissibleUIElementsView: View {
    @StateObject private var viewModel = DismissibleUIElementViewModel()

    var body: some View {
        List {
            ForEach(DismissibleUIElement.allCases, id: \.self) { dismissibleUIElement in
                switch dismissibleUIElement {
                case .itemCreationInSharedVaultAlert:
                    Toggle(isOn: $viewModel.sharedVaultItemCreationDismissed,
                           label: { Text(verbatim: "Item creation in shared vault alert dismissed") })
                }
            }
        }
        .padding(DesignConstant.sectionPadding)
        .navigationTitle(Text(verbatim: kNavTitle))
    }
}

@MainActor
private final class DismissibleUIElementViewModel: ObservableObject {
    @Published var sharedVaultItemCreationDismissed = false {
        didSet {
            save()
        }
    }

    @LazyInjected(\SharedToolingContainer.preferencesManager) var preferencesManager

    init() {
        updateValues()
    }

    private func updateValues() {
        let dismissedUIElements = preferencesManager.appPreferences.unwrapped().dismissedUIElements

        sharedVaultItemCreationDismissed = dismissedUIElements.contains(.itemCreationInSharedVaultAlert)
    }

    func save() {
        var dismissedUIElements = preferencesManager.appPreferences.unwrapped().dismissedUIElements
        if sharedVaultItemCreationDismissed {
            dismissedUIElements.insert(.itemCreationInSharedVaultAlert)
        } else {
            dismissedUIElements.remove(.itemCreationInSharedVaultAlert)
        }
        Task {
            try? await preferencesManager.updateAppPreferences(\.dismissedUIElements,
                                                               value: dismissedUIElements)
        }
    }
}
