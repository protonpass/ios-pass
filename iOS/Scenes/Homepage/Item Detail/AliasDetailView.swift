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
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct AliasDetailView: View {
    @StateObject private var viewModel: AliasDetailViewModel
    @Namespace private var bottomID
    @State private var animate = false
    @StateObject var router = resolve(\RouterContainer.darkWebRouter)
    @Environment(\.dismiss) private var dismiss

    private var iconTintColor: UIColor { viewModel.itemContent.type.normColor }

    init(viewModel: AliasDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        realBody
            .routingProvided
            .navigationStackEmbeded($router.path)
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
                                          vault: viewModel.vault?.vault,
                                          note: viewModel.itemContent.note)
                            .padding(.bottom, 8)
                    }

                    if let note = viewModel.aliasInfos?.note, !note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault,
                                          title: "Note • SimpleLogin",
                                          note: note)
                            .padding(.bottom, 8)
                    }

                    if viewModel.isAdvancedAliasManagementActive {
                        if let name = viewModel.aliasInfos?.name {
                            senderNameRow(name: name)
                                .padding(.bottom, 8)
                        }

                        if viewModel.contacts != nil, let aliasInfos = viewModel.aliasInfos, aliasInfos.modify {
                            contactRow

                            // swiftlint:disable:next line_length
                            Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.footnote)
                                .foregroundStyle(PassColor.textWeak.toColor)
                                .padding(.top, 8)
                                .padding(.bottom, DesignConstant.sectionPadding)
                        }

                        if let stats = viewModel.aliasInfos?.stats {
                            statsRow(stats: stats)
                        }
                    }

                    ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                             action: { viewModel.showItemHistory() })

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
            .animation(.default, value: viewModel.aliasInfos)
            .animation(.default, value: viewModel.contacts)
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
            }
        }
        .itemDetailSetUp(viewModel)
        .task {
            await viewModel.loadContact()
        }
        .onFirstAppear {
            viewModel.getAlias()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animate = true
            }
        }
        .if(viewModel.aliasSyncEnabled) {
            $0.modifier(AliasTrashAlertModifier(showingTrashAliasAlert: $viewModel.showingTrashAliasAlert,
                                                enabled: viewModel.aliasEnabled,
                                                disableAction: { viewModel.disableAlias() },
                                                trashAction: {
                                                    dismiss()
                                                    viewModel.moveToTrash()
                                                }))
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
        .animation(.default, value: viewModel.aliasInfos)
    }

    private var aliasRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.aliasEnabled ? "Alias address" : "Alias address (disabled)")
                    .sectionTitleText()

                Text(viewModel.aliasEmail)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyAliasEmail() }
            .layoutPriority(1)

            if viewModel.aliasSyncEnabled {
                Group {
                    if viewModel.togglingAliasStatus {
                        ProgressView()
                    } else {
                        StaticToggle(isOn: viewModel.aliasEnabled,
                                     tintColor: iconTintColor,
                                     action: { viewModel.toggleAliasState() })
                    }
                }.frame(width: 42)
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.togglingAliasStatus)
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
                if let error = viewModel.error {
                    RetryableErrorCellView(errorMessage: error.localizedDescription,
                                           textColor: PassColor.signalDanger.toColor,
                                           buttonColor: iconTintColor) {
                        viewModel.refresh()
                    }
                } else {
                    Text("Forwarding to")
                        .sectionTitleText()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let mailboxes = viewModel.aliasInfos?.mailboxes {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: viewModel.aliasInfos)
    }

    private func statsRow(stats: AliasStats) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.chartLine, color: iconTintColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Activity in last 14 days")
                    .sectionTitleText()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // swiftlint:disable:next line_length
                Text(verbatim: "\(stats.forwardedEmailsTitle) • \(stats.repliedEmailsTitle) • \(stats.blockedEmailsTitle)")
                    .sectionContentText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    private var contactRow: some View {
        Button {
            guard let infos = viewModel.getContactsInfos() else { return }
            router.navigate(to: .contacts(infos))
        } label: {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.filingCabinet, color: iconTintColor)
                Text("Contacts")
                    .sectionContentText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .padding(.vertical, 8)

                if let totalContacts = viewModel.aliasInfos?.contactCount, totalContacts > 0 {
                    Text(verbatim: "\(totalContacts)")
                        .fontWeight(.medium)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 11)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .background(PassColor.backgroundMedium.toColor)
                        .clipShape(Capsule())
                }

                ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                      width: 20)
            }
            .padding(DesignConstant.sectionPadding)
            .roundedDetailSection()
        }
        .animation(.default, value: viewModel.contacts)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func senderNameRow(name: String) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.cardIdentity, color: iconTintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Display name")
                    .sectionTitleText()

                Text(verbatim: name)
                    .sectionContentText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()

        Text("The display name when sending an email from this alias.")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.footnote)
            .foregroundStyle(PassColor.textWeak.toColor)
            .padding(.bottom, DesignConstant.sectionPadding)
    }
}

private extension AliasStats {
    var forwardedEmailsTitle: String {
        #localized("%lld forwards", forwardedEmails)
    }

    var repliedEmailsTitle: String {
        #localized("%lld replies", repliedEmails)
    }

    var blockedEmailsTitle: String {
        #localized("%lld blocks", blockedEmails)
    }
}
