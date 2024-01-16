//
// DetailHistoryView+Alias.swift
// Proton Pass - Created on 16/01/2024.
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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

extension DetailHistoryView {
    var aliasView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            HStack(spacing: DesignConstant.sectionPadding) {
                ItemSquircleThumbnail(data: itemContent.thumbnailData(),
                                      pinned: false,
                                      size: .large)

                VStack(alignment: .leading, spacing: 4) {
                    Text(itemContent.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .foregroundColor(textColor(for: \.name).toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 60)
            .padding(.bottom, 40)

            aliasMailboxesSection(item: itemContent)
            noteFields(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func aliasMailboxesSection(item: ItemContent) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            aliasRow(item: item)
//            PassSectionDivider()
//            mailboxesRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    private func aliasRow(item: ItemContent) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Alias address")
                    .sectionTitleText()

                Text(item.aliasEmail ?? "")
                    .foregroundStyle(textColor(for: \.aliasEmail).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

//    @ViewBuilder
//    private var mailboxesRow: some View {
//        HStack(spacing: DesignConstant.sectionPadding) {
//            ItemDetailSectionIcon(icon: IconProvider.forward, color: viewModel.currentRevision.type.normColor)
//
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Forwarding to")
//                    .sectionTitleText()
//
//                if let mailboxes = viewModel.mailboxes {
//                    ForEach(mailboxes, id: \.ID) { mailbox in
//                        Text(mailbox.email)
//                            .sectionContentText()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .contentShape(Rectangle())
//                            .contextMenu {
//                                Button(action: {
//                                    viewModel.copyMailboxEmail(mailbox.email)
//                                }, label: {
//                                    Text("Copy")
//                                })
//
//                                Button(action: {
//                                    viewModel.showLarge(.text(mailbox.email))
//                                }, label: {
//                                    Text("Show large")
//                                })
//                            }
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(.horizontal, DesignConstant.sectionPadding)
//        .animation(.default, value: viewModel.mailboxes)
//    }
}
