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
import Combine
import Entities
import Factory
import Foundation
import Macro

@MainActor
final class AcceptRejectInviteViewModel: ObservableObject {
    @Published private(set) var userInvite: UserInvite
    @Published private(set) var vaultInfos: VaultProtobuf?
    @Published private(set) var executingAction = false
    @Published private(set) var shouldCloseSheet = false

    private let rejectInvitation = resolve(\UseCasesContainer.rejectInvitation)
    private let acceptInvitation = resolve(\UseCasesContainer.acceptInvitation)
    private let decodeShareVaultInformation = resolve(\UseCasesContainer.decodeShareVaultInformation)
    private let updateCachedInvitations = resolve(\UseCasesContainer.updateCachedInvitations)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var cancellables = Set<AnyCancellable>()

    init(invite: UserInvite) {
        userInvite = invite
        setUp()
    }

    func reject() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                self.executingAction = false
            }

            do {
                executingAction = true
                try await rejectInvitation(for: userInvite.inviteToken)
                await updateCachedInvitations(for: userInvite.inviteToken)
                shouldCloseSheet = true
            } catch {
                logger.error(message: "Could not reject invitation \(userInvite)", error: error)
                display(error: error)
            }
        }
    }

    func accept() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                if !userInvite.isVault {
                    executingAction = false
                    shouldCloseSheet = true
                }
            }

            do {
                executingAction = true
                _ = try await acceptInvitation(with: userInvite)
                await updateCachedInvitations(for: userInvite.inviteToken)
                syncEventLoop.forceSync()
            } catch {
                logger.error(message: "Could not accept invitation \(userInvite)", error: error)
                display(error: error)
                executingAction = false
            }
        }
    }
}

private extension AcceptRejectInviteViewModel {
    func setUp() {
        if userInvite.isVault {
            decodeVaultData()
        }
        vaultsManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, case let .loaded(uiModel) = state,
                      uiModel.vaults.map(\.vault.id).contains(self.userInvite.targetID) else {
                    return
                }
                executingAction = false
                shouldCloseSheet = true
            }.store(in: &cancellables)
    }

    func decodeVaultData() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                vaultInfos = try await decodeShareVaultInformation(with: userInvite)
            } catch {
                logger.error(message: "Could not decode vault content from invitation", error: error)
                display(error: error)
            }
        }
    }

    func display(error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }
}
