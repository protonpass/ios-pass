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

final class CreateAliasLiteViewModel: ObservableObject {
    @Published var prefix = ""
    private var cancellables = Set<AnyCancellable>()

    let suffixSelection: SuffixSelection
    let mailboxSelection: MailboxSelection

    weak var delegate: AliasCreationLiteInfoDelegate?

    init(options: AliasOptions, creationInfo: AliasCreationLiteInfo) {
        suffixSelection = .init(suffixes: options.suffixes)
        mailboxSelection = .init(mailboxes: options.mailboxes)

        prefix = creationInfo.prefix
        suffixSelection.selectedSuffix = creationInfo.suffix
        suffixSelection.attach(to: self, storeIn: &cancellables)
        mailboxSelection.selectedMailboxes = creationInfo.mailboxes
        suffixSelection.attach(to: self, storeIn: &cancellables)
    }

    func confirm() {
        guard let suffix = suffixSelection.selectedSuffix else { return }
        delegate?.aliasLiteCreationInfo(.init(prefix: prefix,
                                              suffix: suffix,
                                              mailboxes: mailboxSelection.selectedMailboxes))
    }
}
