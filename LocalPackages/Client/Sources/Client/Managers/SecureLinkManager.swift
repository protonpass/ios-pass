//
// SecureLinkManager.swift
// Proton Pass - Created on 13/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Combine
import Entities
import Foundation

public protocol SecureLinkManagerProtocol: Sendable {
    var currentSecureLinks: CurrentValueSubject<[SecureLink]?, Never> { get }

    @discardableResult
    func updateSecureLinks() async throws -> [SecureLink]
}

public final class SecureLinkManager: SecureLinkManagerProtocol, @unchecked Sendable {
    private let dataSource: any RemoteSecureLinkDatasourceProtocol
    private let userManager: any UserManagerProtocol

    public let currentSecureLinks: CurrentValueSubject<[SecureLink]?, Never> = .init(nil)

    public init(dataSource: any RemoteSecureLinkDatasourceProtocol,
                userManager: any UserManagerProtocol) {
        self.dataSource = dataSource
        self.userManager = userManager
    }

    @discardableResult
    public func updateSecureLinks() async throws -> [SecureLink] {
        let currentUserId = try await userManager.getActiveUserId()
        let newLinks = try await dataSource.getAllLinks(userId: currentUserId)
        currentSecureLinks.send(newLinks)
        return newLinks
    }
}
