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

import Entities
import Factory
import Foundation

@MainActor
final class UserPermissionViewModel: ObservableObject {
    @Published private(set) var selectedUserRole: ShareRole = .read
    @Published private(set) var emails = [String: ShareRole]()
    @Published private(set) var canContinue = false

    private let setShareInviteRole = resolve(\UseCasesContainer.setShareInviteRole)
    private let shareInviteService = resolve(\ServiceContainer.shareInviteService)

    var hasOnlyOneInvite: Bool {
        emails.count == 1
    }

    var isItemSharing: Bool {
        shareInviteService.currentSelectedElement.value?.isItem ?? false
    }

    init() {
        setUp()
    }

    func updateRole(for email: String, with newRole: ShareRole) {
        emails[email] = newRole
        setShareInviteRole(with: emails)
        if hasOnlyOneInvite {
            selectedUserRole = newRole
        }
    }

    func setRoleForAll(with role: ShareRole) {
        for (email, _) in emails {
            emails[email] = role
        }
        setShareInviteRole(with: emails)
    }
}

private extension UserPermissionViewModel {
    func setUp() {
        for email in shareInviteService.getAllEmails() {
            emails[email] = .read
            setShareInviteRole(with: emails)
        }
        canContinue = true
    }
}
