//
// CheckAccessToPass.swift
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

import Client
import Core
import ProtonCoreServices

/// Inform the BE that the users had logged in into Pass so that welcome or instruction emails can be sent
public protocol CheckAccessToPassUseCase: Sendable {
    func execute()
}

public extension CheckAccessToPassUseCase {
    func callAsFunction() {
        execute()
    }
}

public final class CheckAccessToPass: @unchecked Sendable, CheckAccessToPassUseCase {
    private let apiService: APIService
    private let logger: Logger

    public init(apiService: APIService, logManager: LogManagerProtocol) {
        self.apiService = apiService
        logger = .init(manager: logManager)
    }

    public func execute() {
        Task { [weak self] in
            guard let self else { return }
            do {
                logger.trace("Checking access to Pass")
                let endpoint = CheckAccessEndpoint()
                _ = try await apiService.exec(endpoint: endpoint)
                logger.info("Checked access to Pass")
            } catch {
                logger.error(error)
            }
        }
    }
}
