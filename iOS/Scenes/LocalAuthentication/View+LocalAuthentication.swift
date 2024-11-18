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

extension Notification.Name {
    static let lockAppToRemoveLocalAuth = Notification.Name(rawValue: "lockAppToRemoveLocalAuth")
    static let lockAppToDefinePIN = Notification.Name(rawValue: "lockAppToDefinePIN")
    static let recordLastActiveTimestamp = Notification.Name(rawValue: "recordLastActiveTimestamp")
}

enum LocalAuthenticationSuccessMode {
    case none
    case definePIN
    case removeLocalAuth

    static var `default`: Self { .none }
}

struct LocalAuthenticationModifier: ViewModifier {
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)

    @State private var method: LocalAuthenticationMethod
    @State private var authenticated: Bool

    // autolocker as @State because it needs to be updated
    // when user changes appLockTime in setting
    @State private var autolocker: Autolocker

    @State private var successMode: LocalAuthenticationSuccessMode = .default

    // When autofill from QuickType bar, we need to wait a bit for the view to be fully loaded
    // Otherwise we would receive error -1004 when calling biometricallyAuthenticate function
    //
    // Error Domain=com.apple.LocalAuthentication Code=-1004
    // "Caller is not running foreground."
    // UserInfo={NSDebugDescription=Caller is not running foreground.,
    // NSLocalizedDescription=User interaction required.}
    private let delayed: Bool

    private let manuallyAvoidKeyboard: Bool
    private let logOutButtonMode: LocalAuthenticationView.LogOutButtonMode

    /// Authentication is started and awaiting for user's response (enterring PIN or biometrically authenticate)
    private let onAuth: (() -> Void)?

    /// Authentication is skipped because threshold is not reached
    private let onAuthSkipped: (() -> Void)?

    /// Authentication succeeded
    private let onSuccess: ((LocalAuthenticationSuccessMode) -> Void)?

    /// Authentication failed
    private let onFailure: (String?) -> Void

    private let checkForAuthenticationSubject = PassthroughSubject<Void, Never>()

    init(delayed: Bool,
         manuallyAvoidKeyboard: Bool,
         logOutButtonMode: LocalAuthenticationView.LogOutButtonMode,
         onAuth: (() -> Void)?,
         onAuthSkipped: (() -> Void)?,
         onSuccess: ((LocalAuthenticationSuccessMode) -> Void)?,
         onFailure: @escaping (String?) -> Void) {
        let preferences = preferencesManager.sharedPreferences.unwrapped()
        _method = .init(initialValue: preferences.localAuthenticationMethod)
        _authenticated = .init(initialValue: preferences.localAuthenticationMethod == .none)
        _autolocker = .init(initialValue: .init(appLockTime: preferences.appLockTime))
        self.delayed = delayed
        self.manuallyAvoidKeyboard = manuallyAvoidKeyboard
        self.logOutButtonMode = logOutButtonMode
        self.onAuth = onAuth
        self.onAuthSkipped = onAuthSkipped
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        autolocker.startCountdown()
    }

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .overlay {
            if !authenticated, method != .none {
                let handleSuccess: () -> Void = {
                    authenticated = true
                    autolocker.releaseCountdown()
                    onSuccess?(successMode)
                    successMode = .default
                }

                LocalAuthenticationView(mode: method == .pin ? .pin : .biometric,
                                        delayed: delayed,
                                        manuallyAvoidKeyboard: manuallyAvoidKeyboard,
                                        logOutButtonMode: logOutButtonMode,
                                        onAuth: { onAuth?() },
                                        onSuccess: handleSuccess,
                                        onFailure: onFailure)
            }
        }
        .animation(.default, value: authenticated)
        .onAppear {
            checkForAuthenticationSubject.send()
        }
        // Take into account right away appLockTime when user updates it
        .onReceive(preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.appLockTime)) { newValue in
                autolocker = .init(appLockTime: newValue)
                autolocker.startCountdown()
        }
        // Take into account right away method when user updates it
        .onReceive(preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.localAuthenticationMethod)) { newValue in
                method = newValue
        }
        // Start the timer whenever app is backgrounded
        .onReceive(UIApplication.willResignActiveNotification, perform: autolocker.startCountdown)
        .onReceive(foregroundEventsPublisher) {
            checkForAuthenticationSubject.send()
        }
        .onReceive(checkForAuthenticationSubject.debounce(for: 0.2, scheduler: DispatchQueue.main)) {
            checkForAuthentication()
        }
        .onReceive(.lockAppToDefinePIN) {
            successMode = .definePIN
            authenticated = false
        }
        .onReceive(.lockAppToRemoveLocalAuth) {
            successMode = .removeLocalAuth
            authenticated = false
        }
        .onReceive(.recordLastActiveTimestamp) {
            Task {
                do {
                    let timestamp = authenticated ? Date.now.timeIntervalSince1970 : nil
                    try await preferencesManager.updateSharedPreferences(\.lastActiveTimestamp,
                                                                         value: timestamp)
                } catch {
                    #if DEBUG
                    print(error.localizedDescription)
                    #endif
                }
            }
        }
    }
}

private extension LocalAuthenticationModifier {
    // Different events could be triggered when app is foregrounded
    // depending on context (app is fully backgrounded or just moved to app switch menu)
    // so we listen to all of them
    @MainActor
    var foregroundEventsPublisher: AnyPublisher<Void, Never> {
        let center = NotificationCenter.default
        let willEnterForeground = center.publisher(for: UIApplication.willEnterForegroundNotification)
        let didBecomeActive = center.publisher(for: UIApplication.didBecomeActiveNotification)
        return Publishers.Merge(willEnterForeground, didBecomeActive)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func checkForAuthentication() {
        if method == .none {
            onAuthSkipped?()
        } else if autolocker.shouldAutolockNow() {
            authenticated = false
        } else if authenticated {
            onAuthSkipped?()
        }
    }
}

extension View {
    @MainActor
    func localAuthentication(delayed: Bool = false,
                             manuallyAvoidKeyboard: Bool = false,
                             logOutButtonMode: LocalAuthenticationView.LogOutButtonMode = .topRight,
                             onAuth: (() -> Void)? = nil,
                             onAuthSkipped: (() -> Void)? = nil,
                             onSuccess: ((LocalAuthenticationSuccessMode) -> Void)? = nil,
                             onFailure: @escaping (String?) -> Void) -> some View {
        modifier(LocalAuthenticationModifier(delayed: delayed,
                                             manuallyAvoidKeyboard: manuallyAvoidKeyboard,
                                             logOutButtonMode: logOutButtonMode,
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
            var lockTime: AutolockTimeout { .minutes(appLockTime.intervalInMinutes) }
        }
        self.init(lockTimeProvider: AutolockerSettingsProvider(appLockTime: appLockTime))
    }
}
