//
// CredentialsSection.swift
// Proton Pass - Created on 29/07/2024.
// Copyright (c) 2024 Proton Technologies AG
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

@_spi(QA)
import Client
import FactoryKit
import SwiftUI

struct CredentialsSection: View {
    var body: some View {
        NavigationLink(destination: { CredentialsView() },
                       label: { Text(verbatim: "Credentials") })
    }
}

private struct CredentialsView: View {
    @StateObject private var viewModel = CredentialsViewModel()

    var body: some View {
        Form {
            ForEach(viewModel.groupedCreds.sorted(by: ==), id: \.key) { userName, creds in
                Section(content: {
                    ForEach(creds, id: \.module) { cred in
                        VStack(alignment: .leading) {
                            Text(verbatim: cred.module.rawValue)
                            Group {
                                Text(verbatim: "Session: " + cred.credential.UID)
                                Text(verbatim: "Access: " + cred.credential.accessToken)
                                Text(verbatim: "Refresh: " + cred.credential.refreshToken)
                            }
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }, header: {
                    Text(verbatim: userName.isEmpty ? "<Unauth>" : userName)
                })
            }
        }
        .navigationTitle(Text(verbatim: "Credentials (\(viewModel.groupedCreds.keys.count))"))
    }
}

private final class CredentialsViewModel: ObservableObject {
    /// Credentials grouped by username
    @Published private(set) var groupedCreds: [String: [Credentials]] = [:]

    private let authManager = resolve(\SharedToolingContainer.authManager)

    init() {
        let credentials = (authManager as? AuthManager)?.getAllCredentialsOfAllModules() ?? []
        groupedCreds = Dictionary(grouping: credentials, by: { $0.credential.userName })
    }
}
