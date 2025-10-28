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
import FactoryKit
import ProtonCoreUIFoundations
import SwiftUI

struct ManageSharedShareView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ManageSharedShareViewModel
    @State private var showFreeSharingLimit = false

    var body: some View {
        ScrollView {
            mainContainer
                .padding(DesignConstant.sectionPadding)
        }
        .overlay {
            if viewModel.fetching {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .animation(.default, value: viewModel.fetching)
        .task {
            viewModel.fetchShareInformation(displayFetchingLoader: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Shared via")
        .background(PassColor.backgroundNorm)
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
        inviteeList
    }
}

private extension ManageSharedShareView {
    var inviteeList: some View {
        LazyVStack(spacing: 32) {
            if !viewModel.itemMembers.isEmpty {
                inviteesSection(for: viewModel.itemMembers,
                                isVaultSection: false,
                                canExecuteActions: viewModel.share.shareRole == .manager,
                                canSeeAccessLevel: viewModel.share.shareRole != .read,
                                title: "Item sharing: \(viewModel.itemMembers.count) users")
            }

            if !viewModel.vaultMembers.isEmpty {
                inviteesSection(for: viewModel.vaultMembers,
                                isVaultSection: true,
                                canExecuteActions: viewModel.share.shareRole == .manager &&
                                    viewModel.share.isVaultRepresentation,
                                canSeeAccessLevel: viewModel.share.isVaultRepresentation,
                                title: "Vault sharing: \(viewModel.vaultMembers.count) members")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func inviteesSection(for invitees: [any ShareInvitee],
                         isVaultSection: Bool,
                         canExecuteActions: Bool,
                         canSeeAccessLevel: Bool,
                         title: LocalizedStringKey) -> some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak)

            LazyVStack(spacing: 0) {
                if isVaultSection, let vaultContent = viewModel.share.vaultContent {
                    HStack(spacing: 16) {
                        vaultContent.vaultBigIcon
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(vaultContent.mainColor)
                            .frame(width: 18, height: 18)
                            .padding(12)
                            .background(vaultContent.backgroundColor)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(vaultContent.name)
                                .foregroundStyle(PassColor.textNorm)
                            Text("\(viewModel.itemsNumber) item(s)")
                                .foregroundStyle(PassColor.textWeak)
                        }
                        Spacer()
                    }.padding(16)
                    PassDivider()
                }
                if canExecuteActions {
                    HStack {
                        if isVaultSection || (!isVaultSection && viewModel.itemSharingAllowed) {
                            inviteMore(isVaultSharing: isVaultSection)
                        }
                        if isVaultSection, viewModel.showInvitesLeft {
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
                                .foregroundStyle(PassColor.textWeak)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    PassDivider()
                }
                ForEach(Array(invitees.enumerated()), id: \.element.id) { index, invitee in
                    ShareInviteeView(invitee: invitee,
                                     isManager: canExecuteActions,
                                     managerAsAdmin: viewModel.managerAsAdmin,
                                     isCurrentUser: viewModel.isCurrentUser(invitee),
                                     canSeeAccessLevel: canSeeAccessLevel,
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension ManageSharedShareView {
    func inviteMore(isVaultSharing: Bool) -> some View {
        VStack {
            Button {
                viewModel.shareWithMorePeople(iSharingVault: isVaultSharing)
            } label: {
                Label(isVaultSharing ? "Invite more users to the vault" : "Invite more users to the item",
                      image: Image(uiImage: IconProvider.userPlus))
                    .foregroundStyle(PassColor.interactionNormMajor2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(isVaultSharing && viewModel.reachedLimit && !viewModel.isBusinessUser)
            if isVaultSharing, viewModel.showVaultLimitMessage {
                vaultLimitReachedMessage
            }
        }
        .padding(.vertical, 12)
    }
}

private extension ManageSharedShareView {
    var vaultLimitReachedMessage: some View {
        ZStack {
            Text("You have reached the limit of users in this vault.")
                .adaptiveForegroundStyle(PassColor.textNorm) +
                Text(verbatim: " ") +
                Text("Upgrade now to share with more people")
                .underline(color: PassColor.interactionNormMajor1)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1)
        }
        .padding()
        .background(PassColor.interactionNormMinor1)
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
