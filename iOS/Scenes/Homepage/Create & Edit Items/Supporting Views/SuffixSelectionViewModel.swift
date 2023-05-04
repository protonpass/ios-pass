//
// SuffixSelectionViewModel.swift
// Proton Pass - Created on 03/05/2023.
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

import Client
import Combine
import Core

protocol SuffixSelectionViewModelDelegate: AnyObject {
    func suffixSelectionViewModelWantsToUpgrade()
    func suffixSelectionViewModelDidEncounter(error: Error)
}

final class SuffixSelectionViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var shouldUpgrade = false

    let logger: Logger
    let suffixSelection: SuffixSelection
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SuffixSelectionViewModelDelegate?

    init(suffixSelection: SuffixSelection,
         upgradeChecker: UpgradeCheckerProtocol,
         logManager: LogManager) {
        self.logger = .init(manager: logManager)
        self.suffixSelection = suffixSelection

        suffixSelection.attach(to: self, storeIn: &cancellables)
        Task { @MainActor in
            do {
                shouldUpgrade = try await upgradeChecker.isFreeUser()
            } catch {
                logger.error(error)
                delegate?.suffixSelectionViewModelDidEncounter(error: error)
            }
        }
    }

    func upgrade() {
        delegate?.suffixSelectionViewModelWantsToUpgrade()
    }
}
