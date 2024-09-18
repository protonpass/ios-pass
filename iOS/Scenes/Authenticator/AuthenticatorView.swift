//
//
// AuthenticatorView.swift
// Proton Pass - Created on 15/03/2024.
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
//

import DesignSystem
import Entities
import Screens
import SwiftUI

struct AuthenticatorView: View {
    @StateObject private var viewModel = AuthenticatorViewModel()

    var body: some View {
        mainContent
            .animation(.default, value: viewModel.displayedItems)
            .navigationTitle("Authenticator")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .navigationStackEmbeded()
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search")
            .task {
                await viewModel.load()
            }
    }
}

private extension AuthenticatorView {
    var mainContent: some View {
        LazyVStack {
            itemsList(items: viewModel.displayedItems)
        }
        .padding(DesignConstant.sectionPadding)
    }

    func itemsList(items: [AuthenticatorItem]) -> some View {
        ForEach(items) { item in
            itemRow(for: item)
                .roundedEditableSection()
        }
    }

    func itemRow(for item: AuthenticatorItem) -> some View {
        AuthenticatorRow(thumbnailView: { ItemSquircleThumbnail(data: item.icon, size: .large) },
                         uri: item.uri,
                         title: item.title,
                         totpManager: SharedServiceContainer.shared.totpManager(),
                         onCopyTotpToken: { viewModel.copyTotpToken($0) })
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
