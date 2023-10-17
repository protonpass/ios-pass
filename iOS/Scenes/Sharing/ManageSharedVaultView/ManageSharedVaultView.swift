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

            if viewModel.canShare {
                CapsuleTextButton(title: #localized("Share with more people"),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNorm,
                                  action: viewModel.shareWithMorePeople)
            }
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
                                          action: viewModel.transferOwnership),
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
                userList
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
    var userList: some View {
        ScrollView {
            VStack(spacing: 32) {
                if !viewModel.invitations.isEmpty {
                    entriesSection(for: viewModel.invitations.invitees, title: #localized("Invitations"))
                }

                if !viewModel.members.isEmpty {
                    entriesSection(for: viewModel.members, title: #localized("Members"))
                }
            }
        }
        .animation(.default, value: viewModel.invitations)
        .animation(.default, value: viewModel.members)
    }

    func entriesSection(for invitees: [any ShareInvitee], title: String) -> some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(PassColor.textWeak.toColor)

            LazyVStack {
                ForEach(Array(invitees.enumerated()), id: \.element.id) { index, invitee in
                    entryCell(for: invitee)
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

    func entryCell(for invitee: any ShareInvitee) -> some View {
        HStack(spacing: kItemDetailSectionPadding) {
            SquircleThumbnail(data: .initials(invitee.email.initials()),
                              tintColor: ItemType.login.tintColor,
                              backgroundColor: ItemType.login.backgroundColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(invitee.email)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .lineLimit(viewModel.isExpanded(email: invitee.email) ? nil : 1)
                    .onTapGesture {
                        viewModel.expand(email: invitee.email)
                    }
                    .animation(.default, value: viewModel.expandedEmails)

                HStack {
                    if viewModel.isCurrentUser(invitee) {
                        Text("You")
                            .font(.body)
                            .foregroundColor(PassColor.textNorm.toColor)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(PassColor.interactionNorm.toColor))
                    }
                    Text(invitee.subtitle)
                        .foregroundColor(PassColor.textWeak.toColor)
                }
            }

            Spacer()

            if viewModel.vault.isAdmin, !viewModel.isCurrentUser(invitee) {
                entryCellTrailingView(for: invitee)
            }
        }
    }

    @ViewBuilder
    func entryCellTrailingView(for invitee: any ShareInvitee) -> some View {
        Menu(content: {
            ForEach(invitee.options) { option in
                switch option {
                case let .resendInvitation(inviteId):
                    Button(action: {
                        viewModel.sendInviteReminder(inviteId: inviteId)
                    }, label: {
                        Label(title: {
                            Text("Resend invitation")
                        }, icon: {
                            Image(uiImage: IconProvider.paperPlane)
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: PassColor.textWeak))
                        })
                    })

                case let .cancelInvitation(inviteId):
                    Button(action: {
                        viewModel.revokeInvite(inviteId: inviteId)
                    }, label: {
                        Label(title: {
                            Text("Cancel invitation")
                        }, icon: {
                            Image(uiImage: IconProvider.circleSlash)
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: PassColor.textWeak))
                        })
                    })

                case let .updateRole(shareId, currentRole):
                    ForEach(ShareRole.allCases, id: \.self) { role in
                        Label(title: {
                            Button(action: {
                                viewModel.updateRole(userSharedId: shareId, role: role)
                            }, label: {
                                Text(role.title)
                                Text(role.description)
                            })
                        }, icon: {
                            if currentRole == role {
                                Image(systemName: "checkmark")
                            }
                        })
                    }

                case let .revokeAccess(shareId):
                    Button(action: {
                        viewModel.revokeShareAccess(shareId: shareId)
                    }, label: {
                        Label(title: {
                            Text("Revoke access")
                        }, icon: {
                            Image(uiImage: IconProvider.circleSlash)
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: PassColor.textWeak))
                        })
                    })

                case let .transferOwnership(newOwner):
                    Button(action: {
                        viewModel.newOwner = newOwner
                    }, label: {
                        Label(title: {
                            Text("Transfer ownership")
                        }, icon: {
                            Image(uiImage: IconProvider.shieldHalfFilled)
                                .renderingMode(.template)
                                .foregroundColor(Color(uiColor: PassColor.textWeak))
                        })
                    })
                }
            }
        }, label: { Image(uiImage: IconProvider.threeDotsVertical)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundColor(Color(uiColor: PassColor.textWeak))
        })
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
