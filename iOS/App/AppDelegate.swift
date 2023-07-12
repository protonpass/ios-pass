//
// AppDelegate.swift
// Proton Pass - Created on 01/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import Factory
import ProtonCore_CryptoGoImplementation
import ProtonCore_CryptoGoInterface
import Sentry
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        injectDefaultCryptoImplementation()
        setUpSentry()
        setUpDefaultValuesForSettingsBundle()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

private extension AppDelegate {
    func setUpSentry() {
        SentrySDK.start { options in
            options.dsn = Bundle.main.plistString(for: .sentryDSN, in: .prod)
            if ProcessInfo.processInfo.environment["me.proton.pass.SentryDebug"] == "1" {
                options.debug = true
            }
            options.enableAppHangTracking = true
            options.enableFileIOTracking = true
            options.enableCoreDataTracking = true
            options.attachViewHierarchy = true // EXPERIMENTAL
        }
    }

    func setUpDefaultValuesForSettingsBundle() {
        let appVersionKey = "pref_app_version"
        kSharedUserDefaults.register(defaults: [appVersionKey: "-"])
        kSharedUserDefaults.set(Bundle.main.displayedAppVersion, forKey: appVersionKey)
    }
}
