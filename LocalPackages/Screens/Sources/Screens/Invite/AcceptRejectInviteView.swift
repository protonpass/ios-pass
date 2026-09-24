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

import DesignSystem
import Entities
import Macro
import SwiftUI

public struct AcceptRejectInviteView: View {
    @State private var viewModel: AcceptRejectInviteViewModel

    public init(invite: Invite, onResult: @escaping (AcceptRejectInviteResult) -> Void) {
        _viewModel = .init(wrappedValue: .init(invite: invite, onResult: onResult))
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack {
                    if viewModel.invite.fromNewUser {
                        Text("Congratulations,\n your access has been confirmed", bundle: .module)
                            .font(.title2.bold())
                            .foregroundStyle(PassColor.textNorm)
                            .multilineTextAlignment(.center)
                    } else {
                        senderEmailInfo
                    }

                    if viewModel.invite.isVault {
                        if let infos = viewModel.vaultInfos {
                            vaultInformation(infos: infos)
                        } else {
                            ProgressView()
                        }
                        Spacer()
                    }

                    actionButtons
                }
                .frame(minHeight: geometry.size.height)
            }
            .frame(width: geometry.size.width)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(PassColor.backgroundWeak)
        .animation(.default, value: viewModel.vaultInfos)
        .task {
            await viewModel.decodeVaultDataIfApplicable()
        }
        .showSpinner(viewModel.executingAction)
    }
}

private extension AcceptRejectInviteView {
    var senderEmailInfo: some View {
        VStack(alignment: .center) {
            if viewModel.invite.isVault {
                Text(verbatim: viewModel.invite.inviterEmail)
                    .fontWeight(.bold)
                switch viewModel.invite {
                case .user:
                    Text("invites you to access items in", bundle: .module)

                case .group:
                    Text("invites the group \(viewModel.invitedGroupName) to access items in",
                         bundle: .module)
                }
            } else {
                Text("Shared item invitation", bundle: .module)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 16)
                switch viewModel.invite {
                case .user:
                    Text("\(viewModel.invite.inviterEmail) wants to share an item with you.",
                         bundle: .module)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)

                case .group:
                    // swiftlint:disable:next line_length
                    Text("\(viewModel.invite.inviterEmail) wants to share an item with the group \(viewModel.invitedGroupName).",
                         bundle: .module)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                }
            }
        }
        .foregroundStyle(PassColor.textNorm)
    }
}

private extension AcceptRejectInviteView {
    func vaultInformation(infos: VaultContent) -> some View {
        VStack {
            CircleButton(icon: infos.vaultBigIcon,
                         iconColor: infos.mainColor,
                         backgroundColor: infos.backgroundColor,
                         type: .custom(buttonSize: 64, iconSize: 28))

            Text(verbatim: infos.name)
                .font(.title2.bold())
                .foregroundStyle(PassColor.textNorm)
            Text(verbatim: viewModel.invite.vaultsCountInfos)
                .font(.title3)
                .foregroundStyle(PassColor.textWeak)
        }
    }
}

private extension AcceptRejectInviteView {
    var actionButtons: some View {
        VStack {
            CapsuleTextButton(title: viewModel.invite.acceptButtonTitle,
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              action: { viewModel.accept() })

            CapsuleTextButton(title: viewModel.invite.rejectButtonTitle,
                              titleColor: PassColor.interactionNormMajor1,
                              backgroundColor: PassColor.interactionNormMinor1,
                              action: { viewModel.reject() })
        }
    }
}

private extension Invite {
    var acceptButtonTitle: String {
        switch self {
        case .user:
            isVault ? fromNewUser ? #localized("See the shared vault", bundle: .module) :
                #localized("Join shared vault", bundle: .module) :
                #localized("Accept and view the item", bundle: .module)

        case .group:
            #localized("Accept invitation", bundle: .module)
        }
    }

    var rejectButtonTitle: String {
        fromNewUser ? #localized("Close", bundle: .module) : #localized("Reject invitation", bundle: .module)
    }

    var vaultsCountInfos: String {
        let itemsCount = #localized("%lld item(s)", bundle: .module, vaultData?.itemCount ?? 0)
        let membersCount = #localized("%lld member(s)", bundle: .module, vaultData?.memberCount ?? 0)
        return "\(itemsCount) • \(membersCount)"
    }
}
