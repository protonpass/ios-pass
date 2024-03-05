//
// PasskeyCredentialsView.swift
// Proton Pass - Created on 27/02/2024.
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

import Client
import DesignSystem
import Entities
import Factory
import Screens
import SwiftUI

struct PasskeyCredentialsView: View {
    @StateObject private var viewModel: PasskeyCredentialsViewModel
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let onCreate: () -> Void
    private let onCancel: () -> Void

    init(request: PasskeyCredentialRequest,
         onCreate: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(request: request))
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(searchableItems, uiModels):
                LoginItemsView(searchableItems: searchableItems,
                               uiModels: uiModels,
                               mode: .passkeyCreation,
                               itemRow: { itemRow(for: $0) },
                               searchResultRow: { searchResultRow(for: $0) },
                               onCreate: onCreate,
                               onCancel: onCancel)
            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.loadCredentials() } })
            }
        }
        .theme(preferences.theme)
        .showSpinner(viewModel.isCreatingPasskey)
        .alert("Create passkey",
               isPresented: $viewModel.isShowingAssociationConfirmation,
               actions: {
                   Button(role: .cancel,
                          label: { Text("Cancel") })

                   Button(role: nil,
                          action: { await viewModel.createAndAssociatePasskey() },
                          label: { Text("Confirm") })
               },
               message: {
                   Text("A passkey will be created for the \"\(viewModel.selectedItem?.itemTitle ?? "")\" login.")
               })
        .task { await viewModel.loadCredentials() }
    }
}

private extension PasskeyCredentialsView {
    func itemRow(for uiModel: ItemUiModel) -> some View {
        GenericCredentialItemRow(item: uiModel, selectItem: { viewModel.selectedItem = $0 })
    }

    func searchResultRow(for result: ItemSearchResult) -> some View {
        Button(action: {
            viewModel.selectedItem = result
        }, label: {
            ItemSearchResultView(result: result)
        })
        .buttonStyle(.plain)
    }
}
