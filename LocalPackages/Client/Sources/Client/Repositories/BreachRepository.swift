//
// BreachRepository.swift
// Proton Pass - Created on 10/04/2024.
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
@preconcurrency import Core
import Entities
import Foundation

/// Take care of fetching and caching behind the scenes
public protocol BreachRepositoryProtocol: Sendable {
    func getAllBreachesForUser() async throws -> UserBreaches
    func getAllCustomEmailForUser() async throws -> [CustomEmail]
    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail
    func verifyCustomEmail(emailId: String, code: String) async throws
    func removeEmailFromBreachMonitoring(emailId: String) async throws
    func resendEmailVerification(emailId: String) async throws
    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches
}

public actor BreachRepository: BreachRepositoryProtocol {
    private let remoteDataSource: any RemoteBreachDataSourceProtocol
    private let logger: Logger

    public init(remoteDataSource: any RemoteBreachDataSourceProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDataSource = remoteDataSource
        logger = .init(manager: logManager)
    }

    public func getAllBreachesForUser() async throws -> UserBreaches {
        let breaches = try await remoteDataSource.getAllBreachesForUser()
        return breaches
    }

    public func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        let emails = try await remoteDataSource.getAllCustomEmailForUser()
        return emails
    }

    public func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail {
        let email = try await remoteDataSource.addEmailToBreachMonitoring(email: email)
        return email
    }

    public func verifyCustomEmail(emailId: String, code: String) async throws {
        try await remoteDataSource.verifyCustomEmail(emailId: emailId, code: code)
    }

    public func removeEmailFromBreachMonitoring(emailId: String) async throws {
        try await remoteDataSource.removeEmailFromBreachMonitoring(emailId: emailId)
    }

    public func resendEmailVerification(emailId: String) async throws {
        try await remoteDataSource.removeEmailFromBreachMonitoring(emailId: emailId)
    }

    public func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches {
        try Task.checkCancellation()
        return try await remoteDataSource.getBreachesForAlias(sharedId: sharedId, itemId: itemId)
    }
}
