//
// LocalAuthenticationView.swift
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

import DesignSystem
import FactoryKit
import ProtonCoreUIFoundations
import SwiftUI

/// Not to be used directly but via `localAuthentication` view modifier
struct LocalAuthenticationView: View {
    @StateObject private var viewModel: LocalAuthenticationViewModel
    private let logOutButtonMode: LogOutButtonMode

    enum LogOutButtonMode {
        case topBarTrailing(onClose: () -> Void)
        case topRight

        var isTopBarTrailing: Bool {
            if case .topBarTrailing = self {
                true
            } else {
                false
            }
        }
    }

    init(mode: LocalAuthenticationViewModel.Mode,
         delayed: Bool = false,
         manuallyAvoidKeyboard: Bool = false,
         logOutButtonMode: LogOutButtonMode = .topRight,
         onAuth: @escaping () -> Void,
         onSuccess: @escaping () async throws -> Void,
         onFailure: @escaping (String?) -> Void) {
        _viewModel = .init(wrappedValue: .init(mode: mode,
                                               delayed: delayed,
                                               manuallyAvoidKeyboard: manuallyAvoidKeyboard,
                                               onAuth: onAuth,
                                               onSuccess: onSuccess,
                                               onFailure: onFailure))
        self.logOutButtonMode = logOutButtonMode
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            switch viewModel.mode {
            case .biometric:
                BiometricAuthenticationView(viewModel: viewModel)
            case .pin:
                PinAuthenticationView(viewModel: viewModel)
            }

            if case .topRight = logOutButtonMode {
                logOutButton
                    .padding()
            }
        }
        .if(logOutButtonMode.isTopBarTrailing) { view in
            view
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CircleButton(icon: IconProvider.cross,
                                     iconColor: PassColor.interactionNormMajor2,
                                     backgroundColor: PassColor.interactionNormMinor1,
                                     accessibilityLabel: "Cancel",
                                     action: {
                                         if case let .topBarTrailing(onClose) = logOutButtonMode {
                                             onClose()
                                         }
                                     })
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        logOutButton
                    }
                }
                .navigationStackEmbeded()
        }
    }
}

private extension LocalAuthenticationView {
    var logOutButton: some View {
        Button { viewModel.logOut() } label: {
            Image(uiImage: IconProvider.arrowOutFromRectangle)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding()
        }
    }
}
