//
// SettingsView.swift
// Proton Pass - Created on 28/09/2022.
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
import SwiftUI
import UIComponents

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            AutoFillSection(viewModel: viewModel)
            BiometricAuthenticationSection(biometricAuthenticator: viewModel.biometricAuthenticator)
            ThemeSection(viewModel: viewModel)
            FullSyncSection(viewModel: viewModel)
            DeleteAccountSection(onDelete: viewModel.deleteAccount)
        }
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
        }

        ToolbarItem(placement: .principal) {
            Text("Settings")
                .fontWeight(.bold)
        }
    }
}

private struct AutoFillSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(content: {
            if viewModel.autoFillEnabled {
                Text("AutoFill is enabled")
            } else {
                Text("AutoFill is disabled")
                    .foregroundColor(.secondary)
            }

            Toggle(isOn: $viewModel.quickTypeBar) {
                Text("QuickType bar suggestions")
            }
            .opacityReduced(!viewModel.autoFillEnabled)
        }, header: {
            Text("AutoFill")
        }, footer: {
            if viewModel.autoFillEnabled {
                // swiftlint:disable:next line_length
                Text("By allowing suggestions on QuickType bar, you can quickly select a matched credential if any without opening the AutoFill extension and manually select one.")
            } else {
                VStack(alignment: .leading) {
                    // swiftlint:disable:next line_length
                    Text("You can enable AutoFill by going to Settings → Passwords → AutoFill Passwords -> Select Proton Pass.")
                    Button(action: UIApplication.shared.openPasswordSettings) {
                        Text("Open Settings")
                            .font(.caption)
                    }
                    .foregroundColor(.interactionNorm)
                }
            }
        })
    }
}

private struct BiometricAuthenticationSection: View {
    @ObservedObject var biometricAuthenticator: BiometricAuthenticator

    var body: some View {
        Section(content: {
            switch biometricAuthenticator.biometryTypeState {
            case .idle, .initializing:
                ProgressView()
            case .initialized(let biometryType):
                view(for: biometryType)
            case .error(let error):
                Text(error.localizedDescription)
            }
        }, header: {
            Text("Biometric authentication")
        })
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

private struct ThemeSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section {
            if #unavailable(iOS 16.0) {
                HStack {
                    Text("Theme")
                    Spacer()
                    Label(title: {
                        Text(viewModel.theme.description)
                    }, icon: {
                        Image(uiImage: viewModel.theme.icon)
                    })
                    .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 16)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .onTapGesture(perform: viewModel.changeTheme)
            } else {
                Picker("Theme", selection: $viewModel.theme) {
                    ForEach(Theme.allCases, id: \.rawValue) { theme in
                        HStack {
                            Label(title: {
                                Text(theme.description)
                            }, icon: {
                                Image(uiImage: theme.icon)
                            })
                        }
                        .tag(theme)
                    }
                }
            }
        }
    }
}

private struct FullSyncSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(content: {
            Button(action: viewModel.fullSync) {
                Text("Trigger a full synchronization")
            }
            .foregroundColor(.interactionNorm)
        }, header: {
            Text("Full synchronization")
        }, footer: {
            Text("Download all your items again to make sure you are in sync.")
        })
    }
}

private struct DeleteAccountSection: View {
    let onDelete: (() -> Void)

    var body: some View {
        Section {
            Button(action: onDelete) {
                Text("Delete account")
                    .foregroundColor(.red)
            }
        }
    }
}
