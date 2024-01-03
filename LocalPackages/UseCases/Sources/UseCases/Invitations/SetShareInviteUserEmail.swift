//
//
// SetShareInviteUserEmail.swift
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
//

import Client
import Entities

public protocol SetShareInvitesUserEmailsAndKeysUseCase {
    func execute(with emails: [String]) async throws
}

public extension SetShareInvitesUserEmailsAndKeysUseCase {
    func callAsFunction(with emails: [String]) async throws {
        try await execute(with: emails)
    }
}

public final class SetShareInvitesUserEmailsAndKeys: SetShareInvitesUserEmailsAndKeysUseCase {
    private let shareInviteService: any ShareInviteServiceProtocol
    private let getEmailPublicKeyUseCase: any GetEmailPublicKeyUseCase

    public init(shareInviteService: any ShareInviteServiceProtocol,
                getEmailPublicKeyUseCase: any GetEmailPublicKeyUseCase) {
        self.shareInviteService = shareInviteService
        self.getEmailPublicKeyUseCase = getEmailPublicKeyUseCase
    }

    public func execute(with emails: [String]) async throws {
        var emailsAndKeys = [String: [PublicKey]?]()
        for email in emails {
            do {
                let receiverPublicKeys = try await getEmailPublicKeyUseCase(with: email)
                emailsAndKeys[email] = receiverPublicKeys
            } catch {
                if let passError = error as? PassError,
                   case let .sharing(reason) = passError,
                   reason == .notProtonAddress {
                    /// Subcript will not work because it won't create the key with nil value
                    /// if the key doesn't exist before. Have to use `updateValue`.
                    emailsAndKeys.updateValue(nil, forKey: email)
                } else {
                    throw error
                }
            }
        }
        shareInviteService.setEmailsAndKeys(with: emailsAndKeys)
    }
}
