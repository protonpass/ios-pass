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
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct PasswordHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PasswordHistoryViewModel
    let onCreateLogin: (String) -> Void
    let onCopy: (String) -> Void

    public init(repository: any PasswordHistoryRepositoryProtocol,
                onCreateLogin: @escaping (String) -> Void,
                onCopy: @escaping (String) -> Void) {
        _viewModel = .init(wrappedValue: .init(repository: repository))
        self.onCreateLogin = onCreateLogin
        self.onCopy = onCopy
    }

    public var body: some View {
        ZStack {
            PassColor.backgroundNorm
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
        .navigationBarTitle(Text("Generated passwords", bundle: .module))
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
            CircleButton(icon: IconProvider.chevronDown,
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
                           label: {
                               Label(title: { Text("Clear history", bundle: .module) },
                                     icon: { Image(uiImage: PassIcon.clearHistory) })
                           })
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
                .foregroundStyle(PassColor.textWeak)
                .padding(.bottom)
            twoWeeksNotice(font: .body)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(DesignConstant.sectionPadding)
        .padding(.bottom, 40)
    }

    func twoWeeksNotice(font: Font) -> some View {
        Text("Generated passwords will be stored for 2 weeks.", bundle: .module)
            .font(font)
            .foregroundStyle(PassColor.textWeak)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    var history: some View {
        LazyVStack(spacing: DesignConstant.sectionPadding) {
            ForEach(viewModel.passwords) { password in
                GeneratedPasswordRow(password: password,
                                     onCopy: { handleCopy(for: password) },
                                     onToggleVisibility: { viewModel.toggleVisibility(for: password) },
                                     onCreateLogin: { handleLoginCreation(for: password) },
                                     onRemove: { viewModel.delete(password) })
            }

            twoWeeksNotice(font: .callout)
        }
        .padding(DesignConstant.sectionPadding)
        .scrollViewEmbeded()
    }
}

private extension PasswordHistoryView {
    func handleLoginCreation(for password: GeneratedPasswordUiModel) {
        Task {
            if let clearPassword = await viewModel.getClearPassword(for: password) {
                onCreateLogin(clearPassword)
            }
        }
    }

    func handleCopy(for password: GeneratedPasswordUiModel) {
        Task {
            if let clearPassword = await viewModel.getClearPassword(for: password) {
                onCopy(clearPassword)
            }
        }
    }
}

private struct GeneratedPasswordRow: View {
    let password: GeneratedPasswordUiModel
    let onCopy: () -> Void
    let onToggleVisibility: () -> Void
    let onCreateLogin: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                switch password.visibility {
                case .masked:
                    Text(verbatim: String(repeating: "•", count: 12))
                        .foregroundStyle(PassColor.textNorm)

                case let .unmasked(clearPassword):
                    Text(clearPassword.coloredPassword())
                        .foregroundStyle(PassColor.textNorm)

                case .failedToUnmask:
                    Image(systemName: "exclamationmark.3")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.signalWarning)
                        .frame(width: 24)
                }

                Text(verbatim: password.relativeCreationDate)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: onCopy)

            visibilityButton
            otherOptionsButton
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: password.visibility)
    }

    private var visibilityButton: some View {
        CircleButton(icon: password.visibility.isUnmasked ? IconProvider.eyeSlash : IconProvider.eye,
                     iconColor: PassColor.passwordInteractionNormMajor2,
                     backgroundColor: PassColor.passwordInteractionNormMinor2,
                     accessibilityLabel: password.visibility.isUnmasked ? "Hide password" : "Show password",
                     action: onToggleVisibility)
            .fixedSize(horizontal: true, vertical: true)
    }

    private var otherOptionsButton: some View {
        Menu(content: {
            Button(action: onCopy) {
                Label(title: { Text("Copy password", bundle: .module) },
                      icon: { Image(uiImage: IconProvider.key) })
            }

            Button(action: onCreateLogin) {
                Label(title: { Text("Create login", bundle: .module) },
                      icon: { Image(uiImage: IconProvider.user) })
            }

            Button(action: onRemove) {
                Label(title: { Text("Remove from history", bundle: .module) },
                      icon: { Image(uiImage: IconProvider.trashCross) })
            }
        }, label: {
            CircleButton(icon: IconProvider.threeDotsVertical,
                         iconColor: PassColor.passwordInteractionNormMajor2,
                         backgroundColor: .clear)
        })
    }
}
