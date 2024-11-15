//
// TelemetryEventTests.swift
// Proton Pass - Created on 12/11/2024.
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

@testable import Entities
import Testing
import Foundation

@Suite(.tags(.entity))
struct TelemetryEventTypeTests {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    @Test("TelemetryEventType can be encoded and decoded",
          arguments: [
            TelemetryEventType.create(.login),  // Replace `.someContentType` with actual value for ItemContentType
                          .read(.login),
                          .update(.login),
                          .delete(.login),
                          .autofillDisplay,
                          .autofillTriggeredFromSource,
                          .autofillTriggeredFromApp,
                          .searchTriggered,
                          .searchClick,
                          .twoFaCreation,
                          .twoFaUpdate,
                          .passkeyCreate,
                          .passkeyAuth,
                          .passkeyDisplay,
                          .monitorDisplayHome,
                          .monitorDisplayWeakPasswords,
                          .monitorDisplayReusedPasswords,
                          .monitorDisplayMissing2FA,
                          .monitorDisplayExcludedItems,
                          .monitorDisplayDarkWebMonitoring,
                          .monitorDisplayMonitoringProtonAddresses,
                          .monitorDisplayMonitoringEmailAliases,
                          .monitorAddCustomEmailFromSuggestion,
                          .monitorItemDetailFromWeakPassword,
                          .monitorItemDetailFromMissing2FA,
                          .monitorItemDetailFromReusedPassword,
                          .multiAccountAddAccount,
                          .multiAccountRemoveAccount,
                          .notificationDisplayNotification(notificationKey: "exampleKey"),
                          .notificationChangeNotificationStatus(notificationKey: "exampleKey", notificationStatus: 1),
                          .notificationNotificationCtaClick(notificationKey: "exampleKey")
                      ])
    func encodingDecodingTelemetryEventType(type: TelemetryEventType) throws {
                    // Test encoding
                    let encodedData = try encoder.encode(type)
                    let encodedString = String(data: encodedData, encoding: .utf8)!
                    print("Encoded JSON for \(type): \(encodedString)")
        
                    // Test decoding
                    let decodedEvent = try decoder.decode(TelemetryEventType.self, from: encodedData)
                    #expect(type == decodedEvent)
    }
}
