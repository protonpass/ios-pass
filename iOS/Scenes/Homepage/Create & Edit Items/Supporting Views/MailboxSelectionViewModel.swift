//
// MailboxSelectionViewModel.swift
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
import SwiftUI

protocol MailboxSelectionViewModelDelegate: AnyObject {
    func mailboxSelectionViewModelWantsToUpgrade()
    func mailboxSelectionViewModelDidEncounter(error: Error)
}

final class MailboxSelectionViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var shouldUpgrade = false

    let mailboxSelection: MailboxSelection
    let logger: Logger
    let mode: Mode
    let titleMode: MailboxSection.Mode

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: MailboxSelectionViewModelDelegate?

    enum Mode {
        case createEditAlias
        case createAliasLite

        var tintColor: Color {
            switch self {
            case .createEditAlias:
                return Color(uiColor: ItemContentType.alias.normMajor2Color)
            case .createAliasLite:
                return Color(uiColor: ItemContentType.login.normMajor2Color)
            }
        }
    }

    init(mailboxSelection: MailboxSelection,
         upgradeChecker: UpgradeCheckerProtocol,
         logManager: LogManager,
         mode: MailboxSelectionViewModel.Mode,
         titleMode: MailboxSection.Mode) {
        self.mailboxSelection = mailboxSelection
        self.logger = .init(manager: logManager)
        self.mode = mode
        self.titleMode = titleMode

        mailboxSelection.attach(to: self, storeIn: &cancellables)
        Task { @MainActor in
            do {
                shouldUpgrade = try await upgradeChecker.isFreeUser()
            } catch {
                logger.error(error)
                delegate?.mailboxSelectionViewModelDidEncounter(error: error)
            }
        }
    }

    func upgrade() {
        delegate?.mailboxSelectionViewModelWantsToUpgrade()
    }
}
