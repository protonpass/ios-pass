//
// ImporterView.swift
// Proton Pass - Created on 05/02/2025.
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

import Core
import DesignSystem
import Entities
import Macro
import ProtonCoreLogin
import ProtonCoreUIFoundations
import SwiftUI

public struct ImporterView: View {
    @StateObject private var viewModel: ImporterViewModel
    private let onClose: () -> Void

    public init(logManager: any LogManagerProtocol,
                users: [UserUiModel],
                logins: [CsvLogin],
                proceedImportation: @escaping (UserUiModel?, [CsvLogin]) async throws -> Void,
                onClose: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(logManager: logManager,
                                               users: users,
                                               logins: logins,
                                               proceedImportation: proceedImportation))
        self.onClose = onClose
    }

    public var body: some View {
        ScrollView {
            LazyVStack {
                if viewModel.users.count > 1 {
                    UserAccountSelectionMenu(selectedUser: $viewModel.selectedUser,
                                             users: viewModel.users,
                                             allowNoSelection: false)
                        .padding(.horizontal)
                }
                ForEach(viewModel.logins) { login in
                    LoginRow(login: login,
                             isSelected: viewModel.isSelected(login),
                             onTap: { viewModel.toggleSelection(login) })
                        .padding([.horizontal, .top])
                }
            }
        }
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .fullSheetBackground()
        .showSpinner(viewModel.importing)
        .navigationStackEmbeded()
        .alert("Succesful import",
               isPresented: $viewModel.importSuccessMessage.mappedToBool(),
               actions: { Button("OK", action: onClose) },
               message: {
                   if let message = viewModel.importSuccessMessage {
                       Text(message)
                   }
               })
        .alert("Error occurred",
               isPresented: $viewModel.error.mappedToBool(),
               actions: { Button("OK", action: onClose) },
               message: {
                   if let error = viewModel.error {
                       Text(error.localizedDescription)
                   }
               })
    }
}

private extension ImporterView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: onClose)
        }

        ToolbarItem(placement: .principal) {
            Text(#localized("Import logins (%1$lld/%2$lld)",
                            viewModel.selectedCount,
                            viewModel.logins.count))
                .navigationTitleText()
                .monospacedDigit()
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Import"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.loginInteractionNormMajor1,
                                        disableBackgroundColor: PassColor.loginInteractionNormMinor1,
                                        disabled: viewModel.selectedCount <= 0 || viewModel.importing,
                                        action: viewModel.startImporting)
        }
    }
}

private struct LoginRow: View {
    let login: CsvLogin
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            SquircleThumbnail(data: .initials(login.initials),
                              tintColor: PassColor.loginInteractionNormMajor2,
                              backgroundColor: PassColor.loginInteractionNormMinor1,
                              height: 40)

            VStack(alignment: .leading) {
                Text(login.name)
                    .lineLimit(2)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(login.emailOrUsername)
                    .lineLimit(2)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
                    .foregroundStyle(PassColor.loginInteractionNormMajor2.toColor)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: isSelected)
        .buttonEmbeded(action: onTap)
    }
}

private extension CsvLogin {
    var emailOrUsername: String {
        email.isEmpty ? username : email
    }

    var initials: String {
        let nameInitials = name.initials()
        return nameInitials.isEmpty ? emailOrUsername.initials() : nameInitials
    }
}
