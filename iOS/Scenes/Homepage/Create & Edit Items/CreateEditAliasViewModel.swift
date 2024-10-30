//
// CreateEditAliasViewModel.swift
// Proton Pass - Created on 05/08/2022.
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
import Combine
import Core
import DesignSystem
import Entities
import Factory
import ProtonCoreLogin
import SwiftUI

@MainActor
final class CreateEditAliasViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var prefix = ""
    @Published var prefixManuallyEdited = false
    @Published var note = ""
    @Published var simpleLoginNote = ""
    @Published var senderName = ""

    var suffix: String { suffixSelection.selectedSuffixString }
    var mailboxes: String { mailboxSelection.selectedMailboxesString }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var state: State = .loading
    @Published private(set) var prefixError: AliasPrefixError?
    @Published private(set) var canCreateAlias = true
    @Published var mailboxSelection: AliasLinkedMailboxSelection = .defaultEmpty
    @Published var suffixSelection: SuffixSelection = .defaultEmpty

    override var shouldUpgrade: Bool {
        if case .create = mode {
            return !canCreateAlias
        }
        return false
    }

    enum State {
        case loading
        case loaded
        case error(any Error)

        var isLoading: Bool {
            switch self {
            case .loading:
                true
            default:
                false
            }
        }
    }

    private(set) var alias: Alias?
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedUseCasesContainer.validateAliasPrefix) private var validateAliasPrefix
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) var getFeatureFlagStatus

    var isAdvancedAliasManagementActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passAdvancedAliasManagementV1)
    }

    override var isSaveable: Bool {
        switch mode {
        case .clone, .create:
            !title.isEmpty && !prefix.isEmpty && !suffix.isEmpty && !mailboxes.isEmpty && prefixError == nil
        case .edit:
            !title.isEmpty && !mailboxes.isEmpty
        }
    }

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)

        if case let .edit(itemContent) = mode {
            title = itemContent.name
            note = itemContent.note
        }
        getAliasAndAliasOptions()

        $prefix
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                validatePrefix()
            }
            .store(in: &cancellables)

        $title
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                guard let self, !self.prefixManuallyEdited else {
                    return
                }
                prefix = PrefixUtils.generatePrefix(fromTitle: title)
            }
            .store(in: &cancellables)

        $selectedVault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                getAliasAndAliasOptions()
            }
            .store(in: &cancellables)
    }

    override func itemContentType() -> ItemContentType { .alias }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: note,
                            itemUuid: UUID().uuidString,
                            data: .alias,
                            customFields: customFieldUiModels.map(\.customField))
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let selectedSuffix = suffixSelection.selectedSuffix else { return nil }
        return .init(prefix: prefix,
                     suffix: selectedSuffix,
                     mailboxIds: mailboxSelection.selectedMailboxes.map(\.ID))
    }

    override func additionalEdit() async throws -> Bool {
        guard let alias, case let .edit(itemContent) = mode else { return false }

        var edited = false
        if Set(alias.mailboxes) != Set(mailboxSelection.selectedMailboxes) {
            let mailboxIds = mailboxSelection.selectedMailboxes.map(\.ID)
            try await changeMailboxes(shareId: itemContent.shareId,
                                      itemId: itemContent.item.itemID,
                                      mailboxIDs: mailboxIds)
            edited = true
        }

        let userId = try await userManager.getActiveUserId()

        if simpleLoginNote != alias.note {
            try await aliasRepository.updateSlAliasNote(userId: userId,
                                                        shareId: itemContent.shareId,
                                                        itemId: itemContent.itemId,
                                                        note: simpleLoginNote)
            edited = true
        }

        if senderName != alias.name {
            try await aliasRepository.updateSlAliasName(userId: userId,
                                                        shareId: itemContent.shareId,
                                                        itemId: itemContent.itemId,
                                                        name: senderName.nilIfEmpty)
            edited = true
        }

        return edited
    }

    private func validatePrefix() {
        do {
            try validateAliasPrefix(prefix: prefix)
            prefixError = nil
        } catch {
            prefixError = error as? AliasPrefixError
        }
    }
}

// MARK: - Public actions

extension CreateEditAliasViewModel {
    func getAliasAndAliasOptions() {
        Task { [weak self] in
            guard let self else { return }
            do {
                state = .loading

                let shareId = selectedVault.shareId
                let aliasOptions = try await getAliasOptions(shareId: shareId)

                suffixSelection = .init(suffixes: aliasOptions.suffixes)
                mailboxSelection = .init(allUserMailboxes: aliasOptions.mailboxes)
                canCreateAlias = aliasOptions.canCreateAlias

                if case let .edit(itemContent) = mode {
                    let alias =
                        try await aliasRepository.getAliasDetails(shareId: shareId,
                                                                  itemId: itemContent.item.itemID)
                    aliasEmail = alias.email
                    simpleLoginNote = alias.note ?? ""
                    self.alias = alias
                    mailboxSelection.selectedMailboxes = alias.mailboxes
                    senderName = alias.name ?? ""
                    logger.info("Get alias successfully \(itemContent.debugDescription)")
                }

                state = .loaded
                logger.info("Get alias options successfully")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}

// MARK: - Private supporting tasks

private extension CreateEditAliasViewModel {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        try await aliasRepository.getAliasOptions(shareId: shareId)
    }

    func changeMailboxes(shareId: String,
                         itemId: String,
                         mailboxIDs: [Int]) async throws {
        try await aliasRepository.changeMailboxes(shareId: shareId,
                                                  itemId: itemId,
                                                  mailboxIDs: mailboxIDs)
    }
}
