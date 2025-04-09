//
// PasswordHistoryView.swift
// Proton Pass - Created on 09/04/2025.
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
//

import Client
import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public struct PasswordHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PasswordHistoryViewModel

    public init(repository: any PasswordHistoryRepositoryProtocol) {
        _viewModel = .init(wrappedValue: .init(repository: repository))
    }

    public var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            if viewModel.loading {
                ProgressView()
            } else if let error = viewModel.error {
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.loadPasswords() } })
            } else if viewModel.passwords.isEmpty {
                noHistory
            } else {
                history
            }
        }
        .animation(.default, value: viewModel.loading)
        .animation(.default, value: viewModel.passwords)
        .animation(.default, value: viewModel.error == nil)
        .toolbar { toolbarContent }
        .navigationBarTitle(Text("Generated passwords", bundle: .module)
            .adaptiveForegroundStyle(PassColor.textNorm.toColor))
        .navigationStackEmbeded()
        .task {
            await viewModel.loadPasswords()
        }
    }
}

private extension PasswordHistoryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.passwordInteractionNormMajor2,
                         backgroundColor: PassColor.passwordInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        if !viewModel.passwords.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button(role: .destructive,
                           action: viewModel.clearHistory,
                           label: { Label("Clear history", uiImage: PassIcon.clearHistory) })
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.passwordInteractionNormMajor2,
                                 backgroundColor: PassColor.passwordInteractionNormMinor1)
                })
            }
        }
    }

    var noHistory: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("No history", bundle: .module)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
            Text("Generated passwords will be stored for a period of 2 weeks.", bundle: .module)
                .foregroundStyle(PassColor.textNorm.toColor)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }

    var history: some View {
        LazyVStack {
            ForEach(viewModel.passwords) { password in
                Text(verbatim: password.relativeCreationDate)
            }
        }
        .scrollViewEmbeded()
    }
}
