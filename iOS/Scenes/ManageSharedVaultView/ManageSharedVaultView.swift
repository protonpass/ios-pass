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

import Factory
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct ManageSharedVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManageSharedVaultViewModel()
    private let router = resolve(\RouterContainer.mainUIKitSwiftUIRouter)

    var body: some View {
        ZStack(alignment: .bottom) {
            mainContainer
            CapsuleTextButton(title: "Share with more people",
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              action: { router.presentSheet(for: .sharingFlow) })
        }
    }
}

private extension ManageSharedVaultView {
    var mainContainer: some View {
        VStack {
            headerVaultInformation
            userList
        }
//        .animation(.default, value: viewModel.error)
//        .navigate(isActive: $viewModel.goToNextStep, destination: router.navigate(to: .userSharePermission))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
//        .ignoresSafeArea(.keyboard)
    }
}

private extension ManageSharedVaultView {
    var headerVaultInformation: some View {
        VStack {
            ZStack {
//                Color(uiColor: infos.display.color.color.color.withAlphaComponent(0.16))
//                    .clipShape(Circle())
                Color.purple
                    .clipShape(Circle())

//                Image(uiImage: infos.display.icon.icon.bigImage)
                Image(systemName: "heart")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color.purple) // infos.display.color.color.color.toColor)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 64, height: 64)

            Text("Family") // infos.name)
                .font(.title2.bold())
                .foregroundColor(PassColor.textNorm.toColor)
            Text("65 items") // viewModel.userInvite.vaultsCountInfos)
                .font(.title3)
                .foregroundColor(PassColor.textWeak.toColor)
        }
    }
}

private extension ManageSharedVaultView {
    var userList: some View {
        List {}
    }
}

private extension ManageSharedVaultView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }
    }
}

struct ManageSharedVaultView_Previews: PreviewProvider {
    static var previews: some View {
        ManageSharedVaultView()
    }
}

//
//
// VStack(alignment: .leading, spacing: 31) {
//    headerView
//
//    emailTextField
//
//    Spacer()
// }
// .onAppear {
//    if #available(iOS 16, *) {
//        defaultFocus = true
//    } else {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
//            defaultFocus = true
//        }
//    }
// }
// .animation(.default, value: viewModel.error)
// .navigate(isActive: $viewModel.goToNextStep, destination: router.navigate(to: .userSharePermission))
// .frame(maxWidth: .infinity, maxHeight: .infinity)
// .padding(kItemDetailSectionPadding)
// .navigationBarTitleDisplayMode(.inline)
// .background(Color(uiColor: PassColor.backgroundNorm))
// .toolbar { toolbarContent }
// .ignoresSafeArea(.keyboard)
// .navigationModifier()
