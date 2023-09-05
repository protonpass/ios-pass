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
import ProtonCoreUIFoundations
import SwiftUI

struct UserPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    private let router = resolve(\RouterContainer.mainNavViewRouter)
    @StateObject private var viewModel = UserPermissionViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                emailDisplayView
                roleList
                Spacer()
            }
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

private extension UserPermissionView {
    var headerView: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Set permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(PassColor.textNorm.toColor)
            Text("Select the level of access this user will gain when they join your ‘\(viewModel.vaultName)’ vault")
                .font(.body)
                .foregroundColor(PassColor.textWeak.toColor)
        }
    }
}

private extension UserPermissionView {
    var emailDisplayView: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            SquircleThumbnail(data: .initials(viewModel.email.initialsRemovingEmojis()),
                              tintColor: ItemType.login.tintColor,
                              backgroundColor: ItemType.login.backgroundColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.email)
                    .foregroundColor(PassColor.textNorm.toColor)
            }
        }
        .frame(height: 60)
    }
}

private extension UserPermissionView {
    var roleList: some View {
        VStack(spacing: 12) {
            ForEach(ShareRole.allCases.reversed(), id: \.self) { role in
                Button {
                    viewModel.select(role: role)
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
            DisablableCapsuleTextButton(title: "Continue".localized,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        action: { viewModel.goToNextStep = true })
        }
    }
}

struct UserPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        UserPermissionView()
    }
}
