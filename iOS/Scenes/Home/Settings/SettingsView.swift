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
import SwiftUI
import UIComponents

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            GeneralSettingsSection(viewModel: viewModel)
            ThemeSection(viewModel: viewModel)
            ApplicationSection(viewModel: viewModel)
            DeleteAccountSection(onDelete: viewModel.deleteAccount)
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ToggleSidebarButton(action: viewModel.toggleSidebar)
            }
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
                    ChevronRight()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: viewModel.updateTheme)
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
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ApplicationSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(content: {
            Button(action: viewModel.viewLogs) {
                Text("View logs")
            }
            .foregroundColor(.interactionNorm)

            Button(action: viewModel.fullSync) {
                Text("Force synchronization")
            }
            .foregroundColor(.interactionNorm)
        }, header: {
            Text("Application")
        }, footer: {
            Text("Download all your items again to make sure you are in sync.")
        })
    }
}

private struct DeleteAccountSection: View {
    let onDelete: (() -> Void)

    var body: some View {
        Section(content: {
            Button(action: onDelete) {
                Text("Delete account")
                    .foregroundColor(.red)
            }
        }, footer: {
            // swiftlint:disable:next line_length
            Text("This will permanently delete your account and all of its data. You will not be able to reactivate this account.")
        })
    }
}

struct ChevronRight: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .resizable()
            .scaledToFit()
            .frame(height: 16)
            .foregroundColor(Color(.tertiaryLabel))
    }
}
