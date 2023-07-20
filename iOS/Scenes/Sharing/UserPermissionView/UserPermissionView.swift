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

import Factory
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct UserPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    private var router = resolve(\RouterContainer.mainNavViewRouter)
    @StateObject private var viewModel = UserPermissionViewModel()
    @State var goToNextStep = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NavigationLink(destination: router.navigate(to: .shareSummary),
                           isActive: $goToNextStep) { EmptyView() }

            headerView
            emailDisplayView
            roleList
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
    }

    @ViewBuilder
    func butonDisplay(with permission: UserPermission) -> some View {
        if viewModel.selectedUserPermission == permission {
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
            Text("Select the level of access this user will gain when they join your ‘\(viewModel.vaultName)’ vault.")
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
            ForEach(UserPermission.allCases, id: \.self) { permission in
                Button {
                    viewModel.select(permission: permission)
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text(permission.title)
                                .font(.body)
                                .foregroundColor(PassColor.textNorm.toColor)
                                .padding(.bottom, 5)

                            Text(permission.description)
                                .font(.body)
                                .foregroundColor(PassColor.textWeak.toColor)
                        }
                        Spacer()

                        Circle()
                            .strokeBorder(viewModel.selectedUserPermission == permission ? PassColor
                                .interactionNormMajor1.toColor : PassColor.textWeak.toColor,
                                lineWidth: 2)
                            .overlay(butonDisplay(with: permission))
                            .frame(width: 24, height: 24)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.selectedUserPermission == permission ? PassColor
                            .interactionNormMajor1
                            .toColor : PassColor.textWeak.toColor,
                            lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension UserPermissionView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: "Continue",
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        action: { goToNextStep = true })
        }
    }
}

struct UserPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        UserPermissionView()
    }
}

//
// struct ItemDetailTitleView: View {
//    let itemContent: ItemContent
//    let vault: Vault?
//    let favIconRepository: FavIconRepositoryProtocol
//
//    var body: some View {
//        HStack(spacing: kItemDetailSectionPadding) {
//            ItemSquircleThumbnail(data: itemContent.thumbnailData(),
//                                  repository: favIconRepository,
//                                  size: .large)
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(itemContent.name)
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .textSelection(.enabled)
//                    .lineLimit(1)
//                    .foregroundColor(Color(uiColor: PassColor.textNorm))
//
//                if let vault {
//                    VaultLabel(vault: vault)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .frame(height: 60)
//    }
// }
