//
// SendEventsRequest.swift
// Proton Pass - Created on 17/04/2023.
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

import Entities
import Foundation

struct SendEventsRequest: Encodable, Sendable {
    let eventInfo: [EventInfo]

    enum CodingKeys: String, CodingKey {
        case eventInfo = "EventInfo"
    }
}

public struct EventInfo: Encodable, Sendable {
    let measurementGroup: String
    let event: String
    // periphery:ignore
    let values: [String: String] = [:] // Not applicable to mobile apps
    let dimensions: Dimensions

    enum CodingKeys: String, CodingKey {
        case measurementGroup = "MeasurementGroup"
        case event = "Event"
        case values = "Values"
        case dimensions = "Dimensions"
    }

    struct Dimensions: Encodable {
        let type: String?
        let location: String?
        let userTier: String

        enum CodingKeys: String, CodingKey {
            case type
            case location
            case userTier = "user_tier"
        }
    }
}

public extension EventInfo {
    init(event: TelemetryEvent, userTier: String) {
        measurementGroup = "pass.any.user_actions"
        self.event = event.eventName
        dimensions = .init(type: event.dimensionType,
                           location: event.dimensionLocation,
                           userTier: userTier)
    }
}

private extension TelemetryEvent {
    // The event name sent to the BE
    var eventName: String {
        switch type {
        case .create:
            "item.creation"
        case .read:
            "item.read"
        case .update:
            "item.update"
        case .delete:
            "item.deletion"
        case .autofillDisplay:
            "autofill.display"
        case .autofillTriggeredFromApp, .autofillTriggeredFromSource:
            "autofill.triggered"
        case .searchClick:
            "search.click"
        case .searchTriggered:
            "search.triggered"
        case .twoFaCreation:
            "2fa.creation"
        case .twoFaUpdate:
            "2fa.update"
        case .passkeyCreate:
            "passkey.create_done"
        case .passkeyAuth:
            "passkey.auth_done"
        case .passkeyDisplay:
            "passkey.display_all_passkeys"
        case .monitorDisplayHome:
            "pass_monitor.display_home"
        case .monitorDisplayWeakPasswords:
            "pass_monitor.display_weak_passwords"
        case .monitorDisplayReusedPasswords:
            "pass_monitor.display_reused_passwords"
        case .monitorDisplayMissing2FA:
            "pass_monitor.display_missing_2fa"
        case .monitorDisplayExcludedItems:
            "pass_monitor.display_excluded_items"
        case .monitorDisplayDarkWebMonitoring:
            "pass_monitor.display_dark_web_monitoring"
        case .monitorDisplayMonitoringProtonAddresses:
            "pass_monitor.display_monitoring_proton_addresses"
        case .monitorDisplayMonitoringEmailAliases:
            "pass_monitor.display_monitoring_email_aliases"
        case .monitorAddCustomEmailFromSuggestion:
            "pass_monitor.add_custom_email_from_suggestion"
        case .monitorItemDetailFromWeakPassword:
            "pass_monitor.item_detail_from_weak_password"
        case .monitorItemDetailFromMissing2FA:
            "pass_monitor.item_detail_from_missing_2fa"
        case .monitorItemDetailFromReusedPassword:
            "pass_monitor.item_detail_from_reused_password"
        case .multiAccountAddAccount:
            "pass_multi_account.add_account"
        case .multiAccountRemoveAccount:
            "pass_multi_account.remove_account"
        }
    }

    var dimensionType: String? {
        switch type {
        case let .create(itemContentType):
            itemContentType.dimensionType
        case let .read(itemContentType):
            itemContentType.dimensionType
        case let .update(itemContentType):
            itemContentType.dimensionType
        case let .delete(itemContentType):
            itemContentType.dimensionType
        case .twoFaCreation, .twoFaUpdate:
            "login"
        default:
            nil
        }
    }

    var dimensionLocation: String? {
        switch type {
        case .autofillDisplay, .autofillTriggeredFromApp:
            "app"
        case .autofillTriggeredFromSource:
            "source"
        default:
            nil
        }
    }
}

private extension ItemContentType {
    var dimensionType: String {
        switch self {
        case .login:
            "login"
        case .alias:
            "alias"
        case .note:
            "note"
        case .creditCard:
            "credit_card"
        case .identity:
            "identity"
        }
    }
}
