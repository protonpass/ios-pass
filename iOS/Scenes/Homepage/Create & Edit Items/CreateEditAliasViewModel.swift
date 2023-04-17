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
import ProtonCore_Login
import SwiftUI

final class SuffixSelection: ObservableObject {
    @Published var selectedSuffix: Suffix?
    let suffixes: [Suffix]

    var selectedSuffixString: String { selectedSuffix?.suffix ?? "" }

    init(suffixes: [Suffix]) {
        self.suffixes = suffixes
        self.selectedSuffix = suffixes.first
    }
}

final class MailboxSelection: ObservableObject {
    @Published var selectedMailboxes: [Mailbox]
    let mailboxes: [Mailbox]

    var selectedMailboxesString: String {
        selectedMailboxes.map { $0.email }.joined(separator: "\n")
    }

    init(mailboxes: [Mailbox]) {
        self.mailboxes = mailboxes
        if let defaultMailbox = mailboxes.first {
            self.selectedMailboxes = [defaultMailbox]
        } else {
            self.selectedMailboxes = []
        }
    }
}

protocol CreateEditAliasViewModelDelegate: AnyObject {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection,
                                                        titleMode: MailboxSection.Mode)
    func createEditAliasViewModelCanNotCreateMoreAliases()
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
    @Published private(set) var canCreateAlias = false

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
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManager) throws {
        self.aliasRepository = aliasRepository
        try super.init(mode: mode,
                       itemRepository: itemRepository,
                       vaults: vaults,
                       preferences: preferences,
                       logManager: logManager)

        if case let .edit(itemContent) = mode {
            self.title = itemContent.name
            self.note = itemContent.note
        }
        getAliasAndAliasOptions()

        _title
            .projectedValue
            .dropFirst(mode.isEditMode ? 1 : 3)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                if !prefixManuallyEdited {
                    prefix = PrefixUtils.generatePrefix(fromTitle: title)
                }
            }
            .store(in: &cancellables)

        _prefix
            .projectedValue
            .dropFirst(mode.isEditMode ? 1 : 3)
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.validatePrefix()
            }
            .store(in: &cancellables)

        $vault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.getAliasAndAliasOptions()
            }
            .store(in: &cancellables)

        Publishers
            .CombineLatest($title, $prefix)
            .combineLatest($note)
            .dropFirst(mode.isEditMode ? 1 : 3)
            .sink(receiveValue: { [unowned self] _ in
                self.didEditSomething = true
            })
            .store(in: &cancellables)
    }

    override func itemContentType() -> ItemContentType { .alias }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: title, note: note, itemUuid: UUID().uuidString, data: .alias)
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let selectedSuffix = suffixSelection?.selectedSuffix,
              let selectedMailboxes = mailboxSelection?.selectedMailboxes else { return nil }
        return .init(prefix: prefix,
                     suffix: selectedSuffix,
                     mailboxIds: selectedMailboxes.map { $0.ID })
    }

    override func additionalEdit() async throws {
        guard let alias, let mailboxSelection = mailboxSelection else { return }
        if Set(alias.mailboxes) == Set(mailboxSelection.selectedMailboxes) { return }
        if case let .edit(itemContent) = mode {
            let mailboxIds = mailboxSelection.selectedMailboxes.map { $0.ID }
            _ = try await changeMailboxesTask(shareId: itemContent.shareId,
                                              itemId: itemContent.item.itemID,
                                              mailboxIDs: mailboxIds).value
        }
    }

    private func validatePrefix() {
        do {
            try AliasPrefixValidator.validate(prefix: prefix)
            self.prefixError = nil
        } catch {
            self.prefixError = error as? AliasPrefixError
        }
    }
}

// MARK: - Public actions
extension CreateEditAliasViewModel {
    func getAliasAndAliasOptions() {
        Task { @MainActor in
            do {
                state = .loading

                let shareId = vault.shareId
                let aliasOptions = try await getAliasOptionsTask(shareId: shareId).value
                suffixSelection = .init(suffixes: aliasOptions.suffixes)
                suffixSelection?.attach(to: self, storeIn: &cancellables)
                mailboxSelection = .init(mailboxes: aliasOptions.mailboxes)
                mailboxSelection?.attach(to: self, storeIn: &cancellables)

                if case .edit(let itemContent) = mode {
                    let alias =
                    try await aliasRepository.getAliasDetailsTask(shareId: shareId,
                                                                  itemId: itemContent.item.itemID).value
                    self.aliasEmail = alias.email
                    self.alias = alias
                    self.mailboxSelection?.selectedMailboxes = alias.mailboxes
                    logger.info("Get alias successfully \(itemContent.debugInformation)")
                }

                if !aliasOptions.canCreateAlias {
                    createEditAliasViewModelDelegate?.createEditAliasViewModelCanNotCreateMoreAliases()
                } else {
                    state = .loaded
                }
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
