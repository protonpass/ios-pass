//
// ShareInviteService.swift
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

@preconcurrency import Combine
import Entities
import Foundation

public protocol ShareInviteServiceProtocol: Sendable {
    var currentSelectedElement: CurrentValueSubject<SharingElementData?, Never> { get }

    func setCurrentSelectedVaultItem(with itemNum: Int)
    func setInvitesAndKeys(with data: [InviteRecommendationType: [PublicKey]?])
    func setInvitesAndRoles(with data: [InviteRecommendationType: ShareRole])

    func getAllInvites() -> [InviteRecommendationType]
    func getSharingInfos() -> [SharingInfos]
    func resetShareInviteInformations()
}

public final class ShareInviteService: @unchecked Sendable, ShareInviteServiceProtocol {
    public nonisolated let currentSelectedElement: CurrentValueSubject<SharingElementData?, Never> = .init(nil)

    private let queue = DispatchQueue(label: "me.proton.pass.shareInviteService")
    private var safeCurrentSelectedVaultItems: Int?
    private var currentSelectedVaultItems: Int? {
        get {
            queue.sync {
                safeCurrentSelectedVaultItems
            }
        }
        set {
            queue.sync {
                safeCurrentSelectedVaultItems = newValue
            }
        }
    }

    private var invitesAndKeys = [InviteRecommendationType: [PublicKey]?]()
    private var invitesAndRole = [InviteRecommendationType: ShareRole]()

    public init() {}
}

public extension ShareInviteService {
    func setCurrentSelectedVaultItem(with itemNum: Int) {
        currentSelectedVaultItems = itemNum
    }

    func setInvitesAndKeys(with data: [InviteRecommendationType: [PublicKey]?]) {
        invitesAndKeys = data
    }

    func setInvitesAndRoles(with data: [InviteRecommendationType: ShareRole]) {
        invitesAndRole = data
    }

    func getAllInvites() -> [InviteRecommendationType] {
        Array(invitesAndKeys.keys)
    }

    func getSharingInfos() -> [SharingInfos] {
        guard let element = currentSelectedElement.value else {
            return []
        }
        var result = [SharingInfos]()
        for (invite, keys) in invitesAndKeys {
            if let role = invitesAndRole[invite], let email = invite.currentEmail {
                let info = SharingInfos(shareElement: element,
                                        email: email,
                                        role: role,
                                        receiverPublicKeys: keys,
                                        itemsNum: currentSelectedVaultItems ?? 0)
                result.append(info)
            }
        }
        return result
    }

    func resetShareInviteInformations() {
        currentSelectedElement.send(nil)
        currentSelectedVaultItems = nil
        invitesAndKeys.removeAll()
        invitesAndRole.removeAll()
    }
}
