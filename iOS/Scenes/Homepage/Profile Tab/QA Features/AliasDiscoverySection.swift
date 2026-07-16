//
// AliasDiscoverySection.swift
// Proton Pass - Created on 21/01/2025.
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

import DesignSystem
import DIComposition
import Entities
import FactoryKit
import Observation
import SwiftUI

struct AliasDiscoverySection: View {
    @State private var viewModel = AliasDiscoverySectionViewModel()

    var body: some View {
        Section(content: {
            StaticToggle(.verbatim("Showed advanced options tip"),
                         isOn: viewModel.showedAdvancedOptions,
                         action: { viewModel.toggle(.advancedOptions) })

            StaticToggle(.verbatim("Showed custom domain tip"),
                         isOn: viewModel.showedCustomDomains,
                         action: { viewModel.toggle(.customDomains) })

            StaticToggle(.verbatim("Showed mailbox tip"),
                         isOn: viewModel.showedMailboxes,
                         action: { viewModel.toggle(.mailboxes) })

            StaticToggle(.verbatim("Showed contact tip"),
                         isOn: viewModel.showedContacts,
                         action: { viewModel.toggle(.contacts) })

            StaticToggle(.verbatim("Asked for copy alias address after creating"),
                         isOn: viewModel.askedForCopyAliasAfterCreating,
                         action: { viewModel.toggle(.copyAliasAfterCreating) })

            StaticToggle(.verbatim("Asked for copy contact reverse-alias after creating"),
                         isOn: viewModel.askedForCopyContactAfterCreating,
                         action: { viewModel.toggle(.copyContactAfterCreating) })
        }, header: {
            Text(verbatim: "Alias discovery")
        })
    }
}

@MainActor
@Observable
private final class AliasDiscoverySectionViewModel {
    private(set) var showedAdvancedOptions = false
    private(set) var showedCustomDomains = false
    private(set) var showedMailboxes = false
    private(set) var showedContacts = false
    private(set) var askedForCopyAliasAfterCreating = false
    private(set) var askedForCopyContactAfterCreating = false

    @ObservationIgnored
    private let preferencesManager = resolve(\ToolingContainer.preferencesManager)

    private var discovery: AliasDiscovery {
        preferencesManager.sharedPreferences.unwrapped().aliasDiscovery
    }

    init() {
        refresh()
    }

    private func refresh() {
        showedAdvancedOptions = discovery.contains(.advancedOptions)
        showedCustomDomains = discovery.contains(.customDomains)
        showedMailboxes = discovery.contains(.mailboxes)
        showedContacts = discovery.contains(.contacts)
        askedForCopyAliasAfterCreating = discovery.contains(.copyAliasAfterCreating)
        askedForCopyContactAfterCreating = discovery.contains(.copyContactAfterCreating)
    }

    func toggle(_ option: AliasDiscovery) {
        Task { [weak self] in
            guard let self else { return }
            do {
                var discovery = discovery
                discovery.flip(option)
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: discovery)
                refresh()
            } catch {
                print(error)
            }
        }
    }
}
