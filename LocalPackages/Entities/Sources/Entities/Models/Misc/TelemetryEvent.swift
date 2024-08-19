//
// TelemetryEvent.swift
// Proton Pass - Created on 19/04/2023.
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

import Foundation

public struct TelemetryEvent: Sendable {
    public let uuid: String
    public let time: TimeInterval
    public let type: TelemetryEventType

    public init(uuid: String, time: TimeInterval, type: TelemetryEventType) {
        self.uuid = uuid
        self.time = time
        self.type = type
    }
}

public enum TelemetryEventType: Sendable, Equatable {
    case create(ItemContentType)
    case read(ItemContentType)
    case update(ItemContentType)
    case delete(ItemContentType)
    case autofillDisplay
    case autofillTriggeredFromSource // AutoFill from QuickType bar
    case autofillTriggeredFromApp // AutoFill manually from extension
    case searchTriggered
    case searchClick
    case twoFaCreation
    case twoFaUpdate
    case passkeyCreate
    case passkeyAuth
    case passkeyDisplay
    case monitorDisplayHome
    case monitorDisplayWeakPasswords
    case monitorDisplayReusedPasswords
    case monitorDisplayMissing2FA
    case monitorDisplayExcludedItems
    case monitorDisplayDarkWebMonitoring
    case monitorDisplayMonitoringProtonAddresses
    case monitorDisplayMonitoringEmailAliases
    case monitorAddCustomEmailFromSuggestion
    case monitorItemDetailFromWeakPassword
    case monitorItemDetailFromMissing2FA
    case monitorItemDetailFromReusedPassword
    case multiAccountAddAccount
    case multiAccountRemoveAccount

    /// For local storage only as we store events locally before sending to the BE in batch
    public var rawValue: String {
        switch self {
        case let .create(type):
            "create.\(type.rawValue)"
        case let .read(type):
            "read.\(type.rawValue)"
        case let .update(type):
            "update.\(type.rawValue)"
        case let .delete(type):
            "delete.\(type.rawValue)"
        case .autofillDisplay:
            "autofill.display"
        case .autofillTriggeredFromSource:
            "autofill.triggered.source"
        case .autofillTriggeredFromApp:
            "autofill.triggered.app"
        case .searchTriggered:
            "search.triggered"
        case .searchClick:
            "search.click"
        case .twoFaCreation:
            "2fa.creation"
        case .twoFaUpdate:
            "2fa.update"
        case .passkeyCreate:
            "passkey.create"
        case .passkeyAuth:
            "passkey.auth"
        case .passkeyDisplay:
            "passkey.display"
        case .monitorDisplayHome:
            "monitor.display.home"
        case .monitorDisplayWeakPasswords:
            "monitor.display.weak.passwords"
        case .monitorDisplayReusedPasswords:
            "monitor.display.reused.passwords"
        case .monitorDisplayMissing2FA:
            "monitor.display.missing.2fa"
        case .monitorDisplayExcludedItems:
            "monitor.display.excluded.items"
        case .monitorDisplayDarkWebMonitoring:
            "monitor.display.dark.web.monitoring"
        case .monitorDisplayMonitoringProtonAddresses:
            "monitor.display.monitoring.proton.addresses"
        case .monitorDisplayMonitoringEmailAliases:
            "monitor.display.monitoring.email.aliases"
        case .monitorAddCustomEmailFromSuggestion:
            "monitor.add.custom.email.from.suggestion"
        case .monitorItemDetailFromWeakPassword:
            "monitor.item.detail.from.weak.password"
        case .monitorItemDetailFromMissing2FA:
            "monitor.item.detail.from.missing.2fa"
        case .monitorItemDetailFromReusedPassword:
            "monitor.item.detail.from.reused.password"
        case .multiAccountAddAccount:
            "multi.account.add.account"
        case .multiAccountRemoveAccount:
            "multi.account.remove.account"
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    public init?(rawValue: String) {
        switch rawValue {
        case "autofill.display":
            self = .autofillDisplay
        case "autofill.triggered.source":
            self = .autofillTriggeredFromSource
        case "autofill.triggered.app":
            self = .autofillTriggeredFromApp
        case "search.triggered":
            self = .searchTriggered
        case "search.click":
            self = .searchClick
        case "2fa.creation":
            self = .twoFaCreation
        case "2fa.update":
            self = .twoFaUpdate
        case "passkey.create":
            self = .passkeyCreate
        case "passkey.auth":
            self = .passkeyAuth
        case "passkey.display":
            self = .passkeyDisplay
        case "monitor.display.home":
            self = .monitorDisplayHome
        case "monitor.display.weak.passwords":
            self = .monitorDisplayWeakPasswords
        case "monitor.display.reused.passwords":
            self = .monitorDisplayReusedPasswords
        case "monitor.display.missing.2fa":
            self = .monitorDisplayMissing2FA
        case "monitor.display.excluded.items":
            self = .monitorDisplayExcludedItems
        case "monitor.display.dark.web.monitoring":
            self = .monitorDisplayDarkWebMonitoring
        case "monitor.display.monitoring.proton.addresses":
            self = .monitorDisplayMonitoringProtonAddresses
        case "monitor.display.monitoring.email.aliases":
            self = .monitorDisplayMonitoringEmailAliases
        case "monitor.add.custom.email.from.suggestion":
            self = .monitorAddCustomEmailFromSuggestion
        case "monitor.item.detail.from.weak.password":
            self = .monitorItemDetailFromWeakPassword
        case "monitor.item.detail.from.missing.2fa":
            self = .monitorItemDetailFromMissing2FA
        case "monitor.item.detail.from.reused.password":
            self = .monitorItemDetailFromReusedPassword
        case "multi.account.add.account":
            self = .multiAccountAddAccount
        case "multi.account.remove.account":
            self = .multiAccountRemoveAccount
        default:
            if let crudEvent = Self.crudEvent(rawValue: rawValue) {
                self = crudEvent
            } else {
                return nil
            }
        }
    }

    private static func crudEvent(rawValue: String) -> TelemetryEventType? {
        let components = rawValue.components(separatedBy: ".")
        guard components.count == 2,
              let eventType = components.first,
              let itemTypeRawValue = Int(components.last ?? ""),
              let itemType = ItemContentType(rawValue: itemTypeRawValue) else { return nil }

        switch eventType {
        case "create":
            return .create(itemType)
        case "read":
            return .read(itemType)
        case "update":
            return .update(itemType)
        case "delete":
            return .delete(itemType)
        default:
            return nil
        }
    }
}
