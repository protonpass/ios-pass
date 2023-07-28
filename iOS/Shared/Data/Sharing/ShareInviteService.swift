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

import Client
import Entities

public protocol ShareInviteServiceProtocol {
    var currentSelectedVault: Vault? { get }
    var currentSelectedVaultItems: Int? { get }
    var currentDestinationUserEmail: String? { get }
    var currentUserRole: ShareRole? { get }
    var receiverPublicKeys: [PublicKey]? { get }

    func setCurrentSelectedVault(with vault: Vault)
    func setCurrentSelectedVaultItem(with itemNum: Int)
    func setCurrentDestinationUserEmail(with email: String)
    func setCurrentUserRole(with role: ShareRole)
    func setReceiverPublicKeys(with keys: [PublicKey])
    func resetShareInviteInformations()
}

final class ShareInviteService: ShareInviteServiceProtocol {
    private(set) var currentSelectedVault: Vault?
    private(set) var currentSelectedVaultItems: Int?
    private(set) var currentDestinationUserEmail: String?
    private(set) var currentUserRole: ShareRole?
    private(set) var receiverPublicKeys: [PublicKey]?

    public func setCurrentSelectedVault(with vault: Vault) {
        currentSelectedVault = vault
    }

    public func setCurrentSelectedVaultItem(with itemNum: Int) {
        currentSelectedVaultItems = itemNum
    }

    public func setCurrentDestinationUserEmail(with email: String) {
        currentDestinationUserEmail = email
    }

    public func setCurrentUserRole(with role: ShareRole) {
        currentUserRole = role
    }

    public func setReceiverPublicKeys(with keys: [PublicKey]) {
        receiverPublicKeys = keys
    }

    public func resetShareInviteInformations() {
        currentSelectedVault = nil
        currentDestinationUserEmail = nil
        currentUserRole = nil
        currentSelectedVaultItems = nil
        receiverPublicKeys = nil
    }
}
