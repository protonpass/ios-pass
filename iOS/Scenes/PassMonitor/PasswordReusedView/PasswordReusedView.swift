//
//
// PasswordReusedView.swift
// Proton Pass - Created on 27/03/2024.
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
import ProtonCoreUIFoundations
import SwiftUI

struct PasswordReusedView: View {
    @StateObject private var viewModel: PasswordReusedViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PasswordReusedViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Text("Items from your vaults that use this password.")
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)

            itemsList(items: viewModel.reusedItems)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .showSpinner(viewModel.loading)
        .navigationTitle(viewModel.title)
        .navigationStackEmbeded()
    }
}

private extension PasswordReusedView {
    func itemsList(items: [ItemContent]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                itemRow(for: item)
            }
            Spacer()
        }
    }

    func itemRow(for item: ItemContent) -> some View {
        Button {
            viewModel.viewDetail(of: item)
        } label: {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                           title: item.title,
                           description: item.toItemUiModel.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private extension PasswordReusedView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }
    }
}
