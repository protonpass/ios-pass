//
// ResetAlertDisplaySection.swift
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

struct ResetAlertDisplaySection: View {
    var body: some View {
        NavigationLink(destination: { ResetAlertDisplayView() },
                       label: { Text(verbatim: "Password Policy") })
    }
}

private struct ResetAlertDisplayView: View {
    @StateObject private var viewModel = ResetAlertDisplayViewModel()

    @AppStorage(Constants.QA.forcePasswordPolicy)
    private var forcePasswordPolicy = false

    var body: some View {
        List {
            Section(header: Text(verbatim: "Alert dismissed state settings").font(.headline.bold())) {
                ForEach(DismissibleUIElementId.allCases, id: \.self) { dismissibleUIElementId in
                    switch dismissibleUIElementId {
                    case .itemCreationInSharedVaultAlert:
                        Toggle(isOn: $viewModel.sharedVaultItemCreationDismissed,
                               label: { Text(verbatim: "Item creation in shared vault alert dismissed") })
                    }
                }
            }
        }
        .padding(DesignConstant.sectionPadding)
        .navigationTitle(Text(verbatim: "Password Policy Settings"))
    }
}

@MainActor
private final class ResetAlertDisplayViewModel: ObservableObject {
    @Published var sharedVaultItemCreationDismissed = false {
        didSet {
            updateAlert()
        }
    }

    @LazyInjected(\SharedToolingContainer.preferencesManager) var preferencesManager

    init() {
        updateValues()
    }

    private func updateValues() {
        let dismissedUIElements = preferencesManager.appPreferences.unwrapped().dismissedElements

        sharedVaultItemCreationDismissed = dismissedUIElements
            .dismissedElements[.itemCreationInSharedVaultAlert] ?? false
    }

    func updateAlert() {
        var dismissedUIElements = preferencesManager.appPreferences.unwrapped().dismissedElements
        dismissedUIElements.dismissedElements[.itemCreationInSharedVaultAlert] = sharedVaultItemCreationDismissed
        Task {
            try? await preferencesManager.updateAppPreferences(\.dismissedElements,
                                                               value: dismissedUIElements)
        }
    }
}
