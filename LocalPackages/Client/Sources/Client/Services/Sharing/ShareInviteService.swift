//
// ShareInviteService.swift
// Proton Pass - Created on 20/07/2023.
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

import Combine
import Entities

public protocol ShareInviteServiceProtocol: Sendable {
    var currentSelectedVault: CurrentValueSubject<SharingVaultData?, Never> { get }

    func setCurrentSelectedVaultItem(with itemNum: Int)
    func setEmailsAndKeys(with data: [String: [PublicKey]?])
    func setEmailsAndRoles(with data: [String: ShareRole])

    func getAllEmails() -> [String]
    func getSharingInfos() -> [SharingInfos]
    func resetShareInviteInformations()
}

public final class ShareInviteService: ShareInviteServiceProtocol {
    public nonisolated let currentSelectedVault: CurrentValueSubject<SharingVaultData?, Never> = .init(nil)
    private var currentSelectedVaultItems: Int?
    private var emailsAndKeys = [String: [PublicKey]?]()
    private var emailsAndRole = [String: ShareRole]()

    public init() {}
}

public extension ShareInviteService {
    func setCurrentSelectedVaultItem(with itemNum: Int) {
        currentSelectedVaultItems = itemNum
    }

    func setEmailsAndKeys(with data: [String: [PublicKey]?]) {
        emailsAndKeys = data
    }

    func setEmailsAndRoles(with data: [String: ShareRole]) {
        emailsAndRole = data
    }

    func getAllEmails() -> [String] {
        Array(emailsAndKeys.keys)
    }

    func getSharingInfos() -> [SharingInfos] {
        guard let vault = currentSelectedVault.value else {
            return []
        }
        var result = [SharingInfos]()
        for (email, keys) in emailsAndKeys {
            if let role = emailsAndRole[email] {
                let info = SharingInfos(vault: vault,
                                        email: email,
                                        role: role,
                                        receiverPublicKeys: keys,
                                        itemsNum: currentSelectedVaultItems ?? 0)
                result.append(info)
            }
        }
        return result
    }

    func resetShareInviteInformations() {
        currentSelectedVault.send(nil)
        currentSelectedVaultItems = nil
        emailsAndKeys.removeAll()
        emailsAndRole.removeAll()
    }
}
