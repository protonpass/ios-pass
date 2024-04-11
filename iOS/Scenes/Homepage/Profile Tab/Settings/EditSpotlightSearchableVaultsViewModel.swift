//
// EditSpotlightSearchableVaultsViewModel.swift
// Proton Pass - Created on 11/04/2024.
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
import Factory
import Foundation

@MainActor
final class EditSpotlightSearchableVaultsViewModel: ObservableObject {
    @Published private(set) var selection: SpotlightSearchableVaults

    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init() {
        let preferences = preferencesManager.userPreferences.unwrapped()
        selection = preferences.spotlightSearchableVaults
    }

    func update(_ newValue: SpotlightSearchableVaults) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.updateUserPreferences(\.spotlightSearchableVaults,
                                                                   value: newValue)
                selection = newValue
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
