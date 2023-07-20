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
import Entities
import ProtonCore_Login
import SwiftUI

final class SuffixSelection: ObservableObject {
    @Published var selectedSuffix: Suffix?
    let suffixes: [Suffix]

    var selectedSuffixString: String { selectedSuffix?.suffix ?? "" }

    init(suffixes: [Suffix]) {
        self.suffixes = suffixes
        selectedSuffix = suffixes.first
    }
}

final class MailboxSelection: ObservableObject {
    @Published var selectedMailboxes: [Mailbox]
    let mailboxes: [Mailbox]

    var selectedMailboxesString: String {
        selectedMailboxes.map(\.email).joined(separator: "\n")
    }

    init(mailboxes: [Mailbox]) {
        self.mailboxes = mailboxes
        if let defaultMailbox = mailboxes.first {
            selectedMailboxes = [defaultMailbox]
        } else {
            selectedMailboxes = []
        }
    }
}

protocol CreateEditAliasViewModelDelegate: AnyObject {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection,
                                                        titleMode: MailboxSection.Mode)
    func createEditAliasViewModelWantsToSelectSuffix(_ suffixSelection: SuffixSelection)
}

// MARK: - Initialization

final class CreateEditAliasViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var prefix = ""
    @Published var prefixManuallyEdited = false
    @Published var note = ""

    var suffix: String { suffixSelection?.selectedSuffixString ?? "" }
    var mailboxes: String { mailboxSelection?.selectedMailboxesString ?? "" }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var state: State = .loading
    @Published private(set) var prefixError: AliasPrefixError?
    @Published private(set) var canCreateAlias = true

    var shouldUpgrade: Bool {
        if case .create = mode {
            return !canCreateAlias
        }
        return false
    }

    private let prefixCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")

    enum State {
        case loading
        case loaded
        case error(Error)

        var isLoaded: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }
    }

    private(set) var alias: Alias?
    private(set) var suffixSelection: SuffixSelection?
    private(set) var mailboxSelection: MailboxSelection?
    let aliasRepository: AliasRepositoryProtocol

    weak var createEditAliasViewModelDelegate: CreateEditAliasViewModelDelegate?

    override var isSaveable: Bool {
        switch mode {
        case .create:
            return !title.isEmpty && !prefix.isEmpty && !suffix.isEmpty && !mailboxes.isEmpty && prefixError == nil
        case .edit:
            return !title.isEmpty && !mailboxes.isEmpty
        }
    }

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManagerProtocol) throws {
        self.aliasRepository = aliasRepository
        try super.init(mode: mode,
                       itemRepository: itemRepository,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults,
                       preferences: preferences,
                       logManager: logManager)

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
                self?.validatePrefix()
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
                self.prefix = PrefixUtils.generatePrefix(fromTitle: title)
            }
            .store(in: &cancellables)

        $selectedVault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.getAliasAndAliasOptions()
            }
            .store(in: &cancellables)

        Publishers
            .CombineLatest($title, $prefix)
            .combineLatest($note)
            .dropFirst()
            .sink(receiveValue: { [unowned self] _ in
                didEditSomething = true
            })
            .store(in: &cancellables)
    }

    override func itemContentType() -> ItemContentType { .alias }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: note,
                            itemUuid: UUID().uuidString,
                            data: .alias,
                            customFields: customFieldUiModels.map(\.customField))
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let selectedSuffix = suffixSelection?.selectedSuffix,
              let selectedMailboxes = mailboxSelection?.selectedMailboxes else { return nil }
        return .init(prefix: prefix,
                     suffix: selectedSuffix,
                     mailboxIds: selectedMailboxes.map(\.ID))
    }

    override func additionalEdit() async throws {
        guard let alias, let mailboxSelection else { return }
        if Set(alias.mailboxes) == Set(mailboxSelection.selectedMailboxes) { return }
        if case let .edit(itemContent) = mode {
            let mailboxIds = mailboxSelection.selectedMailboxes.map(\.ID)
            _ = try await changeMailboxesTask(shareId: itemContent.shareId,
                                              itemId: itemContent.item.itemID,
                                              mailboxIDs: mailboxIds).value
        }
    }

    private func validatePrefix() {
        do {
            try AliasPrefixValidator.validate(prefix: prefix)
            prefixError = nil
        } catch {
            prefixError = error as? AliasPrefixError
        }
    }
}

// MARK: - Public actions

extension CreateEditAliasViewModel {
    func getAliasAndAliasOptions() {
        Task { @MainActor in
            do {
                state = .loading

                let shareId = selectedVault.shareId
                let aliasOptions = try await getAliasOptionsTask(shareId: shareId).value
                suffixSelection = .init(suffixes: aliasOptions.suffixes)
                suffixSelection?.attach(to: self, storeIn: &cancellables)
                mailboxSelection = .init(mailboxes: aliasOptions.mailboxes)
                mailboxSelection?.attach(to: self, storeIn: &cancellables)
                canCreateAlias = aliasOptions.canCreateAlias

                if case let .edit(itemContent) = mode {
                    let alias =
                        try await aliasRepository.getAliasDetailsTask(shareId: shareId,
                                                                      itemId: itemContent.item.itemID).value
                    self.aliasEmail = alias.email
                    self.alias = alias
                    self.mailboxSelection?.selectedMailboxes = alias.mailboxes
                    logger.info("Get alias successfully \(itemContent.debugInformation)")
                }

                state = .loaded
                logger.info("Get alias options successfully")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func showMailboxSelection() {
        guard let mailboxSelection else { return }
        createEditAliasViewModelDelegate?
            .createEditAliasViewModelWantsToSelectMailboxes(mailboxSelection,
                                                            titleMode: mode.isEditMode ? .edit : .create)
    }

    func showSuffixSelection() {
        guard let suffixSelection else { return }
        createEditAliasViewModelDelegate?.createEditAliasViewModelWantsToSelectSuffix(suffixSelection)
    }
}

// MARK: - Private supporting tasks

private extension CreateEditAliasViewModel {
    func getAliasOptionsTask(shareId: String) -> Task<AliasOptions, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.aliasRepository.getAliasOptions(shareId: shareId)
        }
    }

    func changeMailboxesTask(shareId: String,
                             itemId: String,
                             mailboxIDs: [Int]) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            try await self.aliasRepository.changeMailboxes(shareId: shareId,
                                                           itemId: itemId,
                                                           mailboxIDs: mailboxIDs)
        }
    }
}
