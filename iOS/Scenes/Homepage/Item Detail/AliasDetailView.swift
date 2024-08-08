//
// AliasDetailView.swift
// Proton Pass - Created on 15/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct AliasDetailView: View {
    @StateObject private var viewModel: AliasDetailViewModel
    @Namespace private var bottomID
    @State private var animate = false

    private var iconTintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if let error = viewModel.error {
            RetryableErrorView(errorMessage: error.localizedDescription) {
                viewModel.refresh()
            }
            .padding()
        } else {
            if viewModel.isShownAsSheet {
                NavigationStack {
                    realBody
                }
            } else {
                realBody
            }
        }
    }

    private var realBody: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent,
                                        vault: viewModel.vault?.vault,
                                        shouldShowVault: viewModel.shouldShowVault)
                        .padding(.bottom, 40)

                    aliasMailboxesSection
                        .padding(.bottom, 8)

                    if !viewModel.itemContent.note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault)
                    }

                    ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                             action: { viewModel.showItemHistory() })

                    ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                              itemContent: viewModel.itemContent,
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
        .itemDetailSetUp(viewModel)
        .onFirstAppear(perform: viewModel.getAlias)
        .alert("Move To Trash", isPresented: $viewModel.showingGenericAlert) {
            Button("Disable instead") { viewModel.disableAlias() }
            Button("Move to trash") { viewModel.moveToTrash() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Aliases in Trash will continue forwarding emails. If you want to stop receiving emails on this address, disable it instead.")
        }
        .onFirstAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animate = true
            }
        }
    }

    private var aliasMailboxesSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            aliasRow
            PassSectionDivider()
            mailboxesRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.mailboxes)
    }

    private var aliasRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Alias address")
                    .sectionTitleText()

                Text(viewModel.aliasEmail)
                    .sectionContentText()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyAliasEmail() }

            if viewModel.togglingAliasStatus {
                ProgressView()
            } else {
                StaticToggle(isOn: viewModel.aliasIsSync,
                             tintColor: iconTintColor,
                             action: { viewModel.toggleAliasState() })
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contextMenu {
            Button { viewModel.copyAliasEmail() } label: {
                Text("Copy")
            }

            Button(action: {
                viewModel.showLarge(.text(viewModel.aliasEmail))
            }, label: {
                Text("Show large")
            })
        }
    }

    @ViewBuilder
    private var mailboxesRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.forward, color: iconTintColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Forwarding to")
                    .sectionTitleText()
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let mailboxes = viewModel.mailboxes {
                    ForEach(mailboxes, id: \.ID) { mailbox in
                        Text(mailbox.email)
                            .sectionContentText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                            .contextMenu {
                                Button(action: {
                                    viewModel.copyMailboxEmail(mailbox.email)
                                }, label: {
                                    Text("Copy")
                                })

                                Button(action: {
                                    viewModel.showLarge(.text(mailbox.email))
                                }, label: {
                                    Text("Show large")
                                })
                            }
                    }
                } else {
                    Group {
                        SkeletonBlock(tintColor: iconTintColor)
                        SkeletonBlock(tintColor: iconTintColor)
                        SkeletonBlock(tintColor: iconTintColor)
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
