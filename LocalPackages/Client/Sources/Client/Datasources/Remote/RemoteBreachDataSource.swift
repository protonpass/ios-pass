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

// sourcery: AutoMockable
public protocol RemoteBreachDataSourceProtocol: Sendable {
    func getAllBreachesForUser(userId: String) async throws -> UserBreaches
    func getAllCustomEmailForUser(userId: String) async throws -> [CustomEmail]
    func addEmailToBreachMonitoring(userId: String, email: String) async throws -> CustomEmail
    func verifyCustomEmail(userId: String, emailId: String, code: String) async throws
    func getAllBreachesForEmail(userId: String, email: CustomEmail) async throws -> EmailBreaches
    func getAllBreachesForProtonAddress(userId: String, address: ProtonAddress) async throws -> EmailBreaches
    func removeEmailFromBreachMonitoring(userId: String, emailId: String) async throws
    func getBreachesForAlias(userId: String, sharedId: String, itemId: String) async throws -> EmailBreaches
    func resendEmailVerification(userId: String, emailId: String) async throws

    func markAliasAsResolved(userId: String, sharedId: String, itemId: String) async throws
    func markProtonAddressAsResolved(userId: String, address: ProtonAddress) async throws
    func markCustomEmailAsResolved(userId: String, email: CustomEmail) async throws -> CustomEmail
    func toggleMonitoringFor(userId: String, address: ProtonAddress, shouldMonitor: Bool) async throws
    func toggleMonitoringFor(userId: String, email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail
}

public final class RemoteBreachDataSource: RemoteDatasource, RemoteBreachDataSourceProtocol, @unchecked Sendable {}

public extension RemoteBreachDataSource {
    func getAllBreachesForUser(userId: String) async throws -> UserBreaches {
        let endpoint = GetAllBreachesForUserEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.breaches
    }

    func getAllCustomEmailForUser(userId: String) async throws -> [CustomEmail] {
        let endpoint = GetAllCustomEmailForUserEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.emails.customEmails
    }

    func addEmailToBreachMonitoring(userId: String, email: String) async throws -> CustomEmail {
        let request = AddEmailToBreachMonitoringRequest(email: email)
        let endpoint = AddEmailToBreachMonitoringEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.email
    }

    func verifyCustomEmail(userId: String, emailId: String, code: String) async throws {
        let request = VerifyCustomEmailRequest(code: code)
        let endpoint = VerifyCustomEmailEndpoint(customEmailId: emailId, request: request)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func getAllBreachesForEmail(userId: String, email: CustomEmail) async throws -> EmailBreaches {
        let endpoint = GetBreachesForCustomEmailEndpoint(emailId: email.customEmailID)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.breaches
    }

    func getAllBreachesForProtonAddress(userId: String, address: ProtonAddress) async throws -> EmailBreaches {
        let endpoint = GetAllBreachesForProtonAddressEndpoint(addressId: address.addressID)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.breaches
    }

    func removeEmailFromBreachMonitoring(userId: String, emailId: String) async throws {
        let endpoint = RemoveEmailFromBreachMonitoringEndpoint(emailId: emailId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func getBreachesForAlias(userId: String, sharedId: String, itemId: String) async throws -> EmailBreaches {
        let endpoint = GetBreachesForAliasEndpoint(shareId: sharedId, itemId: itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.breaches
    }

    func resendEmailVerification(userId: String, emailId: String) async throws {
        let endpoint = ResendEmailVerificationEndpoint(emailId: emailId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func markAliasAsResolved(userId: String, sharedId: String, itemId: String) async throws {
        let endpoint = MarkAliasAsResolvedEndpoint(sharedId: sharedId, itemId: itemId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func markProtonAddressAsResolved(userId: String, address: ProtonAddress) async throws {
        let endpoint = MarkProtonAddressAsResolvedEndpoint(addressdId: address.addressID)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func markCustomEmailAsResolved(userId: String, email: CustomEmail) async throws -> CustomEmail {
        let endpoint = MarkCustomEmailAsResolvedEndpoint(customEmailId: email.customEmailID)
        let result = try await exec(userId: userId, endpoint: endpoint)
        return result.email
    }

    func toggleMonitoringFor(userId: String, address: ProtonAddress, shouldMonitor: Bool) async throws {
        let request = ToggleMonitoringRequest(monitor: shouldMonitor)
        let endpoint = ToggleMonitoringForProtonAddressEndpoint(addressId: address.addressID, request: request)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func toggleMonitoringFor(userId: String, email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        let request = ToggleMonitoringRequest(monitor: shouldMonitor)
        let endpoint = ToggleMonitoringForCustomEmailEndpoint(customEmailId: email.customEmailID, request: request)
        let result = try await exec(userId: userId, endpoint: endpoint)
        return result.email
    }
}
