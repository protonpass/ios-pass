//
// BiometricAuthenticationView.swift
// Proton Pass - Created on 18/08/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import SwiftUI

struct BiometricAuthenticationView: View {
    @Bindable var viewModel: LocalAuthenticationViewModel

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()

                passLogo

                switch viewModel.state {
                case .noAttempts:
                    if viewModel.promptDismissed {
                        Text("Please authenticate", bundle: .module)
                            .foregroundStyle(PassColor.textNorm)
                        retryButton
                            .padding(.top)
                    }

                case .lastAttempt:
                    Text("This is your last attempt. You will be logged out after failing to authenticate again.",
                         bundle: .module)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PassColor.textNorm)
                    retryButton
                        .padding(.top)

                case let .remainingAttempts(count):
                    Text("\(count) remaining attempt(s)", bundle: .module)
                        .foregroundStyle(PassColor.textNorm)
                    retryButton
                        .padding(.top)

                case .exhausted:
                    EmptyView()
                }

                Spacer()
                    .frame(height: proxy.size.height / 2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                guard case .noAttempts = viewModel.state else {
                    return
                }
                guard await (try? Task.sleep(for: viewModel.delayedTime)) != nil else { return }
                viewModel.onAuth()
                viewModel.biometricallyAuthenticate()
            }
        }
    }
}

private extension BiometricAuthenticationView {
    var passLogo: some View {
        PassIcon.passIcon
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 160)
    }

    var retryButton: some View {
        Button(action: viewModel.biometricallyAuthenticate) {
            Text("Try again", bundle: .module)
                .foregroundStyle(PassColor.interactionNormMajor2)
        }
    }
}
