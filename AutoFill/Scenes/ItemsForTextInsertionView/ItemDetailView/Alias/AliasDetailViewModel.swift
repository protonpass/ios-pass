//
// AliasDetailViewModel.swift
// Proton Pass - Created on 09/10/2024.
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
import FactoryKit
import Foundation

@MainActor
final class AliasDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var mailboxes: [AliasLinkedMailbox]?
    @Published private(set) var mailboxesError: (any Error)?

    private(set) var email = ""
    private(set) var enabled = false

    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository

    override func bindValues() {
        email = item.content.item.aliasEmail ?? ""
        enabled = item.content.item.isAliasEnabled
    }
}

extension AliasDetailViewModel {
    func fetchMailboxes() async {
        mailboxesError = nil
        do {
            let details = try await aliasRepository.getAliasDetails(userId: item.userId,
                                                                    shareId: item.content.shareId,
                                                                    itemId: item.content.itemId)
            mailboxes = details.mailboxes
        } catch {
            mailboxesError = error
        }
    }
}
