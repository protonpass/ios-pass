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

import AuthenticationServices
import Client
import DesignSystem
import Entities
import Factory
import Screens
import SwiftUI

struct PasskeyCredentialsView: View {
    @StateObject private var viewModel: PasskeyCredentialsViewModel

    init(viewModel: PasskeyCredentialsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                LoginItemsView(searchableItems: viewModel.searchableItems,
                               uiModels: viewModel.items,
                               mode: .passkeyCreation,
                               users: viewModel.users,
                               selectedUser: $viewModel.selectedUser,
                               itemRow: { row(for: .uiModel($0)) },
                               searchResultRow: { row(for: .searchResult($0)) },
                               searchBarPlaceholder: viewModel.searchBarPlaceholder,
                               onRefresh: { await viewModel.sync(ignoreError: false) },
                               onCreate: {
                                   if viewModel.shouldAskForUserWhenCreatingNewItem {
                                       viewModel.presentSelectUserActionSheet()
                                   } else {
                                       viewModel.createNewItem(userId: nil)
                                   }
                               },
                               onCancel: { viewModel.handleCancel() })
            case let .error(error):
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }
        }
        .showSpinner(viewModel.isCreatingPasskey)
        .localAuthentication(logOutButtonMode: .topBarTrailing { viewModel.handleCancel() },
                             onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
                             onFailure: { _ in viewModel.handleAuthenticationFailure() })
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
        .task {
            await viewModel.fetchItems()
            // Ignore errors here otherwise users will always end up with errors when being offline
            await viewModel.sync(ignoreError: true)
        }
    }
}

private extension PasskeyCredentialsView {
    func row(for item: CredentialItem) -> some View {
        GenericCredentialItemRow(item: item,
                                 user: viewModel.getUserForUiDisplay(for: item.item),
                                 selectItem: { viewModel.selectedItem = $0 })
    }
}
