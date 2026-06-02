//
//
// GetInviteDecryptionKeys.swift
// Proton Pass - Created on 17/10/2025.
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
//

import Client
import Entities
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreLogin

public protocol GetInviteDecryptionKeysUseCase: Sendable {
    func execute(invite: Invite) async throws -> [DecryptionKey]
}

public extension GetInviteDecryptionKeysUseCase {
    func callAsFunction(invite: Invite) async throws -> [DecryptionKey] {
        try await execute(invite: invite)
    }
}

public final class GetInviteDecryptionKeys: GetInviteDecryptionKeysUseCase {
    private let userManager: any UserManagerProtocol
    private let groupRepository: any GroupRepositoryProtocol
    private let decryptGroupKeys: any DecryptGroupKeyUseCase
    private let updateUserAddresses: any UpdateUserAddressesUseCase

    public init(userManager: any UserManagerProtocol,
                groupRepository: any GroupRepositoryProtocol,
                decryptGroupKeys: any DecryptGroupKeyUseCase,
                updateUserAddresses: any UpdateUserAddressesUseCase) {
        self.userManager = userManager
        self.groupRepository = groupRepository
        self.decryptGroupKeys = decryptGroupKeys
        self.updateUserAddresses = updateUserAddresses
    }

    public func execute(invite: Invite) async throws -> [DecryptionKey] {
        let userData = try await userManager.getUnwrappedActiveUserData()
        return try await getDecryptionKeys(invite: invite, userData: userData)
    }
}

private extension GetInviteDecryptionKeys {
    func getDecryptionKeys(invite: Invite, userData: UserData) async throws -> [DecryptionKey] {
        switch invite {
        case let .user(invite):
            guard let invitedAddress = try await address(for: invite.invitedEmail, userData: userData) else {
                throw PassError.sharing(.invalidAddress(invite.invitedEmail))
            }

            return try CryptoUtils.unlockAddressKeys(address: invitedAddress,
                                                     userData: userData)

        case let .group(invite):
            let group = try await groupRepository.getGroup(userId: userData.user.ID,
                                                           groupId: invite.invitedGroupID)
            let groupAddressKeys = try await decryptGroupKeys(group: group,
                                                              isGroupOwner: invite.isGroupOwner,
                                                              userData: userData)
            return [groupAddressKeys.privateKey]
        }
    }

    func address(for email: String, userData: UserData) async throws -> Address? {
        guard let invitedAddress = userData.address(for: email) else {
            return try await updateUserAddresses()?
                .first(where: { $0.email == email })
        }
        return invitedAddress
    }
}
