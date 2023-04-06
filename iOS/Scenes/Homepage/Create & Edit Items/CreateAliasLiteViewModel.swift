//
// CreateAliasLiteViewModel.swift
// Proton Pass - Created on 16/02/2023.
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

protocol AliasCreationLiteInfoDelegate: AnyObject {
    func aliasLiteCreationInfo(_ info: AliasCreationLiteInfo)
}

struct AliasCreationLiteInfo {
    let prefix: String
    let suffix: Suffix
    let mailboxes: [Mailbox]

    var aliasAddress: String { prefix + suffix.suffix }
}

protocol CreateAliasLiteViewModelDelegate: AnyObject {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection)
}

final class CreateAliasLiteViewModel: ObservableObject {
    @Published var prefix = ""
    @Published private(set) var prefixError: AliasPrefixError?
    private var cancellables = Set<AnyCancellable>()

    let suffixSelection: SuffixSelection
    let mailboxSelection: MailboxSelection

    weak var aliasCreationDelegate: AliasCreationLiteInfoDelegate?
    weak var delegate: CreateAliasLiteViewModelDelegate?

    var suffix: String {
        suffixSelection.selectedSuffix?.suffix ?? ""
    }

    var mailboxes: String {
        mailboxSelection.selectedMailboxes.compactMap { $0.email }.joined(separator: "\n")
    }

    init(options: AliasOptions, creationInfo: AliasCreationLiteInfo) {
        suffixSelection = .init(suffixes: options.suffixes)
        mailboxSelection = .init(mailboxes: options.mailboxes)

        prefix = creationInfo.prefix
        suffixSelection.selectedSuffix = creationInfo.suffix
        suffixSelection.attach(to: self, storeIn: &cancellables)
        mailboxSelection.selectedMailboxes = creationInfo.mailboxes
        suffixSelection.attach(to: self, storeIn: &cancellables)

        _prefix
            .projectedValue
            .dropFirst(3) // TextField is edited 3 times when view is loaded
            .sink { [unowned self] _ in
                self.validatePrefix()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private APIs
private extension CreateAliasLiteViewModel {
    func validatePrefix() {
        do {
            try AliasPrefixValidator.validate(prefix: prefix)
            self.prefixError = nil
        } catch {
            self.prefixError = error as? AliasPrefixError
        }
    }
}

// MARK: - Public APIs
extension CreateAliasLiteViewModel {
    func confirm() {
        guard let suffix = suffixSelection.selectedSuffix else { return }
        let info = AliasCreationLiteInfo(prefix: prefix,
                                         suffix: suffix,
                                         mailboxes: mailboxSelection.selectedMailboxes)
        aliasCreationDelegate?.aliasLiteCreationInfo(info)
    }

    func showMailboxSelection() {
        delegate?.createAliasLiteViewModelWantsToSelectMailboxes(mailboxSelection)
    }
}
