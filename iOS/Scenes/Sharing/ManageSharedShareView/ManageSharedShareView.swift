//
//
// ManageSharedShareView.swift
// Proton Pass - Created on 02/08/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ManageSharedShareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ManageSharedShareViewModel
    @State private var showFreeSharingLimit = false

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContainer
                .padding(.bottom, viewModel.share.isAdmin ? 70 : 0) // Avoid the bottom button

            if !viewModel.fetching, !viewModel.isViewOnly {
                shareButtonAndInfos
            }

            if !viewModel.share.isVaultRepresentation, !viewModel.share.owner {
                CapsuleTextButton(title: #localized("Leave"),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  action: {
                                      viewModel.leaveVault()
                                  })
            }
        }
        .task {
            viewModel.fetchShareInformation(displayFetchingLoader: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignConstant.sectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .toolbar { toolbarContent }
        .showSpinner(viewModel.loading)
        .alert(item: $viewModel.newOwner) { newOwner in
            Alert(title: Text("Transfer ownership"),
                  message: Text("Transfer ownership of this vault to \(newOwner.email)?"),
                  primaryButton: .default(Text("Confirm"),
                                          action: { viewModel.handle(option: .transferOwnership(newOwner)) }),
                  secondaryButton: .cancel())
        }
        .alert("Member Limit",
               isPresented: $showFreeSharingLimit,
               actions: {
                   Button(role: .cancel, label: { Text("OK") })
               }, message: {
                   Text(viewModel
                       .isFreeUser ? "Vaults can’t contain more than 3 users with a free plan." :
                       "Vaults can’t contain more than 10 users.")
               })
        .navigationStackEmbeded()
    }

    func refresh() {
        viewModel.fetchShareInformation()
    }
}

private extension ManageSharedShareView {
    var mainContainer: some View {
        VStack {
            if let vaultContent = viewModel.share.vaultContent, viewModel.share.shared {
                headerVaultInformation(vaultContent: vaultContent)
            } else {
                itemShareHeader
            }
            if viewModel.fetching {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                inviteeList
            }
        }
        .animation(.default, value: viewModel.fetching)
    }
}

private extension ManageSharedShareView {
    var itemShareHeader: some View {
        Text("Shared with")
            .font(.title.bold())
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 22)
    }

    func headerVaultInformation(vaultContent: VaultContent) -> some View {
        VStack {
            ZStack {
                vaultContent.backgroundColor.toColor
                    .clipShape(Circle())

                Image(uiImage: vaultContent.vaultBigIcon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(vaultContent.mainColor.toColor)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 64, height: 64)

            Text(vaultContent.name)
                .font(.title2.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
            Text("\(viewModel.itemsNumber) item(s)")
                .font(.title3)
                .foregroundStyle(PassColor.textWeak.toColor)
        }
    }
}

private extension ManageSharedShareView {
    var inviteeList: some View {
        ScrollView {
            VStack(spacing: 32) {
                if !viewModel.invitations.isEmpty {
                    inviteesSection(for: viewModel.invitations.invitees, title: "Invitations")
                }

                if !viewModel.vaultMembers.isEmpty {
                    inviteesSection(for: viewModel.vaultMembers,
                                    title: " Vault share Members (\(viewModel.vaultMembers.count))")
                }

                if !viewModel.itemMembers.isEmpty {
                    inviteesSection(for: viewModel.itemMembers,
                                    title: " Item share Members (\(viewModel.itemMembers.count))")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.default, value: viewModel.invitations)
        .animation(.default, value: viewModel.vaultMembers)
        .animation(.default, value: viewModel.itemMembers)
    }

    func inviteesSection(for invitees: [any ShareInvitee], title: LocalizedStringKey) -> some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(PassColor.textWeak.toColor)

            LazyVStack {
                ForEach(Array(invitees.enumerated()), id: \.element.id) { index, invitee in
                    ShareInviteeView(invitee: invitee,
                                     isAdmin: viewModel.share.isAdmin,
                                     isCurrentUser: viewModel.isCurrentUser(invitee),
                                     canTransferOwnership: viewModel.canTransferOwnership(to: invitee),
                                     onSelect: { viewModel.handle(option: $0) })
                        .padding(16)
                    if index != invitees.count - 1 {
                        PassDivider()
                    }
                }
                .listRowSeparator(.hidden)
            }
            .roundedEditableSection()
        }
    }
}

private extension ManageSharedShareView {
    var shareButtonAndInfos: some View {
        VStack {
            DisablableCapsuleTextButton(title: #localized("Share with more people"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textInvert,
                                        backgroundColor: PassColor.interactionNorm,
                                        disableBackgroundColor: PassColor.interactionNorm
                                            .withAlphaComponent(0.5),
                                        disabled: viewModel.reachedLimit && !viewModel.isBusinessUser,
                                        action: { viewModel.shareWithMorePeople() })

            if viewModel.showVaultLimitMessage {
                vaultLimitReachedMessage
            }

            if viewModel.showInvitesLeft {
                Button { showFreeSharingLimit.toggle() } label: {
                    Label {
                        Text("\(viewModel.numberOfInvitesLeft) invite remaining")
                            .font(.caption)
                            .fontWeight(.semibold)
                    } icon: {
                        IconProvider.questionCircle.toImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16)
                    }
                    .foregroundStyle(PassColor.textWeak.toColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension ManageSharedShareView {
    var vaultLimitReachedMessage: some View {
        ZStack {
            Text("You have reached the limit of users in this vault.")
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now to share with more people")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
        .onTapGesture(perform: viewModel.upgrade)
    }
}

private extension ManageSharedShareView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }
}
