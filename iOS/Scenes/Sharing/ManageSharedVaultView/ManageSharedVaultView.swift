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

            if viewModel.vault.canShareVaultWithMorePeople {
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
        .alert(item: $viewModel.newOwner) { user in
            Alert(title: Text("Transfer ownership"),
                  message: Text("Transfer ownership of this vault to \(user.email)?"),
                  primaryButton: .default(Text("Confirm")) {
                      viewModel.transferOwnership(to: user)
                  },
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
            LazyVStack {
                ForEach(viewModel.users, id: \.self) { user in
                    userCell(for: user)
                        .padding(16)
                    if !viewModel.isLast(info: user) {
                        Divider()
                    }
                }
                .listRowSeparator(.hidden)
            }
            .roundedEditableSection()
        }
        .animation(.default, value: viewModel.users.count)
    }

    func userCell(for user: ShareUser) -> some View {
        HStack(spacing: kItemDetailSectionPadding) {
            SquircleThumbnail(data: .initials(user.email.initials()),
                              tintColor: ItemType.login.tintColor,
                              backgroundColor: ItemType.login.backgroundColor)
            VStack(alignment: .leading, spacing: 4) {
                Label(title: {
                    Text(user.email)
                        .font(user.isPending ? .body.italic() : .body)
                        .foregroundColor(PassColor.textNorm.toColor)
                        .lineLimit(viewModel.isExpanded(email: user.email) ? nil : 1)
                        .onTapGesture {
                            viewModel.expand(email: user.email)
                        }
                        .animation(.default, value: viewModel.expandedEmails)
                }, icon: {
                    if user.isPending {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(PassColor.textWeak.toColor)
                            .font(.callout)
                    }
                })

                HStack {
                    if viewModel.isCurrentUser(with: user) {
                        Text("You")
                            .font(.body)
                            .foregroundColor(PassColor.textNorm.toColor)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(PassColor.interactionNorm.toColor))
                    }
                    Text(user.permission)
                        .foregroundColor(PassColor.textWeak.toColor)
                }
            }

            Spacer()
            if viewModel.vault.isAdmin, !user.isOwner {
                vaultTrailingView(user: user)
                    .onTapGesture {
                        viewModel.setCurrentRole(for: user)
                    }
            }
        }
    }
}

private extension ManageSharedVaultView {
    @ViewBuilder
    func vaultTrailingView(user: ShareUser) -> some View {
        let isOwnerAndCurrentUser = viewModel.isOwnerAndCurrentUser(with: user)
        Menu(content: {
            if !isOwnerAndCurrentUser, !user.isPending {
                ForEach(ShareRole.allCases, id: \.self) { role in
                    Label(title: {
                        Button(action: {
                            if viewModel.userRole != role {
                                viewModel.userRole = role
                            }
                        }, label: {
                            Text(role.title)
                            Text(role.description)
                        })
                    }, icon: {
                        if viewModel.userRole == role {
                            Image(systemName: "checkmark")
                        }
                    })
                }
            }

            if user.isPending {
                Button(action: {
                    viewModel.sendInviteReminder(for: user)
                }, label: {
                    Label(title: {
                        Text("Resend invitation")
                    }, icon: {
                        Image(uiImage: IconProvider.paperPlane)
                            .renderingMode(.template)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    })
                })
            }

            if viewModel.canTransferOwnership(to: user) {
                Button(action: {
                    viewModel.newOwner = user
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

            if !isOwnerAndCurrentUser {
                Button(action: {
                    if user.isPending {
                        viewModel.revokeInvite(for: user)
                    } else {
                        viewModel.revokeShareAccess(for: user)
                    }
                }, label: {
                    Label(title: {
                        Text(user.isPending ? "Cancel invitation" : "Revoke access")
                    }, icon: {
                        Image(uiImage: IconProvider.circleSlash)
                            .renderingMode(.template)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    })
                })
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
