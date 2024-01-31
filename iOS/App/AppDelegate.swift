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
import Client
import Core
import Factory
import ProtonCoreCryptoGoImplementation
import ProtonCoreCryptoGoInterface
import ProtonCoreLog
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let getRustLibraryVersion = resolve(\UseCasesContainer.getRustLibraryVersion)
    private let setUpSentry = resolve(\SharedUseCasesContainer.setUpSentry)

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        injectDefaultCryptoImplementation()
        setUpSentry(bundle: .main)
        setUpDefaultValuesForSettingsBundle()
        configureCoreLogger()
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

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Woot url: \(url)")
        if let otpAuth = parseOTPAuthURL(url) {
            // Handle the parsed OTPAuth details
            // E.g., Pass to a view controller, store securely, etc.
            print("Secret: \(otpAuth.secret)")
        }
        return true
    }

    func parseOTPAuthURL(_ url: URL) -> OTPAuth? {
        guard url.scheme == "otpauth" else { return nil }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let secret = queryItems?.first(where: { $0.name == "secret" })?.value
        let issuer = queryItems?.first(where: { $0.name == "issuer" })?.value
        let accountName = url.host // or extract from the URL path

        if let secret {
            return OTPAuth(secret: secret, issuer: issuer, accountName: accountName)
        } else {
            return nil
        }
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

    private func setUserDefaultsIfUITestsRunning() {
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
}

struct OTPAuth {
    let secret: String
    let issuer: String?
    let accountName: String?
    // Add other fields as needed
}
