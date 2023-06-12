//
// AliasDetailViewModel.swift
// Proton Pass - Created on 15/09/2022.
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

final class AliasDetailViewModel: BaseItemDetailViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var name = ""
    @Published private(set) var note = ""
    @Published private(set) var mailboxes: [Mailbox]?
    @Published private(set) var error: Error?

    private let aliasRepository: AliasRepositoryProtocol

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         favIconRepository: FavIconRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol,
         vault: Vault?,
         logManager: LogManager,
         theme: Theme) {
        self.aliasRepository = aliasRepository
        super.init(isShownAsSheet: isShownAsSheet,
                   itemContent: itemContent,
                   favIconRepository: favIconRepository,
                   itemRepository: itemRepository,
                   upgradeChecker: upgradeChecker,
                   featureFlagsRepository: featureFlagsRepository,
                   vault: vault,
                   logManager: logManager,
                   theme: theme)
    }

    override func bindValues() {
        aliasEmail = itemContent.item.aliasEmail ?? ""
        if case .alias = itemContent.contentData {
            self.name = itemContent.name
            self.note = itemContent.note
        } else {
            fatalError("Expecting alias type")
        }
    }

    func getAlias() {
        Task { @MainActor in
            do {
                let alias =
                try await aliasRepository.getAliasDetailsTask(shareId: itemContent.shareId,
                                                              itemId: itemContent.item.itemID).value
                aliasEmail = alias.email
                mailboxes = alias.mailboxes
                logger.info("Get alias detail successfully \(itemContent.debugInformation)")
            } catch {
                logger.error(error)
                self.error = error
            }
        }
    }

    override func refresh() {
        mailboxes = nil
        error = nil
        getAlias()
        super.refresh()
    }

    func copyAliasEmail() {
        copyToClipboard(text: aliasEmail, message: "Alias copied")
    }

    func copyMailboxEmail(_ email: String) {
        copyToClipboard(text: email, message: "Mailbox copied")
    }
}
