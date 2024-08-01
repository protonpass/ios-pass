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
import DesignSystem
import Entities
import Factory
import ProtonCoreKeymaker
import SwiftUI

struct LocalAuthenticationModifier: ViewModifier {
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)

    @State private var authenticated: Bool

    // autolocker as @State because it needs to be updated
    // when user changes appLockTime in setting
    @State private var autolocker: Autolocker

    // When autofill from QuickType bar, we need to wait a bit for the view to be fully loaded
    // Otherwise we would receive error -1004 when calling biometricallyAuthenticate function
    //
    // Error Domain=com.apple.LocalAuthentication Code=-1004
    // "Caller is not running foreground."
    // UserInfo={NSDebugDescription=Caller is not running foreground.,
    // NSLocalizedDescription=User interaction required.}
    private let delayed: Bool

    /// Authentication is started and awaiting for user's response (enterring PIN or biometrically authenticate)
    private let onAuth: (() -> Void)?

    /// Authentication is skipped because threshold is not reached
    private let onAuthSkipped: (() -> Void)?

    /// Authentication succeeded
    private let onSuccess: (() -> Void)?

    /// Authentication failed
    private let onFailure: () -> Void

    private var preferences: SharedPreferences { preferencesManager.sharedPreferences.unwrapped() }

    init(delayed: Bool,
         onAuth: (() -> Void)?,
         onAuthSkipped: (() -> Void)?,
         onSuccess: (() -> Void)?,
         onFailure: @escaping () -> Void) {
        let preferences = preferencesManager.sharedPreferences.unwrapped()
        _authenticated = .init(initialValue: preferences.localAuthenticationMethod == .none)
        _autolocker = .init(initialValue: .init(appLockTime: preferences.appLockTime))
        self.delayed = delayed
        self.onAuth = onAuth
        self.onAuthSkipped = onAuthSkipped
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        autolocker.startCountdown()
    }

    func body(content: Content) -> some View {
        let authenticationRequired = preferences.localAuthenticationMethod != .none && !authenticated
        ZStack {
            content

            if authenticationRequired {
                let handleSuccess: () -> Void = {
                    authenticated = true
                    autolocker.releaseCountdown()
                    onSuccess?()
                }

                LocalAuthenticationView(mode: preferences.localAuthenticationMethod == .pin ? .pin : .biometric,
                                        delayed: delayed,
                                        onAuth: { onAuth?() },
                                        onSuccess: handleSuccess,
                                        onFailure: onFailure)
                    // Set zIndex otherwise animation won't occur
                    // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                    .zIndex(1)
            }
        }
        .animation(.default, value: authenticated)
        .onAppear {
            if !authenticationRequired {
                onAuthSkipped?()
            }
        }
        .onReceive(preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.appLockTime)) { newValue in
                // Take into account right away appLockTime when user updates it
                autolocker = .init(appLockTime: newValue)
                autolocker.startCountdown()
        }
        // Start the timer whenever app is backgrounded
        .onReceive(UIApplication.willResignActiveNotification,
                   perform: autolocker.startCountdown)
        // When app is foregrounded, check if authentication is needed or could be skipped
        .onReceive(UIApplication.didBecomeActiveNotification) {
            if autolocker.shouldAutolockNow(), preferences.localAuthenticationMethod != .none {
                authenticated = false
            } else {
                onAuthSkipped?()
            }
        }
    }
}

extension View {
    @MainActor
    func localAuthentication(delayed: Bool,
                             onAuth: (() -> Void)? = nil,
                             onAuthSkipped: (() -> Void)? = nil,
                             onSuccess: (() -> Void)? = nil,
                             onFailure: @escaping () -> Void) -> some View {
        modifier(LocalAuthenticationModifier(delayed: delayed,
                                             onAuth: onAuth,
                                             onAuthSkipped: onAuthSkipped,
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
