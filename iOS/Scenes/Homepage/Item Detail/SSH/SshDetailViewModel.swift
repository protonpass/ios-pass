//
// SshDetailViewModel.swift
// Proton Pass - Created on 10/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import Entities
import Foundation

final class SshDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var publicKey = ""
    @Published private(set) var privateKey = ""

    var extraSections: [CustomSection] {
        itemContent.sshKey?.extraSections ?? []
    }

    override func bindValues() {
        super.bindValues()
        if case let .sshKey(data) = itemContent.contentData {
            publicKey = data.publicKey
            privateKey = data.privateKey
        } else {
            fatalError("Expecting SSH key type")
        }
    }
}

extension SshDetailViewModel {
    func copyPublicKey() {
        guard !publicKey.isEmpty else { return }
        copyToClipboard(text: publicKey, message: "Public key copied")
    }

    func copyPrivateKey() {
        guard !privateKey.isEmpty else { return }
        copyToClipboard(text: privateKey, message: "Private key copied")
    }
}
