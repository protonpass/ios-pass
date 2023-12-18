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
import Entities
import Factory
import SwiftUI

@MainActor
final class MailboxSelectionViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var shouldUpgrade = false

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let mailboxSelection: MailboxSelection
    let mode: Mode
    let titleMode: MailboxSection.Mode

    private var cancellables = Set<AnyCancellable>()

    enum Mode {
        case createEditAlias
        case createAliasLite

        var tintColor: Color {
            switch self {
            case .createEditAlias:
                Color(uiColor: ItemContentType.alias.normMajor2Color)
            case .createAliasLite:
                Color(uiColor: ItemContentType.login.normMajor2Color)
            }
        }
    }

    init(mailboxSelection: MailboxSelection,
         mode: MailboxSelectionViewModel.Mode,
         titleMode: MailboxSection.Mode) {
        self.mailboxSelection = mailboxSelection
        self.mode = mode
        self.titleMode = titleMode

        mailboxSelection.attach(to: self, storeIn: &cancellables)
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}
