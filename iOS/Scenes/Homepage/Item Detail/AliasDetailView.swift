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
import FactoryKit
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

    private var iconTintColor: Color { viewModel.itemContent.type.normColor }

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
                                        vault: viewModel.vault?.vault)
                        .padding(.bottom, 40)

                    aliasMailboxesSection
                        .padding(.bottom, 8)

                    if !viewModel.itemContent.note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault,
                                          note: viewModel.itemContent.note)
                            .padding(.bottom, 8)
                    }

                    if let note = viewModel.simpleLoginNote, !note.isEmpty {
                        NoteDetailSection(itemContent: viewModel.itemContent,
                                          vault: viewModel.vault?.vault,
                                          title: "Note • SimpleLogin",
                                          note: note)
                            .padding(.bottom, 8)
                    }

                    if let name = viewModel.aliasInfos?.name {
                        senderNameRow(name: name)
                            .padding(.bottom, 8)
                    }

                    if viewModel.contacts != nil, viewModel.isAliasOwner {
                        contactRow
                            .padding(.bottom, viewModel.showContactsTip ? 0 : 8)

                        if viewModel.showContactsTip {
                            contactTip
                                .padding(.vertical, 8)
                        }
                    }

                    if let stats = viewModel.aliasInfos?.stats {
                        statsRow(stats: stats)
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        fields: viewModel.customFields,
                                        isFreeUser: viewModel.isFreeUser,
                                        onSelectHiddenText: viewModel.copyHiddenText,
                                        onSelectTotpToken: viewModel.copyTOTPToken,
                                        onUpgrade: { viewModel.upgrade() })

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
            .animation(.default, value: viewModel.aliasInfos)
            .animation(.default, value: viewModel.contacts)
            .animation(.default, value: viewModel.showContactsTip)
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
            }
        }
        .itemDetailSetUp(viewModel)
        .task {
            await viewModel.loadContact()
        }
        .onFirstAppear {
            // Reset the navigation path because it could be modified by a previous alias' detail page
            router.popToRoot()
            viewModel.getAlias()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animate = true
            }
        }
        .modifier(AliasTrashAlertModifier(showingTrashAliasAlert: $viewModel.showingTrashAliasAlert,
                                          enabled: viewModel.aliasEnabled,
                                          disableAction: { viewModel.disableAlias() },
                                          trashAction: {
                                              dismiss()
                                              viewModel.moveToTrash()
                                          }))
    }

    private var aliasMailboxesSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            aliasRow
            if viewModel.showMailboxesRow {
                PassSectionDivider()
                mailboxesRow
            }
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

                Text(AttributedString(viewModel.aliasEmail, attributes: .lineBreakHyphenErasing))
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyAliasEmail() }
            .layoutPriority(1)

            Group {
                if viewModel.togglingAliasStatus || viewModel.aliasInfos == nil {
                    ProgressView()
                } else if viewModel.isAliasOwner {
                    StaticToggle(isOn: viewModel.aliasEnabled,
                                 tintColor: iconTintColor,
                                 action: { viewModel.toggleAliasState() })
                }
            }
            .frame(width: 42)
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
                    RetryableErrorView(mode: .defaultHorizontal,
                                       tintColor: iconTintColor,
                                       error: error,
                                       onRetry: viewModel.refresh)
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
                        .foregroundStyle(PassColor.textNorm)
                        .background(PassColor.backgroundMedium)
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

    private var contactTip: some View {
        TipBanner(configuration: .init(arrowMode: .topLeft(padding: 20),
                                       description: contactTipDescription,
                                       trailingBackground: .init(image: PassIcon.protonStamp,
                                                                 offset: .init(width: 40, height: -20))),
                  onDismiss: viewModel.dismissContactsTip)
    }

    private var contactTipDescription: LocalizedStringKey {
        "Every time your alias receives an email from someone, a new contact is automatically created."
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
            .foregroundStyle(PassColor.textWeak)
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
