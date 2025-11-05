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

public enum TelemetryEventType: Sendable, Equatable, Codable {
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
    case notificationDisplay(key: String)
    case notificationChangeStatus(key: String, status: Int)
    case notificationCtaClick(key: String)
    case fileUploaded(mimeType: String)
    case onboardingUpsellCtaClicked(planName: String)
    case onboardingUpsellSubscribed
    case onboardingUpsellSkipped
    case onboardingBiometricsEnabled
    case onboardingBiometricsSkipped
    case onboardingPassAsAutofillProviderEnabled
    case onboardingPassAsAutofillProviderSkipped
    case onboardingAliasVideoOpened

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
        case "passkey.create", "passkey.create_done":
            self = .passkeyCreate
        case "passkey.auth", "passkey.auth_done":
            self = .passkeyAuth
        case "passkey.display", "passkey.display_all_passkeys":
            self = .passkeyDisplay
        case "monitor.display.home", "pass_monitor.display_home":
            self = .monitorDisplayHome
        case "monitor.display.weak.passwords", "pass_monitor.display_weak_passwords":
            self = .monitorDisplayWeakPasswords
        case "monitor.display.reused.passwords", "pass_monitor.display_reused_passwords":
            self = .monitorDisplayReusedPasswords
        case "monitor.display.missing.2fa", "pass_monitor.display_missing_2fa":
            self = .monitorDisplayMissing2FA
        case "monitor.display.excluded.items", "pass_monitor.display_excluded_items":
            self = .monitorDisplayExcludedItems
        case "monitor.display.dark.web.monitoring", "pass_monitor.display_dark_web_monitoring":
            self = .monitorDisplayDarkWebMonitoring
        case "monitor.display.monitoring.proton.addresses", "pass_monitor.display_monitoring_proton_addresses":
            self = .monitorDisplayMonitoringProtonAddresses
        case "monitor.display.monitoring.email.aliases", "pass_monitor.display_monitoring_email_aliases":
            self = .monitorDisplayMonitoringEmailAliases
        case "monitor.add.custom.email.from.suggestion", "pass_monitor.add_custom_email_from_suggestion":
            self = .monitorAddCustomEmailFromSuggestion
        case "monitor.item.detail.from.weak.password", "pass_monitor.item_detail_from_weak_password":
            self = .monitorItemDetailFromWeakPassword
        case "monitor.item.detail.from.missing.2fa", "pass_monitor.item_detail_from_missing_2fa":
            self = .monitorItemDetailFromMissing2FA
        case "monitor.item.detail.from.reused.password", "pass_monitor.item_detail_from_reused_password":
            self = .monitorItemDetailFromReusedPassword
        case "multi.account.add.account", "pass_multi_account.add_account":
            self = .multiAccountAddAccount
        case "multi.account.remove.account", "pass_multi_account.remove_account":
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

    // The event name sent to the BE
    public var eventName: String {
        switch self {
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
        case .notificationDisplay:
            "pass_notification.display_notification"
        case .notificationChangeStatus:
            "pass_notification.change_notification_status"
        case .notificationCtaClick:
            "pass_notification.notification_cta_click"
        case .fileUploaded:
            "pass_file_attachment.file_uploaded"
        case .onboardingUpsellCtaClicked:
            "onboarding_upsell_cta_clicked"
        case .onboardingUpsellSubscribed:
            "onboarding_upsell_subscribed"
        case .onboardingUpsellSkipped:
            "onboarding_upsell_skipped"
        case .onboardingBiometricsEnabled:
            "onboarding_biometrics_enabled"
        case .onboardingBiometricsSkipped:
            "onboarding_biometrics_skipped"
        case .onboardingPassAsAutofillProviderEnabled:
            "onboarding_pass_as_autofill_provider_enabled"
        case .onboardingPassAsAutofillProviderSkipped:
            "onboarding_pass_as_autofill_provider_skipped"
        case .onboardingAliasVideoOpened:
            "onboarding_alias_video_opened"
        }
    }
}
