//
// SshDetailView.swift
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct SshDetailView: View {
    @StateObject private var viewModel: SshDetailViewModel
    @State private var selectedKeyType: SshKeyType?
    @Namespace private var bottomID

    init(viewModel: SshDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(spacing: 0) {
                ItemDetailTitleView(itemContent: viewModel.itemContent,
                                    vault: viewModel.vault?.vault)
                    .padding(.bottom, 40)

                keysSection

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
                                         action: viewModel.showItemHistory)

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
        .sheet(item: $selectedKeyType) { keyType in
            let value = switch keyType {
            case .private: viewModel.privateKey
            case .public: viewModel.publicKey
            }
            SshKeyDetailView(value: value, title: keyType.title)
        }
    }
}

private extension SshDetailView {
    var keysSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            publicKeyRow
            PassSectionDivider()
            privateKeyRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    var publicKeyRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Public key")
                .sectionTitleText()

            if viewModel.publicKey.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(viewModel.publicKey)
                    .sectionContentText()
                    .monospaced()
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture {
            if !viewModel.publicKey.isEmpty {
                selectedKeyType = .public
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .if(!viewModel.publicKey.isEmpty) { view in
            view.contextMenu {
                Button(action: viewModel.copyPublicKey) {
                    Text("Copy")
                }
            }
        }
    }

    var privateKeyRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Private key")
                .sectionTitleText()

            if viewModel.privateKey.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(String(repeating: "•", count: 12))
                    .sectionContentText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture {
            if !viewModel.privateKey.isEmpty {
                selectedKeyType = .private
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .if(!viewModel.privateKey.isEmpty) { view in
            view.contextMenu {
                Button(action: viewModel.copyPrivateKey) {
                    Text("Copy")
                }
            }
        }
    }
}
