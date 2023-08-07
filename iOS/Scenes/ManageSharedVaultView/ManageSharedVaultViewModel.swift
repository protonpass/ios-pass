//
//
// ManageSharedVaultViewModel.swift
// Proton Pass - Created on 02/08/2023.
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

@preconcurrency import Client
import Combine
import Entities
import Factory
import Foundation
import ProtonCore_Networking

final class ManageSharedVaultViewModel: ObservableObject, Sendable {
    let vault: Vault
    @Published private(set) var itemsNumber: Int?
    @Published private(set) var users: [ShareUser] = []
    @Published private(set) var fetching = false
    @Published private(set) var loading = false
    @Published var userRole: ShareRole = .read
    @Published var error: Error?

    private var currentSelectedUser: ShareUser?

    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let getUsersLinkedToShare: GetUsersLinkedToShareUseCase = resolve(\UseCasesContainer
        .getUsersLinkedToShare)
    private let getAllUsersForShare = resolve(\UseCasesContainer.getAllUsersForShare)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let revokeInvitation = resolve(\UseCasesContainer.revokeInvitation)
    private let sendInviteReminder = resolve(\UseCasesContainer.sendInviteReminder)
    private let updateUserShareRole = resolve(\UseCasesContainer.updateUserShareRole)
    private let revokeUserShareAccess = resolve(\UseCasesContainer.revokeUserShareAccess)

    private var fetchingTask: Task<Void, Never>?
    private var updateShareTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    init(vault: Vault) {
        self.vault = vault
        setUp()
    }

    func isLast(info: ShareUser) -> Bool {
        users.last == info
    }

    func fetchShareInformation(displayFetchingLoader: Bool = false) {
        fetchingTask?.cancel()
        fetchingTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            if displayFetchingLoader {
                self.fetching = true
            }
            defer { self.fetching = false }
            do {
                self.itemsNumber = self.getVaultItemCount(for: self.vault)
                if Task.isCancelled {
                    return
                }
                self.users = try await self.fetchVaultContent(for: vault)
            } catch {
                print(error)
                self.error = error
            }
        }
    }

    func setCurrentRole(for user: ShareUser) {
        currentSelectedUser = user
        if userRole != user.shareRole {
            userRole = user.shareRole ?? .read
        }
    }

    func revokeInvite(for user: ShareUser) {
        guard let inviteId = user.inviteID else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.loading = true
            defer { self.loading = false }
            do {
                try await self.revokeInvitation(with: self.vault.shareId, and: inviteId)
                self.fetchShareInformation()
            } catch {
                print(error)
                self.error = error
            }
        }
    }

    func revokeShareAccess(for user: ShareUser) {
        guard let userShareId = user.shareID else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.loading = true
            defer { self.loading = false }
            do {
                try await self.revokeUserShareAccess(with: userShareId, and: self.vault.shareId)
                self.fetchShareInformation()
            } catch {
                print(error)
                self.error = error
            }
        }
    }

    func sendInviteReminder(for user: ShareUser) {
        guard let inviteId = user.inviteID else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                try await self.sendInviteReminder(with: self.vault.shareId, and: inviteId)
                self.fetchShareInformation()
            } catch {
                print(error)
                self.error = error
            }
        }
    }
}

private extension ManageSharedVaultViewModel {
    func setUp() {
        setShareInviteVault(with: vault)
        $userRole
            .sink { [weak self] role in
                guard let self,
                      let selectedUser = self.currentSelectedUser,
                      let userSharedId = selectedUser.shareID,
                      role != selectedUser.shareRole else {
                    return
                }
                self.updateShareTask?.cancel()
                self.updateShareTask = Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }
                    self.loading = true
                    defer { self.loading = false }
                    do {
                        try await updateUserShareRole(userShareId: userSharedId,
                                                      shareId: vault.shareId,
                                                      shareRole: role)
                        self.fetchShareInformation()
                    } catch {
                        print(error)
                        self.error = error
                    }
                }
            }
            .store(in: &cancellables)
    }

    func fetchVaultContent(for vault: Vault) async throws -> [ShareUser] {
        vault.isAdmin ? try await getAllUsersForShare(with: vault.shareId)
            .sorted { $0.email < $1.email } : try await getUsersLinkedToShare(with: vault.shareId)
            .map(\.toShareUser)
            .sorted { $0.email < $1.email }
    }
}
