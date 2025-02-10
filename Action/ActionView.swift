//
// ActionView.swift
// Proton Pass - Created on 10/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct ActionView: View {
    @StateObject private var viewModel: ActionViewModel

    init(context: NSExtensionContext?) {
        _viewModel = .init(wrappedValue: .init(context: context))
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea(.all)

            switch viewModel.logins {
            case .fetching:
                ProgressView()

            case let .fetched(logins):
                ImporterView(logManager: viewModel.logManager,
                             users: viewModel.users,
                             logins: logins,
                             proceedImportation: { user, logins in
                                 try await viewModel.proceedImportation(user: user, logins: logins)
                             },
                             onClose: viewModel.dismiss)

            case let .error(error):
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.getUsersAndParseCsv() } })
            }
        }
        .task {
            await viewModel.getUsersAndParseCsv()
        }
        .toolbar {
            if !viewModel.logins.isFetched {
                toolbarContent
            }
        }
        .navigationStackEmbeded()
    }
}

private extension ActionView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: viewModel.dismiss)
        }
    }
}
