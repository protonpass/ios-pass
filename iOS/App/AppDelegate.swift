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

import BackgroundTasks
import Core
import Factory
import ProtonCoreCryptoGoImplementation
import ProtonCoreCryptoGoInterface
import ProtonCoreLog
import TipKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let getRustLibraryVersion = resolve(\UseCasesContainer.getRustLibraryVersion)
    private let setUpSentry = resolve(\SharedUseCasesContainer.setUpSentry)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let userDefaults: UserDefaults = .standard

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        injectDefaultCryptoImplementation()
        setUpSentry(bundle: .main)
        setUpDefaultValuesForSettingsBundle()
        configureCoreLogger()
        configureTipKit()
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
    private func configureCoreLogger() {
        let environment = ProtonPassDoH(bundle: .main).environment.name
        PMLog.setEnvironment(environment: environment)
    }

    func setUpDefaultValuesForSettingsBundle() {
        let appVersionKey = "pref_app_version"
        kSharedUserDefaults.register(defaults: [appVersionKey: "-"])
        kSharedUserDefaults.set(Bundle.main.displayedAppVersion, forKey: appVersionKey)

        let rustVersionKey = "pref_rust_version"
        kSharedUserDefaults.register(defaults: [rustVersionKey: "-"])
        kSharedUserDefaults.set(getRustLibraryVersion(), forKey: rustVersionKey)

        setUserDefaultsIfUITestsRunning()
    }

    func setUserDefaultsIfUITestsRunning() {
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            UIView.setAnimationsEnabled(false)
            if ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"] != "" {
                let envDomain = ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"]
                let envName = String(envDomain?.split(separator: ".")[0] ?? "")

                kSharedUserDefaults.setValue("scientist", forKey: "pref_environment")
                kSharedUserDefaults.setValue(envName, forKey: "pref_scientist_env_name")
            }
        }
    }

    func configureTipKit() {
        guard #available(iOS 17, *) else { return }
        do {
            if !userDefaults.bool(forKey: Constants.QA.enableTips) {
                Tips.hideAllTipsForTesting()
            }

            if userDefaults.bool(forKey: Constants.QA.forceShowTips) {
                Tips.showAllTipsForTesting()
            }

            if userDefaults.bool(forKey: Constants.QA.resetTipsStateOnLaunch) {
                try Tips.resetDatastore()
            }

            try Tips.configure([
                .datastoreLocation(.groupContainer(identifier: Constants.appGroup)),
                // Show eligible tips right away for QA builds
                // Only show 1 tip per day for normal builds
                .displayFrequency(Bundle.main.isQaBuild ? .immediate : .daily)
            ])
        } catch {
            logger.error(error)
        }
    }
}
