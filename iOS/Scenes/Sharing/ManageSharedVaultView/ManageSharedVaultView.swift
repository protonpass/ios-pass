//
//
// ManageSharedVaultView.swift
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

import Client
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ManageSharedVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ManageSharedVaultViewModel
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContainer
                .padding(.bottom, viewModel.vault.isAdmin ? 60 : 0) // Avoid the bottom button

//            if viewModel.canShare {
            shareButtonAndInfos
//            }
        }
        .onAppear {
            viewModel.fetchShareInformation(displayFetchingLoader: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
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
        .navigationModifier()
    }

    func refresh() {
        viewModel.fetchShareInformation()
    }
}

private extension ManageSharedVaultView {
    var mainContainer: some View {
        VStack {
            headerVaultInformation
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

private extension ManageSharedVaultView {
    var headerVaultInformation: some View {
        VStack {
            ZStack {
                viewModel.vault.backgroundColor
                    .clipShape(Circle())

                viewModel.vault.bigImage
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(viewModel.vault.mainColor)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 64, height: 64)

            Text(viewModel.vault.name)
                .font(.title2.bold())
                .foregroundColor(PassColor.textNorm.toColor)
            Text("\(viewModel.itemsNumber) item(s)")
                .font(.title3)
                .foregroundColor(PassColor.textWeak.toColor)
        }
    }
}

private extension ManageSharedVaultView {
    var inviteeList: some View {
        ScrollView {
            VStack(spacing: 32) {
                if !viewModel.invitations.isEmpty {
                    inviteesSection(for: viewModel.invitations.invitees, title: "Invitations")
                }

                if !viewModel.members.isEmpty {
                    inviteesSection(for: viewModel.members, title: "Members")
                }
            }
        }
        .animation(.default, value: viewModel.invitations)
        .animation(.default, value: viewModel.members)
    }

    func inviteesSection(for invitees: [any ShareInvitee], title: LocalizedStringKey) -> some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PassColor.textWeak.toColor)

            LazyVStack {
                ForEach(Array(invitees.enumerated()), id: \.element.id) { index, invitee in
                    ShareInviteeView(invitee: invitee,
                                     isAdmin: viewModel.vault.isAdmin,
                                     isCurrentUser: viewModel.isCurrentUser(invitee),
                                     canTransferOwnership: viewModel.canTransferOwnership(to: invitee),
                                     onSelect: viewModel.handle(option:))
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

private extension ManageSharedVaultView {
    var shareButtonAndInfos: some View {
        VStack {
            DisablableCapsuleTextButton(title: #localized("Share with more people"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textInvert,
                                        backgroundColor: PassColor.interactionNorm,
                                        disableBackgroundColor: PassColor.interactionNorm
                                            .withAlphaComponent(0.5),
                                        disabled: !viewModel.canShare,
                                        action: viewModel.shareWithMorePeople)

            primaryVaultOnlyMessage

            Label(title: {
                Text("1 invite remaining")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: PassColor.textWeak))
            }, icon: {
                IconProvider.questionCircle.toImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16)
                    .foregroundColor(Color(uiColor: PassColor.textWeak))
            })
        }
    }
}

private extension ManageSharedVaultView {
    var primaryVaultOnlyMessage: some View {
        ZStack {
            Text("Your plan only allows to use items from your first vaults for autofill purposes.")
                .foregroundColor(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .foregroundColor(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
        .onTapGesture(perform: viewModel.upgrade)
    }
}

private extension ManageSharedVaultView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }
    }
}
