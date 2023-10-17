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
    @Published private(set) var expandedEmails: [String] = []
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
    private var updateShareTask: Task<Void, Never>?
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

    func revokeInvite(inviteId: String) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
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
    }

    func revokeShareAccess(shareId: String) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
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
    }

    func sendInviteReminder(inviteId: String) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                try await sendInviteReminder(with: vault.shareId, and: inviteId)
                fetchShareInformation()
            } catch {
                display(error: error)
                logger.error(message: "Failed send invite reminder \(inviteId)", error: error)
            }
        }
    }

    func updateRole(userSharedId: String, role: ShareRole) {
        updateShareTask?.cancel()
        updateShareTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            loading = true
            defer { loading = false }
            do {
                try await updateUserShareRole(userShareId: userSharedId,
                                              shareId: vault.shareId,
                                              shareRole: role)
                fetchShareInformation()
            } catch {
                display(error: error)
                logger.error(message: "Failed update user role with \(role)", error: error)
            }
        }
    }

    func isExpanded(email: String) -> Bool {
        expandedEmails.contains(email)
    }

    func expand(email: String) {
        if !expandedEmails.contains(email) {
            expandedEmails.append(email)
        }
    }
}

// MARK: - Transfer vault Ownership

extension ManageSharedVaultViewModel {
    func canTransferOwnership(to invitee: any ShareInvitee) -> Bool {
        canUserTransferVaultOwnership(for: vault, to: invitee)
    }

    func transferOwnership() {
        Task { @MainActor [weak self] in
            guard let self, let newOwner else {
                return
            }
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

    public var showConfirmAccessButton: Bool {
        false
    }

    public var isPending: Bool {
        false
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareEntryOption] {
        [
            .updateRole(shareId: shareID, role: shareRole),
            .transferOwnership(.init(email: userEmail, shareId: shareID)),
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

    public var showConfirmAccessButton: Bool {
        false
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        // swiftlint:disable:next todo
        // TODO: wait for ShareRoleID exposure
        false
    }

    public var options: [ShareEntryOption] {
        [
            .resendInvitation(inviteId: inviteID),
            .cancelInvitation(inviteId: inviteID)
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

    public var showConfirmAccessButton: Bool {
        inviteState == .accountCreated
    }

    public var isPending: Bool {
        true
    }

    public var isAdmin: Bool {
        shareRole == .admin
    }

    public var options: [ShareEntryOption] {
        switch inviteState {
        case .waitingForAccountCreation:
            [
                .resendInvitation(inviteId: newUserInviteID),
                .cancelInvitation(inviteId: newUserInviteID)
            ]

        case .accountCreated:
            [.cancelInvitation(inviteId: newUserInviteID)]
        }
    }
}
