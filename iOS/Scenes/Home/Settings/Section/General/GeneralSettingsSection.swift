//
// GeneralSettingsSection.swift
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

import SwiftUI

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(content: {
            SecurityRow(viewModel: viewModel)
            DefaultBrowserRow(viewModel: viewModel)
            AutoFillRow(viewModel: viewModel)
        }, header: {
            Text("General")
        }, footer: {
            if !viewModel.autoFillEnabled {
                Text("Set Proton Pass as AutoFill provider to automatically fill in your usernames and passwords.")
            }
        })
    }
}

private struct SecurityRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button(action: viewModel.openSecuritySettings) {
            HStack {
                Text("Security")
                Spacer()
                ChevronRight()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct DefaultBrowserRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button(action: viewModel.updateDefaultBrowser) {
            HStack {
                Text("Default browser")
                Spacer()
                Text(viewModel.browser.description)
                    .foregroundColor(.secondary)
                ChevronRight()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AutoFillRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Button(action: viewModel.updateAutoFill) {
            HStack {
                Text("AutoFill")
                Spacer()
                Text(viewModel.autoFillEnabled ? "On" : "Off")
                    .foregroundColor(.secondary)
                ChevronRight()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
