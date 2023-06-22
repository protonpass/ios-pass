//
// View+LocalAuthentication.swift
// Proton Pass - Created on 22/06/2023.
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

import Combine
import Core
import ProtonCore_Keymaker
import SwiftUI

enum LocalAuthenticationType {
    case biometric, pin
}

struct LocalAuthenticationModifier: ViewModifier {
    @State private var shouldLock: Bool
    @State private var autolocker: Autolocker
    @ObservedObject private var preferences: Preferences
    private let logManager: LogManager
    private let onSuccess: () -> Void
    private let onFailure: () -> Void

    init(preferences: Preferences,
         logManager: LogManager,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        self.shouldLock = preferences.biometricAuthenticationEnabled
        self._autolocker = .init(initialValue: .init(appLockTime: preferences.appLockTime))
        self._preferences = .init(initialValue: preferences)
        self.logManager = logManager
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func body(content: Content) -> some View {
        if preferences.biometricAuthenticationEnabled {
            ZStack {
                content
                if shouldLock {
                    let handleSuccess: () -> Void = {
                        shouldLock = false
                        autolocker.releaseCountdown()
                        onSuccess()
                    }

                    LocalAuthenticationView(type: .biometric,
                                            preferences: preferences,
                                            logManager: logManager,
                                            onSuccess: handleSuccess,
                                            onFailure: onFailure)
                    // Set zIndex otherwise animation won't occur
                    // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                    .zIndex(1)
                }
            }
            .animation(.default, value: shouldLock)
            .onChange(of: preferences.appLockTime) { newAppLockTime in
                // Take into account right away appLockTime when user updates it
                autolocker = .init(appLockTime: newAppLockTime)
            }
            .onReceive(UIApplication.willResignActiveNotification,
                       perform: autolocker.startCountdown)
            // Check if we should lock the app base on 2 notifications
            // willEnterForegroundNotification & didBecomeActiveNotification
            //
            // "Fully backgrounded" means the user quickly swipes up and is back to iOS's home screen
            // "Not fully backgrounded" means the user is slowly wipe up & see the stack of running apps
            //
            // If we only check on willEnterForegroundNotification
            // the app would not be locked when it's not fully backgrounded
            //
            // If we only check on didBecomeActiveNotification
            // the app would be locked a bit late when it's fully backgrounded
            // which makes the content of the app visible for a fraction of second
            // that's not what we want
            .onReceive(UIApplication.willEnterForegroundNotification) {
                shouldLock = autolocker.shouldAutolockNow()
            }
            .onReceive(UIApplication.didBecomeActiveNotification) {
                shouldLock = autolocker.shouldAutolockNow()
            }
        } else {
            content
        }
    }
}

extension View {
    func localAuthentication(preferences: Preferences,
                             logManager: LogManager,
                             onSuccess: @escaping () -> Void,
                             onFailure: @escaping () -> Void) -> some View {
        modifier(LocalAuthenticationModifier(preferences: preferences,
                                             logManager: logManager,
                                             onSuccess: onSuccess,
                                             onFailure: onFailure))
    }
}

private extension Autolocker {
    convenience init(appLockTime: AppLockTime) {
        struct AutolockerSettingsProvider: SettingsProvider {
            let appLockTime: AppLockTime
            var lockTime: AutolockTimeout {
                if let intervalInMinutes = appLockTime.intervalInMinutes {
                    return .minutes(intervalInMinutes)
                } else {
                    return .never
                }
            }
        }
        self.init(lockTimeProvider: AutolockerSettingsProvider(appLockTime: appLockTime))
    }
}
