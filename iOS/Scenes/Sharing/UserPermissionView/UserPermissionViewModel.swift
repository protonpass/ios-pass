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

import Factory
import Foundation

enum UserPermission: String, CaseIterable, Equatable {
    case read = "3"
    case edit = "2"
    case admin = "1"

    var title: String {
        switch self {
        case .read:
            return "Can View"
        case .edit:
            return "Can Edit"
        case .admin:
            return "Can Manage"
        }
    }

    var description: String {
        switch self {
        case .read:
            return "Can view items in this vault."
        case .edit:
            return "Can create, edit, delete and export items in this vault."
        case .admin:
            return "Can grant and revoke access to this vault."
        }
    }

    var summary: String {
        switch self {
        case .read:
            return "only view items in this vault."
        case .edit:
            return "create, edit, delete and export items in this vault."
        case .admin:
            return "grant and revoke access to this vault."
        }
    }
}

@MainActor
final class UserPermissionViewModel: ObservableObject, Sendable {
    @Published private(set) var selectedUserPermission: UserPermission = .read
    @Published private(set) var vaultName = ""
    @Published private(set) var email = ""
    @Published private(set) var canContinue = false

    private let setShareInviteRole = resolve(\UseCasesContainer.setShareInviteRole)
    private let getShareInviteInfos = resolve(\UseCasesContainer.getCurrentShareInviteInformations)

    init() {
        setUp()
    }

    func select(permission: UserPermission) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            await self.setShareInviteRole(with: permission.rawValue)
            self.selectedUserPermission = permission
        }
    }
}

private extension UserPermissionViewModel {
    func setUp() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            let infos = await self.getShareInviteInfos()
            self.selectedUserPermission = UserPermission(rawValue: infos.role ?? "3") ?? .read
            await self.setShareInviteRole(with: self.selectedUserPermission.rawValue)
            self.canContinue = true
            self.vaultName = infos.vault?.name ?? ""
            self.email = infos.email ?? ""
        }
    }
}
