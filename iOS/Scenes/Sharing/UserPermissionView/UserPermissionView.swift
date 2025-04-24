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
    @EnvironmentObject private var router: PathRouter
    @StateObject private var viewModel = UserPermissionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Set access level")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm.toColor)
            if viewModel.hasOnlyOneInvite,
               let email = viewModel.emails.keys.first {
                emailDisplayView(email: email)
                roleList(email: email)
            } else {
                inviteeList
            }
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignConstant.sectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
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
        VStack {
            HStack {
                Text("Members")
                    .font(.headline)
                    .fontWeight(.bold) +
                    Text(verbatim: " (\(viewModel.emails.count))")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                setAccessLevelMenu
            }
            .foregroundStyle(PassColor.textWeak.toColor)
            .frame(maxWidth: .infinity)

            inviteeList(for: viewModel.emails)
        }
        .frame(maxWidth: .infinity)
        .scrollViewEmbeded(maxWidth: .infinity)
    }

    var setAccessLevelMenu: some View {
        Menu {
            Section("Set access level for all members") {
                ForEach(ShareRole.allCases, id: \.self) { role in
                    Button(action: {
                        viewModel.setRoleForAll(with: role)
                    }, label: {
                        Text(role.title(managerAsAdmin: viewModel.managerAsAdmin))
                        Text(role.description(isItemSharing: viewModel.isItemSharing))
                    })
                }
            }
        } label: {
            Label("Set access level", systemImage: "chevron.down")
                .labelStyle(.rightIcon)
                .foregroundStyle(PassColor.interactionNorm.toColor)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(PassColor.interactionNorm.toColor, lineWidth: 1))
        }
    }

    func inviteeList(for emails: [String: ShareRole]) -> some View {
        LazyVStack {
            ForEach(Array(emails.keys), id: \.self) { email in
                HStack(spacing: DesignConstant.sectionPadding) {
                    SquircleThumbnail(data: .initials(email.initials()),
                                      tintColor: PassColor.interactionNormMajor2,
                                      backgroundColor: PassColor.interactionNormMinor1)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(email)
                            .foregroundStyle(PassColor.textNorm.toColor)
                        if let currentRole = viewModel.emails[email] {
                            HStack {
                                Text(currentRole.title(managerAsAdmin: viewModel.managerAsAdmin))
                                    .foregroundStyle(PassColor.textWeak.toColor)
                            }
                        }
                    }

                    Spacer()
                    if let currentRole = viewModel.emails[email] {
                        trailingView(email: email, currentRole: currentRole)
                    }
                }
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
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
                        Text(role.title(managerAsAdmin: viewModel.managerAsAdmin))
                        Text(role.description(isItemSharing: viewModel.isItemSharing))
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
            .foregroundStyle(PassColor.textWeak.toColor)
        })
    }
}

// MARK: - Single Email

private extension UserPermissionView {
    func emailDisplayView(email: String) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            SquircleThumbnail(data: .initials(email.initials()),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)
            VStack(alignment: .leading, spacing: 4) {
                Text(email)
                    .foregroundStyle(PassColor.textNorm.toColor)
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
                            Text(role.title(managerAsAdmin: viewModel.managerAsAdmin))
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding(.bottom, 2)

                            Text(role.description(isItemSharing: viewModel.isItemSharing))
                                .foregroundStyle(PassColor.textWeak.toColor)
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
                    .contentShape(.rect)
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
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Go back",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Continue"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        action: { router.navigate(to: .shareSummary) })
        }
    }
}

#Preview("UserPermissionView Preview") {
    UserPermissionView()
}
