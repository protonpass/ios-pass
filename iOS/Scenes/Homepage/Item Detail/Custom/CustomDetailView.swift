//
// CustomDetailView.swift
// Proton Pass - Created on 10/03/2025.
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

import Screens
import SwiftUI

struct CustomDetailView: View {
    @StateObject private var viewModel: CustomDetailViewModel
    @Namespace private var bottomID

    init(viewModel: CustomDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 0) {
                ItemDetailTitleView(itemContent: viewModel.itemContent,
                                    vault: viewModel.vault?.vault)
                    .padding(.bottom, 40)

                CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                    fields: viewModel.customFields,
                                    isFreeUser: viewModel.isFreeUser,
                                    showIcon: false,
                                    onSelectHiddenText: viewModel.copyHiddenText,
                                    onSelectTotpToken: viewModel.copyTOTPToken,
                                    onUpgrade: { viewModel.upgrade() })

                CustomSectionsSection(sections: viewModel.extraSections,
                                      contentType: viewModel.itemContentType,
                                      isFreeUser: viewModel.isFreeUser,
                                      showIcon: false,
                                      onCopyHiddenText: viewModel.copyHiddenText,
                                      onCopyTotpToken: viewModel.copyTOTPToken,
                                      onUpgrade: viewModel.upgrade)

                if viewModel.showFileAttachmentsSection {
                    FileAttachmentsViewSection(files: viewModel.fileUiModels,
                                               isFetching: viewModel.files.isFetching,
                                               fetchError: viewModel.files.error,
                                               handler: viewModel)
                        .padding(.top, 8)
                }

                ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                         action: {
                                             viewModel.canShareItem ? viewModel.showItemHistory() : nil
                                         })

                ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                          itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault,
                                          onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                    .padding(.top, 24)
                    .id(bottomID)
            }
            .padding()
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { proxy.scrollTo(bottomID, anchor: .bottom) }
            }
            .scrollViewEmbeded()
        }
        .itemDetailSetUp(viewModel)
        .navigationStackEmbeded()
    }
}
