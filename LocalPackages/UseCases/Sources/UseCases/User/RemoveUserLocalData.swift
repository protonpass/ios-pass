//
// RemoveUserLocalData.swift
// Proton Pass - Created on 24/06/2024.
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
import Foundation

/// Remove all local data related to a user after logging out
public protocol RemoveUserLocalDataUseCase: Sendable {
    func execute(userId: String) async throws
}

public extension RemoveUserLocalDataUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class RemoveUserLocalData: Sendable, RemoveUserLocalDataUseCase {
    private let accessDatasource: any LocalAccessDatasourceProtocol
    private let itemDatasource: any LocalItemDatasourceProtocol
    private let itemReadEventDatasource: any LocalItemReadEventDatasourceProtocol
    private let organizationDatasource: any LocalOrganizationDatasourceProtocol
    private let searchEntryDatasource: any LocalSearchEntryDatasourceProtocol
    private let shareDatasource: any LocalShareDatasourceProtocol
    private let shareEventIdDatasource: any LocalShareEventIDDatasourceProtocol
    private let shareKeyDatasource: any LocalShareKeyDatasourceProtocol
    private let spotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol
    private let telemetryEventDatasource: any LocalTelemetryEventDatasourceProtocol
    private let userDataDatasource: any LocalUserDataDatasourceProtocol
    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol
    private let inAppNotificationDatasource: any LocalInAppNotificationDatasourceProtocol
    private let passwordDatasource: any LocalPasswordDatasourceProtocol
    private let userEventIdDatasource: any LocalUserEventIdDatasourceProtocol

    public init(accessDatasource: any LocalAccessDatasourceProtocol,
                itemDatasource: any LocalItemDatasourceProtocol,
                itemReadEventDatasource: any LocalItemReadEventDatasourceProtocol,
                organizationDatasource: any LocalOrganizationDatasourceProtocol,
                searchEntryDatasource: any LocalSearchEntryDatasourceProtocol,
                shareDatasource: any LocalShareDatasourceProtocol,
                shareEventIdDatasource: any LocalShareEventIDDatasourceProtocol,
                shareKeyDatasource: any LocalShareKeyDatasourceProtocol,
                spotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol,
                telemetryEventDatasource: any LocalTelemetryEventDatasourceProtocol,
                userDataDatasource: any LocalUserDataDatasourceProtocol,
                userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol,
                inAppNotificationDatasource: any LocalInAppNotificationDatasourceProtocol,
                passwordDatasource: any LocalPasswordDatasourceProtocol,
                userEventIdDatasource: any LocalUserEventIdDatasourceProtocol) {
        self.accessDatasource = accessDatasource
        self.itemDatasource = itemDatasource
        self.itemReadEventDatasource = itemReadEventDatasource
        self.organizationDatasource = organizationDatasource
        self.searchEntryDatasource = searchEntryDatasource
        self.shareDatasource = shareDatasource
        self.shareEventIdDatasource = shareEventIdDatasource
        self.shareKeyDatasource = shareKeyDatasource
        self.spotlightVaultDatasource = spotlightVaultDatasource
        self.telemetryEventDatasource = telemetryEventDatasource
        self.userDataDatasource = userDataDatasource
        self.userPreferencesDatasource = userPreferencesDatasource
        self.inAppNotificationDatasource = inAppNotificationDatasource
        self.passwordDatasource = passwordDatasource
        self.userEventIdDatasource = userEventIdDatasource
    }
}

public extension RemoveUserLocalData {
    func execute(userId: String) async throws {
        async let removeAccess: () = accessDatasource.removeAccess(userId: userId)
        async let removeItems: () = itemDatasource.removeAllItems(userId: userId)
        async let removeItemReadEvents: () = itemReadEventDatasource.removeEvents(userId: userId)
        async let removeOrganization: () = organizationDatasource.removeOrganization(userId: userId)
        async let removeSearchEntries: () = searchEntryDatasource.removeAllEntries(userId: userId)
        async let removeShares: () = shareDatasource.removeAllShares(userId: userId)
        async let removeShareEventIds: () = shareEventIdDatasource.removeAllEntries(userId: userId)
        async let removeShareKeys: () = shareKeyDatasource.removeAllKeys(userId: userId)
        async let removeSpotlightVaults: () = spotlightVaultDatasource.removeAll(for: userId)
        async let removeTelemetryEvents: () = telemetryEventDatasource.removeAllEvents(userId: userId)
        async let removeUserData: () = userDataDatasource.remove(userId: userId)
        async let removeUserPrefs: () = userPreferencesDatasource.removePreferences(for: userId)
        async let removeInAppNotifications: () = inAppNotificationDatasource
            .removeAllNotifications(userId: userId)
        async let removePasswords: () = passwordDatasource.deleteAllPasswords(userId: userId)
        async let removeLastEventId: () = userEventIdDatasource.removeLastEventId(userId: userId)

        _ = try await (removeAccess,
                       removeItems,
                       removeItemReadEvents,
                       removeOrganization,
                       removeSearchEntries,
                       removeShares,
                       removeShareEventIds,
                       removeShareKeys,
                       removeSpotlightVaults,
                       removeTelemetryEvents,
                       removeUserData,
                       removeUserPrefs,
                       removeInAppNotifications,
                       removePasswords,
                       removeLastEventId)
    }
}
