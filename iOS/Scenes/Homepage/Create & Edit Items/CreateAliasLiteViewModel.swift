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
import Entities
import Factory
import SwiftUI

@MainActor
protocol AliasCreationLiteInfoDelegate: AnyObject {
    func aliasLiteCreationInfo(_ info: AliasCreationLiteInfo)
}

struct AliasCreationLiteInfo: Sendable {
    let prefix: String
    let suffix: Suffix
    let mailboxes: [AliasLinkedMailbox]

    var aliasAddress: String { prefix + suffix.suffix }
}

@MainActor
final class CreateAliasLiteViewModel: ObservableObject {
    @Published var prefix = ""
    @Published private(set) var canCreateAlias: Bool
    @Published private(set) var prefixError: AliasPrefixError?
    @Published var mailboxSelection: AliasLinkedMailboxSelection
    @Published var suffixSelection: SuffixSelection
    let module = resolve(\SharedToolingContainer.module)

    private var cancellables = Set<AnyCancellable>()

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let validateAliasPrefix = resolve(\SharedUseCasesContainer.validateAliasPrefix)

    weak var aliasCreationDelegate: (any AliasCreationLiteInfoDelegate)?

    init(options: AliasOptions, creationInfo: AliasCreationLiteInfo) {
        canCreateAlias = options.canCreateAlias
        suffixSelection = .init(suffixes: options.suffixes, selectedSuffix: creationInfo.suffix)
        mailboxSelection = .init(allUserMailboxes: options.mailboxes, selectedMailboxes: creationInfo.mailboxes)

        prefix = creationInfo.prefix

        _prefix
            .projectedValue
            .dropFirst(3) // TextField is edited 3 times when view is loaded
            .sink { [weak self] _ in
                guard let self else { return }
                validatePrefix()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private APIs

private extension CreateAliasLiteViewModel {
    func validatePrefix() {
        do {
            try validateAliasPrefix(prefix: prefix)
            prefixError = nil
        } catch {
            prefixError = error as? AliasPrefixError
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

    func addMailbox() {
        router.present(for: .addMailbox)
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}
