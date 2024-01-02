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
import DesignSystem
import Factory
import ProtonCoreKeymaker
import SwiftUI

struct LocalAuthenticationModifier: ViewModifier {
    @State private var authenticated: Bool

    // autolocker as @State because it needs to be updated
    // when user changes appLockTime in setting
    @State private var autolocker: Autolocker

    @ObservedObject private var preferences: Preferences

    // When autofill from QuickType bar, we need to wait a bit for the view to be fully loaded
    // Otherwise we would receive error -1004 when calling biometricallyAuthenticate function
    //
    // Error Domain=com.apple.LocalAuthentication Code=-1004
    // "Caller is not running foreground."
    // UserInfo={NSDebugDescription=Caller is not running foreground.,
    // NSLocalizedDescription=User interaction required.}
    private let delayed: Bool

    private let onAuth: () -> Void
    private let onSuccess: () -> Void
    private let onFailure: () -> Void

    init(delayed: Bool,
         onAuth: @escaping () -> Void,
         onSuccess: @escaping () -> Void,
         onFailure: @escaping () -> Void) {
        let preferences = resolve(\SharedToolingContainer.preferences)
        authenticated = preferences.localAuthenticationMethod == .none
        _autolocker = .init(initialValue: .init(appLockTime: preferences.appLockTime))
        _preferences = .init(initialValue: preferences)
        self.delayed = delayed
        self.onAuth = onAuth
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        autolocker.startCountdown()
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            if preferences.localAuthenticationMethod != .none, !authenticated {
                let handleSuccess: () -> Void = {
                    authenticated = true
                    autolocker.releaseCountdown()
                    onSuccess()
                }

                LocalAuthenticationView(mode: preferences.localAuthenticationMethod == .pin ? .pin : .biometric,
                                        delayed: delayed,
                                        onAuth: onAuth,
                                        onSuccess: handleSuccess,
                                        onFailure: onFailure)
                    // Set zIndex otherwise animation won't occur
                    // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                    .zIndex(1)
            }
        }
        .animation(.default, value: authenticated)
        .onChange(of: preferences.appLockTime) { newAppLockTime in
            // Take into account right away appLockTime when user updates it
            autolocker = .init(appLockTime: newAppLockTime)
            autolocker.startCountdown()
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
            if autolocker.shouldAutolockNow() {
                authenticated = false
            }
        }
        .onReceive(UIApplication.didBecomeActiveNotification) {
            if autolocker.shouldAutolockNow() {
                authenticated = false
            }
        }
    }
}

extension View {
    @MainActor
    func localAuthentication(delayed: Bool,
                             onAuth: @escaping () -> Void,
                             onSuccess: @escaping () -> Void,
                             onFailure: @escaping () -> Void) -> some View {
        modifier(LocalAuthenticationModifier(delayed: delayed,
                                             onAuth: onAuth,
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
                    .minutes(intervalInMinutes)
                } else {
                    .never
                }
            }
        }
        self.init(lockTimeProvider: AutolockerSettingsProvider(appLockTime: appLockTime))
    }
}
