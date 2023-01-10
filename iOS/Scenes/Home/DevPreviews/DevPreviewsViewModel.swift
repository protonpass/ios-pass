//
// DevPreviewsViewModel.swift
// Proton Pass - Created on 14/12/2022.
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

import Client
import Core
import UIComponents

protocol DevPreviewsViewModelDelegate: AnyObject {
    func devPreviewsViewModelWantsToShowLoadingHud()
    func devPreviewsViewModelWantsToHideLoadingHud()
    func devPreviewsViewModelWantsToOnboard()
    func devPreviewsViewModelWantsToEnableAutoFill()
    func devPreviewsViewModelDidTrashAllItems(count: Int)
    func devPreviewsViewModelDidFail(_ error: Error)
}

final class DevPreviewsViewModel: ObservableObject {
    private let itemRepository: ItemRepositoryProtocol
    private let preferences: Preferences

    @Published var onboarded: Bool {
        didSet {
            preferences.onboarded = onboarded
        }
    }

    init(itemRepository: ItemRepositoryProtocol,
         preferences: Preferences) {
        self.itemRepository = itemRepository
        self.preferences = preferences
        self.onboarded = preferences.onboarded
    }

    weak var delegate: DevPreviewsViewModelDelegate?

    func onboard() {
        delegate?.devPreviewsViewModelWantsToOnboard()
    }

    func enableAutoFill() {
        delegate?.devPreviewsViewModelWantsToEnableAutoFill()
    }

    @MainActor
    func trashAllItems() async {
        defer { delegate?.devPreviewsViewModelWantsToHideLoadingHud() }
        do {
            delegate?.devPreviewsViewModelWantsToShowLoadingHud()
            let items = try await itemRepository.getItems(state: .active)
            try await itemRepository.trashItems(items)
            delegate?.devPreviewsViewModelDidTrashAllItems(count: items.count)
        } catch {
            delegate?.devPreviewsViewModelDidFail(error)
        }
    }
}
