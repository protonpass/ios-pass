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
            switch option {
            case let .remindExistingUserInvitation(inviteId):
                await remindExistingUserInvitation(inviteId: inviteId)
            case let .cancelExistingUserInvitation(inviteId):
                await cancelExistingUserInvitation(inviteId: inviteId)
            case let .cancelNewUserInvitation(inviteId):
                await cancelNewUserInvitation(inviteId: inviteId)
            case let .confirmAccess(inviteId):
                await confirmAccess(inviteId: inviteId)
            case let .updateRole(shareId, role):
                await updateRole(sharedId: shareId, role: role)
            case let .revokeAccess(shareId):
                await revokeAccess(shareId: shareId)
            case let .confirmTransferOwnership(newOwner):
                self.newOwner = newOwner
            case let .transferOwnership(newOwner):
                await transferOwnership(newOwner: newOwner)
            }
        }
    }
}

private extension ManageSharedVaultViewModel {
    func cancelExistingUserInvitation(inviteId: String) async {
        loading = true
        defer { loading = false }
        do {
            try await revokeInvitation(with: vault.shareId, and: inviteId)
            fetchShareInformation()
            syncEventLoop.forceSync()
        } catch {
            display(error: error)
            logger.error(message: "Failed to revoke the invite \(inviteId)", error: error)
        }
    }

    func cancelNewUserInvitation(inviteId: String) async {
        print(#function)
    }

    func revokeAccess(shareId: String) async {
        loading = true
        defer { loading = false }
        do {
            try await revokeUserShareAccess(with: shareId, and: vault.shareId)
            fetchShareInformation()
            syncEventLoop.forceSync()
        } catch {
            display(error: error)
            logger.error(message: "Failed to revoke the share access \(shareId)", error: error)
        }
    }

    func remindExistingUserInvitation(inviteId: String) async {
        do {
            try await sendInviteReminder(with: vault.shareId, and: inviteId)
            fetchShareInformation()
        } catch {
            display(error: error)
            logger.error(message: "Failed send invite reminder \(inviteId)", error: error)
        }
    }

    func confirmAccess(inviteId: String) async {
        print(#function)
    }

    func updateRole(sharedId: String, role: ShareRole) async {
        loading = true
        defer { loading = false }
        do {
            try await updateUserShareRole(userShareId: sharedId,
                                          shareId: vault.shareId,
                                          shareRole: role)
            fetchShareInformation()
        } catch {
            display(error: error)
            logger.error(message: "Failed update user role with \(role)", error: error)
        }
    }

    func transferOwnership(newOwner: NewOwner) async {
        defer { loading = false }
        loading = true
        do {
            try await transferVaultOwnership(newOwnerID: newOwner.shareId,
                                             shareId: vault.shareId)
            fetchShareInformation()
            router.display(element: .successMessage(#localized("Vault has been transferred"), config: nil))
            syncEventLoop.forceSync()
        } catch {
            display(error: error)
            logger
                .error(message: "Failed to transfer ownership of vault \(vault.shareId) to \(newOwner.shareId)",
                       error: error)
        }
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
