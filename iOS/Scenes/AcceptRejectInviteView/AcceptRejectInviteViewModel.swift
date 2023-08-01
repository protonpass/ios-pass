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

import Client
import Entities
import Factory

final class AcceptRejectInviteViewModel: ObservableObject {
    @Published private(set) var userInvite: UserInvite
    @Published private(set) var vaultInfos: VaultProtobuf?
    @Published private(set) var executingAction = false
    @Published private(set) var shouldCloseSheet = false
    @Published var error: Error?

    private let rejectInvitation = resolve(\UseCasesContainer.rejectInvitation)
    private let acceptInvitation = resolve(\UseCasesContainer.acceptInvitation)
    private let decodeShareVaultInformation = resolve(\UseCasesContainer.decodeShareVaultInformation)
    private let updateCachedInvitations = resolve(\UseCasesContainer.updateCachedInvitations)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)

    init(invite: UserInvite) {
        userInvite = invite
        setUp()
    }

    func reject() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            defer {
                self.executingAction = false
            }

            do {
                self.executingAction = true
                try await self.rejectInvitation(for: self.userInvite.inviteToken)
                await self.updateCachedInvitations(for: self.userInvite.inviteToken)
                self.syncEventLoop.forceSync()
                self.shouldCloseSheet = true
            } catch {
                self.logger.error(message: "Could not reject invitation \(userInvite)", error: error)
                self.error = error
            }
        }
    }

    func accept() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            defer {
                self.executingAction = false
            }

            do {
                self.executingAction = true
                _ = try await self.acceptInvitation(with: self.userInvite)
                await self.updateCachedInvitations(for: self.userInvite.inviteToken)
                self.shouldCloseSheet = true
            } catch {
                self.logger.error(message: "Could not accept invitation \(userInvite)", error: error)
                self.error = error
            }
        }
    }
}

private extension AcceptRejectInviteViewModel {
    func setUp() {
        decodeVaultData()
    }

    func decodeVaultData() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                self.vaultInfos = try await self.decodeShareVaultInformation(with: self.userInvite)
            } catch {
                self.logger.error(message: "Could not decode vault content from invitation", error: error)
                self.error = error
            }
        }
    }
}
