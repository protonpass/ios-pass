//
// CxpImportView.swift
// Proton Pass - Created on 02/10/2026.
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
import Entities
import Macro
import SwiftUI

public struct CxpImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CxpImportViewModel
    private let onSuccess: () -> Void

    public init(result: CxpImportResult, onSuccess: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(result: result))
        self.onSuccess = onSuccess
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    summary
                    footer
                    Spacer()
                    actionButtons
                }
                .frame(minHeight: geometry.size.height)
            }
            .frame(width: geometry.size.width)
            .opacity(viewModel.importSuccessMessage == nil ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.importedCount)
        .alert(Text("Imported successfully", bundle: .module),
               isPresented: $viewModel.importSuccessMessage.mappedToBool(),
               actions: {
                   Button(action: {
                       onSuccess()
                       dismiss()
                   }, label: { Text("OK", bundle: .module) })
               },
               message: {
                   if let message = viewModel.importSuccessMessage {
                       Text(verbatim: message)
                   }
               })
        .alert(Text("Error occurred", bundle: .module),
               isPresented: $viewModel.errorMessage.mappedToBool(),
               actions: {
                   Button(action: {
                       // Some vaults may already be imported
                       onSuccess()
                       dismiss()
                   }, label: { Text("OK", bundle: .module) })
               },
               message: {
                   if let message = viewModel.errorMessage {
                       Text(verbatim: message)
                   }
               })
        .idleTimerDisabled(viewModel.importing)
        .task { await viewModel.loadUsers() }
    }
}

private extension CxpImportView {
    var header: some View {
        VStack(spacing: 24) {
            PassIcon.passIcon
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Import items\nfrom \(viewModel.exporterName)", bundle: .module)
                .font(.title2.bold())
                .foregroundStyle(PassColor.textNorm)
                .multilineTextAlignment(.center)

            if viewModel.hasMultipleAccounts {
                UserAccountSelectionMenu(selectedUser: $viewModel.selectedUser,
                                         users: viewModel.users,
                                         allowNoSelection: false,
                                         alignment: .center)
                    .disabled(viewModel.importing)
            }
        }
    }

    var summary: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.rows) { row in
                HStack {
                    Text(verbatim: row.category.title)
                        .foregroundStyle(PassColor.textNorm)
                    Spacer()
                    Text(verbatim: "\(row.total)")
                        .foregroundStyle(PassColor.textWeak)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)

                if row.id != viewModel.rows.last?.id {
                    PassSectionDivider()
                }
            }
        }
        .roundedEditableSection()
    }

    @ViewBuilder
    var footer: some View {
        if let importedCount = viewModel.importedCount {
            VStack(spacing: 16) {
                HStack {
                    ProgressView()
                    Text("\(importedCount) of \(viewModel.itemCount) items", bundle: .module)
                }
                .foregroundStyle(PassColor.textNorm)

                keepAppOpenNotice
            }
        } else if viewModel.hasUnsupportedItems {
            Text("Not all item types are supported by other password managers.", bundle: .module)
                .foregroundStyle(PassColor.textWeak)
                .multilineTextAlignment(.center)
        }
    }

    var keepAppOpenNotice: some View {
        Label(title: {
            // swiftlint:disable:next line_length
            Text("Please keep Proton Pass open until the import finishes. Leaving the app or locking your device may interrupt it.",
                 bundle: .module)
        }, icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        })
        .foregroundStyle(PassColor.noteInteractionNormMajor2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(PassColor.noteInteractionNormMinor1)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var actionButtons: some View {
        VStack {
            DisablableCapsuleTextButton(title: #localized("Import items", bundle: .module),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNorm,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canImport,
                                        action: viewModel.startImporting)

            CapsuleTextButton(title: #localized("Cancel", bundle: .module),
                              titleColor: PassColor.interactionNormMajor1,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: { dismiss() })
                .disabled(viewModel.importing)
        }
    }
}
