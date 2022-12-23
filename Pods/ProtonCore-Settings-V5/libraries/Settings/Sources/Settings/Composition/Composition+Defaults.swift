//
//  Composition+Defaults.swift
//  ProtonCore-Settings - Created on 24.09.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

@available(iOSApplicationExtension, unavailable)
public extension PMSettingsSectionViewModel {
    static var systemSettings: PMSettingsSectionViewModel {
        PMSettingsSectionBuilder(bundle: PMSettings.bundle)
            .title("pmsettings-settings-system-settings-section")
            .appendRow(PMSystemSettingConfiguration.language)
            .appendRow(PMSystemSettingConfiguration.notifications)
            .build()
    }

    static func appSettings(with locker: Locker) -> PMSettingsSectionViewModel {
        PMSettingsSectionBuilder(bundle: PMSettings.bundle)
            .title("pmsettings-settings-app-settings-section")
            .appendRow(PMPinFaceIDDrillDownCellConfiguration.security(locker: locker))
            .build()
    }

    static var about: PMSettingsSectionViewModel {
        PMSettingsSectionBuilder(bundle: PMSettings.bundle)
            .title("pmsettings-settings-about-section")
            .appendRow(PMAboutConfiguration.privacy)
            .appendRow(PMAboutConfiguration.terms)
            .build()
    }
    
    @available(iOS 13.0, *)
    static func telemetry(delegate: TelemetrySettingsDelegate, telemetrySettingsService: TelemetrySettingsServiceProtocol) -> PMSettingsSectionViewModel {
        PMSettingsSectionBuilder(bundle: PMSettings.bundle)
            .title("Telemetry")
            .appendRow(PMSwitchSecurityCellConfiguration.telemetry(
                delegate: delegate,
                telemetrySettingsService: telemetrySettingsService
            ))
            .build()
    }
}

public extension PMPinFaceIDDrillDownCellConfiguration {
    static func security(locker: Locker) -> PMPinFaceIDDrillDownCellConfiguration {
        let vcProvider = {
            SecuritySettingsAssembler.assemble(locker: locker)
        }
        return PMPinFaceIDDrillDownCellConfiguration(
            lockReader: locker,
            biometryType: .currentType,
            action: vcProvider)
    }
}

@available(iOSApplicationExtension, unavailable)
public extension PMSystemSettingConfiguration {
    static var language: PMSystemSettingConfiguration {
        PMSystemSettingConfiguration(title: "pmsettings-settings-system-settings-language-title",
                                     description: "pmsettings-settings-system-settings-language-description",
                                     buttonText: "pmsettings-settings-system-settings-language-button",
                                     action: .perform(openSystemSettings),
                                     bundle: PMSettings.bundle)
    }

    static var notifications: PMSystemSettingConfiguration {
        PMSystemSettingConfiguration(title: "pmsettings-settings-system-settings-notifications-title",
                                     description: "pmsettings-settings-system-settings-notifications-description",
                                     buttonText: "pmsettings-settings-system-settings-notifications-button",
                                     action: .perform(openSystemSettings),
                                     bundle: PMSettings.bundle)
    }

    static func openSystemSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}
