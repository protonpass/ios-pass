//
// AliasDetailView.swift
// Proton Pass - Created on 09/10/2024.
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct AliasDetailView: View {
    @StateObject private var viewModel: AliasDetailViewModel
    @State private var animate = false

    var tintColor: Color {
        viewModel.type.normColor
    }

    init(_ viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            aliasRow
            PassSectionDivider()
            mailboxesRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.mailboxes)
        .task { await viewModel.fetchMailboxes() }

        if !viewModel.item.content.note.isEmpty {
            NoteDetailSection(itemContent: viewModel.item.content,
                              vault: nil)
        }

        CustomFieldSections(itemContentType: viewModel.type,
                            fields: viewModel.customFields,
                            isFreeUser: viewModel.isFreeUser,
                            onSelectHiddenText: viewModel.autofill,
                            onSelectTotpToken: viewModel.autofill,
                            onUpgrade: viewModel.upgrade)
    }
}

private extension AliasDetailView {
    var aliasRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.enabled ? "Alias address" : "Alias address (disabled)")
                    .sectionTitleText()

                Text(viewModel.email)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.autofill(viewModel.email) }
            .layoutPriority(1)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var mailboxesRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.forward, color: tintColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Forwarding to")
                    .sectionTitleText()
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let error = viewModel.mailboxesError {
                    RetryableErrorView(mode: .defaultHorizontal,
                                       tintColor: tintColor,
                                       error: error,
                                       onRetry: {
                                           Task {
                                               await viewModel.fetchMailboxes()
                                           }
                                       })
                } else if let mailboxes = viewModel.mailboxes {
                    ForEach(mailboxes, id: \.ID) { mailbox in
                        Text(mailbox.email)
                            .sectionContentText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                            .onTapGesture {
                                viewModel.autofill(mailbox.email)
                            }
                    }
                } else {
                    Group {
                        SkeletonBlock(tintColor: tintColor)
                        SkeletonBlock(tintColor: tintColor)
                        SkeletonBlock(tintColor: tintColor)
                    }
                    .clipShape(Capsule())
                    .shimmering(active: animate)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.mailboxes)
    }
}
