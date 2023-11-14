//
// UpdateLastUseTime.swift
// Proton Pass - Created on 09/11/2023.
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
import Foundation
import ProtonCoreServices

public protocol UpdateLastUseTimeUseCase {
    func execute(item: ItemIdentifiable, date: Date) async throws
}

public extension UpdateLastUseTimeUseCase {
    func callAsFunction(item: ItemIdentifiable, date: Date) async throws {
        try await execute(item: item, date: date)
    }
}

public final class UpdateLastUseTime: UpdateLastUseTimeUseCase {
    private let apiService: APIService

    public init(apiService: APIService) {
        self.apiService = apiService
    }

    public func execute(item: ItemIdentifiable, date: Date) async throws {
        let endpoint = UpdateLastUseTimeEndpoint(shareId: item.shareId,
                                                 itemId: item.itemId,
                                                 lastUseTime: date.timeIntervalSince1970)
        _ = try await apiService.exec(endpoint: endpoint)
    }
}
