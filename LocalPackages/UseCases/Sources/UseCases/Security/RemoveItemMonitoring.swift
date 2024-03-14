//
//  
// RemoveItemMonitoring.swift
// Proton Pass - Created on 14/03/2024.
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
//

import Client
import Combine
import Entities

public protocol RemoveItemMonitoringUseCase: Sendable {
   func execute(item: ItemContent) async throws
}

public extension RemoveItemMonitoringUseCase {
    func callAsFunction(item: ItemContent) async throws {
        try await execute(item: item)
    }
}

public final class RemoveItemMonitoring: RemoveItemMonitoringUseCase {
    private let securityCenterRepository: any SecurityCenterRepositoryProtocol

    public init(securityCenterRepository: any SecurityCenterRepositoryProtocol) {
        self.securityCenterRepository = securityCenterRepository
    }
    
    public func execute(item: ItemContent) async throws {
        // TODO: Update the flags of the item and send update to BE
        // This should also reflect in local database and update a the security centre data by calling the refreshSecurityChecks function
       try await securityCenterRepository.refreshSecurityChecks()
    }
}
