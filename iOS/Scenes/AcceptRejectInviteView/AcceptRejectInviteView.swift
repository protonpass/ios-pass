//
//
// AcceptRejectInviteView.swift
// Proton Pass - Created on 27/07/2023.
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
import Entities
import SwiftUI
import UIComponents

struct AcceptRejectInviteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AcceptRejectInviteViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack {
                    senderEmailInfo
                    Spacer()
                    if let infos = viewModel.vaultInfos {
                        vaultInformation(infos: infos)
                    } else {
                        ProgressView()
                    }
                    Spacer()
                    actionButtons
                }
                .frame(minHeight: geometry.size.height)
            }
            .frame(width: geometry.size.width)
        }
        .errorAlert(error: $viewModel.error)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .animation(.default, value: viewModel.vaultInfos)
        .showSpinner(viewModel.executingAction)
        .onChange(of: viewModel.shouldCloseSheet) { value in
            guard value else {
                return
            }
            dismiss()
        }
    }
}

private extension AcceptRejectInviteView {
    var senderEmailInfo: some View {
        VStack {
            Text("Invitation from")
            Text(viewModel.userInvite.inviterEmail)
        }
        .font(.body)
        .foregroundColor(PassColor.textNorm.toColor)
    }
}

private extension AcceptRejectInviteView {
    func vaultInformation(infos: VaultProtobuf) -> some View {
        VStack {
            ZStack {
                Color(uiColor: infos.display.color.color.color.withAlphaComponent(0.16))
                    .clipShape(Circle())

                Image(uiImage: infos.display.icon.icon.bigImage)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(infos.display.color.color.color.toColor)
                    .frame(width: 28, height: 28)
            }
            .frame(width: 64, height: 64)

            Text(infos.name)
                .font(.title2)
                .foregroundColor(PassColor.textNorm.toColor)
            Text("\(viewModel.userInvite.vaultData.itemCount) items • \(viewModel.userInvite.vaultData.memberCount) members")
                .font(.title3)
                .foregroundColor(PassColor.textWeak.toColor)
        }
    }
}

private extension AcceptRejectInviteView {
    var actionButtons: some View {
        VStack {
            Button { viewModel.accept() } label: {
                HStack(alignment: .center, spacing: 4) {
                    Spacer()

                    Text("Join shared vault")
                        .font(.body)
                        .foregroundColor(PassColor.textInvert.toColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(PassColor.interactionNorm.toColor)
                .cornerRadius(32)
            }

            Button { viewModel.reject() } label: {
                HStack(alignment: .center, spacing: 4) {
                    Spacer()
                    Text("Reject invitation")
                        .font(.body)
                        .foregroundColor(PassColor.interactionNormMajor1.toColor)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(PassColor.interactionNormMinor1.toColor)
                .cornerRadius(32)
            }
        }
    }
}

struct AcceptRejectInviteView_Previews: PreviewProvider {
    static var previews: some View {
        AcceptRejectInviteView(viewModel: AcceptRejectInviteViewModel(invite: UserInvite.mocked))
    }
}
