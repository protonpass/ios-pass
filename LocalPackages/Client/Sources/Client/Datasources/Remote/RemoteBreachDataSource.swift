//
// RemoteBreachDataSource.swift
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

import Entities

public protocol RemoteBreachDataSourceProtocol: Sendable {
    func getAllBreachesForUser() async throws -> GeneralBreaches
    func getAllCustomEmailForUser() async throws -> [CustomEmail]
    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail
    func verifyCustomEmail(emailId: String, code: String) async throws
    func getAllBreachesForEmail(emailId: String) async throws -> BreachDetails
    func removeEmailFromBreachMonitoring(emailId: String) async throws
    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> BreachDetails
}

public final class RemoteBreachDataSource: RemoteDatasource, RemoteBreachDataSourceProtocol {}

public extension RemoteBreachDataSource {
    func getAllBreachesForUser() async throws -> GeneralBreaches {
        let endpoint = GetAllBreachesForUserEndpoint()
        let response = try await exec(endpoint: endpoint)
        return response.breaches
    }

    func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        let endpoint = GetAllCustomEmailForUserEndpoint()
        let response = try await exec(endpoint: endpoint)
        return response.emails.customEmails
    }

    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail {
        let request = AddEmailToBreachMonitoringRequest(email: email)
        let endpoint = AddEmailToBreachMonitoringEndpoint(request: request)
        let response = try await exec(endpoint: endpoint)
        return response.email
    }

    func verifyCustomEmail(emailId: String, code: String) async throws {
        let request = VerifyCustomEmailRequest(code: code)
        let endpoint = VerifyCustomEmailEndpoint(customEmailId: emailId, request: request)
        _ = try await exec(endpoint: endpoint)
    }

    func getAllBreachesForEmail(emailId: String) async throws -> BreachDetails {
        let endpoint = GetAllBreachesForEmailEndpoint(emailId: emailId)
        let response = try await exec(endpoint: endpoint)
        return response.breaches
    }

    func removeEmailFromBreachMonitoring(emailId: String) async throws {
        let endpoint = RemoveEmailFromBreachMonitoringEndpoint(emailId: emailId)
        _ = try await exec(endpoint: endpoint)
    }

    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> BreachDetails {
        let endpoint = GetBreachesForAliasEndpoint(shareId: sharedId, itemId: itemId)
        let response = try await exec(endpoint: endpoint)
        return response.breaches
    }
}
