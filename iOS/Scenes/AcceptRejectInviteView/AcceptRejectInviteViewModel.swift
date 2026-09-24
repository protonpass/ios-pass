//
//
// AcceptRejectInviteViewModel.swift
// Proton Pass - Created on 27/07/2023.
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

import DIComposition
import Entities
import FactoryKit
import Foundation
import Screens

typealias AcceptRejectInviteResult = Result<ItemContent?, any Error>

@MainActor
@Observable
final class AcceptRejectInviteViewModel {
    let invite: Invite
    private(set) var vaultInfos: VaultContent?
    private(set) var executingAction = false
    private(set) var invitedGroupName = ""

    private let rejectInvitation = dependency(\UseCasesContainer.rejectInvitation)
    private let acceptInvitation = dependency(\UseCasesContainer.acceptInvitation)
    private let decodeShareVaultInformation = dependency(\UseCasesContainer.decodeShareVaultInformation)
    private let logger = dependency(\ToolingContainer.logger)
    private let syncEventLoop = dependency(\ServiceContainer.syncEventLoop)
    private let userManager = dependency(\ServiceContainer.userManager)
    private let groupRepository = dependency(\RepositoryContainer.groupRepository)
    private let onResult: (AcceptRejectInviteResult) -> Void

    init(invite: Invite, onResult: @escaping (AcceptRejectInviteResult) -> Void) {
        self.invite = invite
        self.onResult = onResult
    }

    func decodeVaultDataIfApplicable() async {
        guard invite.isVault, invite.vaultData != nil else { return }
        do {
            vaultInfos = try await decodeShareVaultInformation(with: invite)
            if case let .group(invite) = invite {
                let userId = try await userManager.getActiveUserId()
                let group = try await groupRepository.getGroup(userId: userId, groupId: invite.invitedGroupID)
                invitedGroupName = group.name
            }
        } catch {
            logger.error(message: "Could not decode vault content from invitation", error: error)
            onResult(.failure(error))
        }
    }

    func reject() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                executingAction = false
            }

            do {
                executingAction = true
                let userId = try await userManager.getActiveUserId()
                try await rejectInvitation(userId: userId, invite: invite)
                onResult(.success(nil))
            } catch {
                logger.error(message: "Could not reject invitation \(invite)", error: error)
                onResult(.failure(error))
            }
        }
    }

    func accept() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                executingAction = false
            }

            do {
                executingAction = true
                let userData = try await userManager.getUnwrappedActiveUserData()
                let itemToBeOpened = try await acceptInvitation(userData: userData,
                                                                invite: invite)
                syncEventLoop.forceSync()
                onResult(.success(itemToBeOpened))
            } catch {
                logger.error(message: "Could not accept invitation \(invite)", error: error)
                onResult(.failure(error))
            }
        }
    }
}
