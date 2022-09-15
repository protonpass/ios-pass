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
import Core
import ProtonCore_Login
import SwiftUI

final class SuffixSelection: ObservableObject {
    let suffixes: [Suffix]
    @Published var selectedSuffix: Suffix?

    init(suffixes: [Suffix]) {
        self.suffixes = suffixes
    }

    func selectDefaultSuffix() {
        selectedSuffix = suffixes.first
    }
}

final class MailboxSelection: ObservableObject {
    let mailboxes: [Mailbox]
    @Published var selectedMailboxes: [Mailbox] = []

    init(mailboxes: [Mailbox]) {
        self.mailboxes = mailboxes
    }

    func selectOrDeselect(mailbox: Mailbox) {
        if selectedMailboxes.contains(mailbox) {
            if selectedMailboxes.count == 1 { return }
            selectedMailboxes.removeAll(where: { $0 == mailbox })
        } else {
            selectedMailboxes.append(mailbox)
        }
    }

    func selectDefaultMailboxes(_ mailboxes: [String]) {
        selectedMailboxes = self.mailboxes.filter { mailbox in
            mailboxes.contains(where: { $0 == mailbox.email })
        }

        if selectedMailboxes.isEmpty, let firstMailbox = self.mailboxes.first {
            selectedMailboxes = [firstMailbox]
        }
    }
}

final class CreateEditAliasViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var prefix = ""
    @Published var suffix = ""
    @Published var mailboxes = ""
    @Published var note = ""

    @Published private(set) var alias = ""
    @Published private(set) var state: State = .loading

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
    }

    private(set) var suffixSelection: SuffixSelection?
    private(set) var mailboxSelection: MailboxSelection?
    let aliasRepository: AliasRepositoryProtocol

    init(mode: ItemMode,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol) {
        self.aliasRepository = aliasRepository
        super.init(mode: mode,
                   userData: userData,
                   shareRepository: shareRepository,
                   shareKeysRepository: shareKeysRepository,
                   itemRevisionRepository: itemRevisionRepository)

        if case let .edit(itemContent) = mode {
            self.title = itemContent.name
            self.note = itemContent.note
        }
        getAliasAndAliasOptions()
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "Create new alias"
        case .edit:
            return "Edit alias"
        }
    }

    override func itemContentType() -> ItemContentType { .alias }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: title, note: note, data: .alias)
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let selectedSuffix = suffixSelection?.selectedSuffix,
              let selectedMailboxes = mailboxSelection?.selectedMailboxes else { return nil }
        return .init(prefix: prefix,
                     signedSuffix: selectedSuffix.signedSuffix,
                     mailboxIds: selectedMailboxes.map { $0.ID })
    }

    func getAliasAndAliasOptions() {
        Task { @MainActor in
            do {
                state = .loading

                var selectedMailboxes = [String]()
                if case .edit(let itemContent) = mode {
                    let alias = try await aliasRepository.getAliasDetails(shareId: shareId,
                                                                          itemId: itemContent.itemId)
                    self.alias = alias.email
                    selectedMailboxes = alias.mailboxes
                }

                let aliasOptions = try await aliasRepository.getAliasOptions(shareId: shareId)

                // Initialize SuffixSelection
                suffixSelection = .init(suffixes: aliasOptions.suffixes)
                suffixSelection?.$selectedSuffix
                    .sink { [weak self] selectedSuffix in
                        guard let self = self else { return }
                        self.suffix = selectedSuffix?.suffix ?? ""
                    }
                    .store(in: &cancellables)
                suffixSelection?.selectDefaultSuffix()

                // Initialize MailboxSelection
                mailboxSelection = .init(mailboxes: aliasOptions.mailboxes)
                mailboxSelection?.$selectedMailboxes
                    .sink { [weak self] selectedMailboxes in
                        guard let self = self else { return }
                        self.mailboxes = selectedMailboxes.compactMap { $0.email }.joined(separator: "\n")
                    }
                    .store(in: &cancellables)
                mailboxSelection?.selectDefaultMailboxes(selectedMailboxes)

                state = .loaded
            } catch {
                state = .error(error)
            }
        }
    }
}
