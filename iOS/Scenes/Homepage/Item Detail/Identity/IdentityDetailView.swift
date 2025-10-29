//
//
// IdentityDetailView.swift
// Proton Pass - Created on 27/05/2024.
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
import Screens
import SwiftUI

struct IdentityDetailView: View {
    @StateObject private var viewModel: IdentityDetailViewModel
    @State private var showSocialSecurityNumber = false
    @Namespace private var bottomID

    init(viewModel: IdentityDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        mainContainer
            .if(viewModel.isShownAsSheet) { view in
                view.navigationStackEmbeded()
            }
    }
}

private extension IdentityDetailView {
    var mainContainer: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent,
                                        vault: viewModel.vault?.vault)
                        .padding(.bottom, 25)

                    ForEach(viewModel.sections) { section in
                        if !section.isEmpty {
                            view(for: section)
                        }
                    }

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
            }
            .animation(.default, value: viewModel.moreInfoSectionExpanded)
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
            }
        }
        .animation(.default, value: viewModel.moreInfoSectionExpanded)
        .itemDetailSetUp(viewModel)
    }
}

private extension IdentityDetailView {
    func view(for section: IdentityDetailSection) -> some View {
        Section {
            VStack(spacing: DesignConstant.sectionPadding) {
                ForEach(section.rows) { row in
                    if let value = row.value, !value.isEmpty {
                        HStack(spacing: DesignConstant.sectionPadding) {
                            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                                Text(row.title)
                                    .sectionTitleText()

                                let showPlainText = !row.isSocialSecurityNumber ||
                                    (row.isSocialSecurityNumber && showSocialSecurityNumber)
                                Text(showPlainText ? value : String(repeating: "•", count: 12))
                                    .sectionContentText()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                            .onTapGesture {
                                viewModel.copyToClipboard(row)
                            }

                            if row.isSocialSecurityNumber {
                                toggleSSNVisibilityButton
                            }
                        }
                        .padding(.horizontal, DesignConstant.sectionPadding)
                        .contextMenu {
                            Button(action: {
                                viewModel.copyToClipboard(row)
                            }, label: {
                                Text("Copy")
                            })
                        }

                        if row == section.rows.last, section.customFields.isEmpty {
                            EmptyView()
                        } else {
                            PassSectionDivider()
                        }
                    }
                }

                CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                    fields: section.customFields,
                                    isFreeUser: viewModel.isFreeUser,
                                    isASection: false,
                                    showIcon: false,
                                    onSelectHiddenText: viewModel.copyHiddenText,
                                    onSelectTotpToken: viewModel.copyTOTPToken,
                                    onUpgrade: { viewModel.upgrade() })
            }
            .padding(.vertical, DesignConstant.sectionPadding)
            .roundedDetailSection()
        } header: {
            Text(section.title)
                .foregroundStyle(PassColor.textWeak)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }

    var toggleSSNVisibilityButton: some View {
        CircleButton(icon: showSocialSecurityNumber ? IconProvider.eyeSlash : IconProvider.eye,
                     iconColor: viewModel.itemContent.type.normMajor2Color,
                     backgroundColor: viewModel.itemContent.type.normMinor2Color,
                     accessibilityLabel: showSocialSecurityNumber ?
                         "Hide social security number" : "Show social security number",
                     action: { showSocialSecurityNumber.toggle() })
            .fixedSize(horizontal: true, vertical: true)
            .animationsDisabled()
    }
}
