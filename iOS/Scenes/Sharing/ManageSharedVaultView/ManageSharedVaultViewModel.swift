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

import Client
import Combine
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreNetworking

final class ManageSharedVaultViewModel: ObservableObject, @unchecked Sendable {
    private(set) var vault: Vault
    @Published private(set) var itemsNumber = 0
    @Published private(set) var invitations = ShareInvites.default
    @Published private(set) var members: [UserShareInfos] = []
    @Published private(set) var fetching = false
    @Published private(set) var loading = false
    @Published var newOwner: NewOwner?

    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let getVaultInfos = resolve(\UseCasesContainer.getVaultInfos)
    private let getUsersLinkedToShare = resolve(\UseCasesContainer.getUsersLinkedToShare)
    private let getPendingInvitationsForShare = resolve(\UseCasesContainer.getPendingInvitationsForShare)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let revokeInvitation = resolve(\UseCasesContainer.revokeInvitation)
    private let revokeNewUserInvitation = resolve(\UseCasesContainer.revokeNewUserInvitation)
    private let sendInviteReminder = resolve(\UseCasesContainer.sendInviteReminder)
    private let updateUserShareRole = resolve(\UseCasesContainer.updateUserShareRole)
    private let revokeUserShareAccess = resolve(\UseCasesContainer.revokeUserShareAccess)
    private let transferVaultOwnership = resolve(\UseCasesContainer.transferVaultOwnership)
    private let canUserTransferVaultOwnership = resolve(\UseCasesContainer.canUserTransferVaultOwnership)
    private let canUserShareVault = resolve(\UseCasesContainer.canUserShareVault)
    private let userData = resolve(\SharedDataContainer.userData)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private var fetchingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var canShare: Bool {
        canUserShareVault(for: vault)
    }

    init(vault: Vault) {
        self.vault = vault
        setUp()
    }

    func isCurrentUser(_ invitee: any ShareInvitee) -> Bool {
        userData.user.email == invitee.email
    }

    func isOwnerAndCurrentUser(_ invitee: any ShareInvitee) -> Bool {
        vault.isOwner && isCurrentUser(invitee)
    }

    func shareWithMorePeople() {
        router.present(for: .sharingFlow(.none))
    }

    func fetchShareInformation(displayFetchingLoader: Bool = false) {
        fetchingTask?.cancel()
        fetchingTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            if displayFetchingLoader {
                fetching = true
            }
            defer { fetching = false }
            do {
                itemsNumber = getVaultItemCount(for: vault)
                if Task.isCancelled {
                    return
                }
                let shareId = vault.shareId
                if vault.isAdmin {
                    invitations = try await getPendingInvitationsForShare(with: shareId)
                }
                members = try await getUsersLinkedToShare(with: shareId)
            } catch {
                display(error: error)
                logger.error(message: "Failed to fetch the current share informations", error: error)
            }
        }
    }

    func canTransferOwnership(to invitee: any ShareInvitee) -> Bool {
        canUserTransferVaultOwnership(for: vault, to: invitee)
    }

    func handle(option: ShareInviteeOption) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                switch option {
                case let .remindExistingUserInvitation(inviteId):
                    try await remindExistingUserInvitation(inviteId: inviteId)
                case let .cancelExistingUserInvitation(inviteId):
                    try await cancelExistingUserInvitation(inviteId: inviteId)
                case let .cancelNewUserInvitation(inviteId):
                    try await cancelNewUserInvitation(inviteId: inviteId)
                case let .confirmAccess(inviteId):
                    try await confirmAccess(inviteId: inviteId)
                case let .updateRole(shareId, role):
                    try await updateRole(sharedId: shareId, role: role)
                case let .revokeAccess(shareId):
                    try await revokeAccess(shareId: shareId)
                case let .confirmTransferOwnership(newOwner):
                    self.newOwner = newOwner
                case let .transferOwnership(newOwner):
                    try await transferOwnership(newOwner: newOwner)
                }
            } catch {
                display(error: error)
            }
        }
    }
}

private extension ManageSharedVaultViewModel {
    func cancelExistingUserInvitation(inviteId: String) async throws {
        defer { loading = false }
        loading = true
        try await revokeInvitation(with: vault.shareId, and: inviteId)
        fetchShareInformation()
        syncEventLoop.forceSync()
    }

    func cancelNewUserInvitation(inviteId: String) async throws {
        defer { loading = false }
        loading = true
        try await revokeNewUserInvitation(with: vault.shareId, and: inviteId)
        fetchShareInformation()
        syncEventLoop.forceSync()
    }

    func revokeAccess(shareId: String) async throws {
        defer { loading = false }
        loading = true
        try await revokeUserShareAccess(with: shareId, and: vault.shareId)
        fetchShareInformation()
        syncEventLoop.forceSync()
    }

    func remindExistingUserInvitation(inviteId: String) async throws {
        try await sendInviteReminder(with: vault.shareId, and: inviteId)
        fetchShareInformation()
    }

    func confirmAccess(inviteId: String) async throws {
        print(#function)
    }

    func updateRole(sharedId: String, role: ShareRole) async throws {
        defer { loading = false }
        loading = true
        try await updateUserShareRole(userShareId: sharedId,
                                      shareId: vault.shareId,
                                      shareRole: role)
        fetchShareInformation()
    }

    func transferOwnership(newOwner: NewOwner) async throws {
        defer { loading = false }
        loading = true
        try await transferVaultOwnership(newOwnerID: newOwner.shareId, shareId: vault.shareId)
        fetchShareInformation()
        router.display(element: .successMessage(#localized("Vault has been transferred"), config: nil))
        syncEventLoop.forceSync()
    }
}

private extension ManageSharedVaultViewModel {
    func setUp() {
        setShareInviteVault(with: .existing(vault))

        getVaultInfos(for: vault.id)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vaultInfos in
                guard let self, vaultInfos != vault else {
                    return
                }
                vault = vaultInfos
                fetchShareInformation()
                loading = false
            }
            .store(in: &cancellables)
    }

    func display(error: Error) {
        router.display(element: .displayErrorBanner(error))
    }
}

extension ShareInvites {
    var invitees: [any ShareInvitee] {
        exisingInvites + newInvites
    }
}

// MARK: Conformances to ShareInvitee

extension UserShareInfos: ShareInvitee {
    public var email: String {
        userEmail
    }

    public var subtitle: String {
        if owner {
            #localized("Owner")
        } else {
            shareRole.title
        }
    }

    public var isPending: Bool {
        false
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        [
            .updateRole(shareId: shareID, role: shareRole),
            .confirmTransferOwnership(.init(email: userEmail, shareId: shareID)),
            .revokeAccess(shareId: shareID)
        ]
    }
}

extension ShareExisingUserInvite: ShareInvitee {
    public var email: String {
        invitedEmail
    }

    public var subtitle: String {
        #localized("Invitation sent")
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        [
            .remindExistingUserInvitation(inviteId: inviteID),
            .cancelExistingUserInvitation(inviteId: inviteID)
        ]
    }
}

extension ShareNewUserInvite: ShareInvitee {
    public var email: String {
        invitedEmail
    }

    public var subtitle: String {
        switch inviteState {
        case .waitingForAccountCreation:
            #localized("Pending account creation")
        case .accountCreated:
            shareRole.title
        }
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareInviteeOption] {
        switch inviteState {
        case .waitingForAccountCreation:
            [
                .cancelNewUserInvitation(inviteId: newUserInviteID)
            ]

        case .accountCreated:
            [
                .cancelNewUserInvitation(inviteId: newUserInviteID),
                .confirmAccess(inviteId: newUserInviteID)
            ]
        }
    }
}
