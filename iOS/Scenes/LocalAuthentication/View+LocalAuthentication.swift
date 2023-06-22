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

import Core
import SwiftUI

enum LocalAuthenticationType {
    case biometric, pin
}

enum LocalAuthenticationRequirement {
    case required(LocalAuthenticationType)
    case notRequired
}

struct LocalAuthenticationModifier: ViewModifier {
    @State private var authenticated = false
    let preferences: Preferences
    let logManager: LogManager
    let onSuccess: () -> Void
    let onFailure: () -> Void

    func body(content: Content) -> some View {
        if preferences.biometricAuthenticationEnabled {
            ZStack {
                content
                if !authenticated {
                    LocalAuthenticationView(viewModel:
                            .init(type: .biometric,
                                  preferences: preferences,
                                  logManager: logManager,
                                  onSuccess: { authenticated = true; onSuccess() },
                                  onFailure: onFailure))
                    // Set zIndex otherwise animation won't occur
                    // https://sarunw.com/posts/how-to-fix-zstack-transition-animation-in-swiftui/
                    .zIndex(1)
                }
            }
            .animation(.default, value: authenticated)
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
