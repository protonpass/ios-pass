//
// SecuritySettingsView.swift
// Proton Pass - Created on 25/12/2022.
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
import LocalAuthentication
import ProtonCore_UIFoundations
import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onGoBack: () -> Void

    var body: some View {
        Form {
            BiometricAuthenticationSection(biometricAuthenticator: viewModel.biometricAuthenticator)
            ClipboardSection(viewModel: viewModel)
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("Security")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onGoBack) {
                    Image(uiImage: IconProvider.chevronLeft)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

private struct BiometricAuthenticationSection: View {
    @ObservedObject var biometricAuthenticator: BiometricAuthenticator

    var body: some View {
        Section {
            switch biometricAuthenticator.biometryTypeState {
            case .idle, .initializing:
                ProgressView()
            case .initialized(let biometryType):
                view(for: biometryType)
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
    }

    @ViewBuilder
    private func view(for biometryType: LABiometryType) -> some View {
        if let uiModel = biometryType.uiModel {
            Toggle(isOn: $biometricAuthenticator.enabled) {
                Label(title: {
                    Text(uiModel.title)
                }, icon: {
                    if let icon = uiModel.icon {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                    } else {
                        EmptyView()
                    }
                })
            }
        } else {
            Text("Not supported")
        }
    }
}

private struct ClipboardSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(content: {
            HStack {
                Button(action: viewModel.updateClipboardExpiration) {
                    HStack {
                        Text("Clear clipboard")
                        Spacer()
                        Text(viewModel.clipboardExpiration.description)
                            .foregroundColor(.secondary)
                        ChevronRight()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: $viewModel.shareClipboard) {
                Text("Share clipboard between devices")
            }
        }, header: {
            Text("Clipboard")
        })
    }
}
