//
//
// UserPermissionViewModel.swift
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
import FactoryKit
import Foundation

@MainActor
final class UserPermissionViewModel: ObservableObject {
    @Published private(set) var selectedUserRole: ShareRole = .read
    @Published private(set) var invites = [InviteRecommendationType: ShareRole]()
    @Published private(set) var canContinue = false
    @Published private(set) var currentUserEmail: String?

    private let setShareInviteRole = resolve(\UseCasesContainer.setShareInviteRole)
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus)
    private var getFeatureFlagStatus

    var managerAsAdmin: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passRenameAdminToManager)
    }

    var hasOnlyOneInvite: Bool {
        invites.count == 1
    }

    var isItemSharing: Bool {
        shareInviteService.currentSelectedElement.value?.isItem ?? false
    }

    init() {}

    func setUp() async {
        for invite in shareInviteService.getAllInvites() {
            invites[invite] = .read
            setShareInviteRole(with: invites)
        }
        canContinue = true

        if let userData = try? await userManager.getActiveUserData() {
            currentUserEmail = userData.user.email
        }
    }

    func updateRole(for invite: InviteRecommendationType, with newRole: ShareRole) {
        invites[invite] = newRole
        setShareInviteRole(with: invites)
        if hasOnlyOneInvite {
            selectedUserRole = newRole
        }
    }

    func setRoleForAll(with role: ShareRole) {
        for (invite, _) in invites {
            invites[invite] = role
        }
        setShareInviteRole(with: invites)
    }
}
