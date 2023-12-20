//
//
// UserPermissionView.swift
// Proton Pass - Created on 20/07/2023.
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

struct UserPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    private let router = resolve(\RouterContainer.mainNavViewRouter)
    @StateObject private var viewModel = UserPermissionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Set access level")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(PassColor.textNorm.toColor)
            if viewModel.hasOnlyOneInvite,
               let email = viewModel.emails.keys.first {
                emailDisplayView(email: email)
                roleList(email: email)
            } else {
                inviteeList
            }
            Spacer()
        }
        .navigate(isActive: $viewModel.goToNextStep, destination: router.navigate(to: .shareSummary))
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
    }

    @ViewBuilder
    func butonDisplay(with permission: ShareRole) -> some View {
        if viewModel.selectedUserRole == permission {
            Circle()
                .fill(PassColor.interactionNormMajor1.toColor)
                .frame(width: 15, height: 15)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Multiple Emails

private extension UserPermissionView {
    var inviteeList: some View {
        ScrollView {
            VStack(spacing: 32) {
                if !viewModel.emails.isEmpty {
                    inviteesSection(for: viewModel.emails, title: "Members")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.default, value: viewModel.emails)
    }

    func inviteesSection(for emails: [String: ShareRole], title: LocalizedStringKey) -> some View {
        VStack {
            Menu {
                Text("Set access level for all members")
                    .font(.footnote)
                ForEach(ShareRole.allCases, id: \.self) { role in
                    Button(action: {
                        viewModel.setRoleForAll(with: role)
                    }, label: {
                        Text(role.title)
                        Text(role.description)
                    })
                }
            } label: {
                HStack {
                    Text(title)
                    Text("[\(viewModel.emails.count)]")
                    Image(uiImage: IconProvider.chevronDown)
                }
                .foregroundColor(PassColor.interactionNorm.toColor)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(PassColor.interactionNorm.toColor, lineWidth: 1))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 15)
            .padding(.top, 10)
            .padding(.horizontal, 10)

            LazyVStack {
                ForEach(Array(emails.keys), id: \.self) { email in
                    HStack(spacing: kItemDetailSectionPadding) {
                        SquircleThumbnail(data: .initials(email.initials()),
                                          tintColor: ItemType.login.tintColor,
                                          backgroundColor: ItemType.login.backgroundColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(email)
                                .foregroundColor(PassColor.textNorm.toColor)
                            if let currentRole = viewModel.emails[email] {
                                HStack {
                                    Text(currentRole.title)
                                        .foregroundColor(PassColor.textWeak.toColor)
                                }
                            }
                        }

                        Spacer()
                        if let currentRole = viewModel.emails[email] {
                            trailingView(email: email, currentRole: currentRole)
                        }
                    }.padding(8)
                }
                .listRowSeparator(.hidden)
            }
        }
    }

    @ViewBuilder
    func trailingView(email: String, currentRole: ShareRole) -> some View {
        Menu(content: {
            ForEach(ShareRole.allCases, id: \.self) { role in
                Label(title: {
                    Button(action: {
                        viewModel.updateRole(for: email, with: role)
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
        }, label: { Image(uiImage: IconProvider.threeDotsVertical)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundColor(PassColor.textWeak.toColor)
        })
    }
}

// MARK: - Single Email

private extension UserPermissionView {
    func emailDisplayView(email: String) -> some View {
        HStack(spacing: kItemDetailSectionPadding) {
            SquircleThumbnail(data: .initials(email.initials()),
                              tintColor: ItemType.login.tintColor,
                              backgroundColor: ItemType.login.backgroundColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(email)
                    .foregroundColor(PassColor.textNorm.toColor)
            }
        }
        .frame(height: 60)
    }
}

private extension UserPermissionView {
    func roleList(email: String) -> some View {
        VStack(spacing: 12) {
            ForEach(ShareRole.allCases.reversed(), id: \.self) { role in
                Button {
                    viewModel.updateRole(for: email, with: role)
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(role.title)
                                .font(.body)
                                .foregroundColor(PassColor.textNorm.toColor)
                                .padding(.bottom, 2)

                            Text(role.description)
                                .font(.body)
                                .foregroundColor(PassColor.textWeak.toColor)
                        }
                        Spacer()

                        Circle()
                            .strokeBorder(viewModel.selectedUserRole == role ? PassColor
                                .interactionNormMajor1.toColor : PassColor.textWeak.toColor,
                                lineWidth: 2)
                            .overlay(butonDisplay(with: role))
                            .frame(width: 24, height: 24)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(16)
                    .contentShape(Rectangle())
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(viewModel.selectedUserRole == role ? PassColor
                            .interactionNormMajor1
                            .toColor : PassColor.textWeak.toColor,
                            lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.default, value: viewModel.selectedUserRole)
    }
}

private extension UserPermissionView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Continue"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        action: { viewModel.goToNextStep = true })
        }
    }
}

#Preview("UserPermissionView Preview") {
    UserPermissionView()
}
