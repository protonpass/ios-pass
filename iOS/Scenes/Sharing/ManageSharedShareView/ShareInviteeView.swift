//
// ShareInviteeView.swift
// Proton Pass - Created on 18/10/2023.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ShareInviteeView: View {
    @State private var isExpanded = false
    let invitee: any ShareInvitee
    let isAdmin: Bool
    let isCurrentUser: Bool
    let canSeeAccessLevel: Bool
    let canTransferOwnership: Bool
    let onSelect: (ShareInviteeOption) -> Void

    var body: some View {
        if let pendingAccess = invitee.options.compactMap(\.pendingAccess).first {
            VStack {
                content
                CapsuleTextButton(title: #localized("Confirm access"),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  action: { onSelect(.confirmAccess(pendingAccess)) })
            }
        } else {
            content
        }
    }
}

private extension ShareInviteeView {
    var content: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            SquircleThumbnail(data: .initials(invitee.email.initials()),
                              tintColor: ItemType.login.tintColor,
                              backgroundColor: ItemType.login.backgroundColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(invitee.email)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .lineLimit(isExpanded ? nil : 1)
                    .onTapGesture {
                        isExpanded = true
                    }
                    .animation(.default, value: isExpanded)

                HStack {
                    if isCurrentUser {
                        Text("You")
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(PassColor.interactionNorm.toColor))
                    }
                    if canSeeAccessLevel {
                        Text(invitee.subtitle)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    } else {
                        Text(invitee.owner ? "Owner" : "Viewer")
                            .foregroundStyle(PassColor.textWeak.toColor)
                    }
                }
            }

            Spacer()

            if isAdmin, !isCurrentUser, !invitee.owner {
                trailingView
            }
        }
    }
}

private extension ShareInviteeView {
    @ViewBuilder
    var trailingView: some View {
        Menu(content: {
            ForEach(invitee.options) { option in
                switch option {
                case .remindExistingUserInvitation:
                    button(option: option,
                           title: "Resend invitation",
                           image: IconProvider.paperPlane)

                case .cancelExistingUserInvitation, .cancelNewUserInvitation:
                    button(option: option,
                           title: "Cancel invitation",
                           image: IconProvider.circleSlash)

                case let .updateRole(shareId, currentRole):
                    ForEach(ShareRole.allCases, id: \.self) { role in
                        Label(title: {
                            Button(action: {
                                onSelect(.updateRole(shareId: shareId, role: role))
                            }, label: {
                                Text(role.title)
                                Text(role.description(isItemSharing: invitee.shareType == .item))
                            })
                        }, icon: {
                            if currentRole == role {
                                Image(systemName: "checkmark")
                            }
                        })
                    }

                case .revokeAccess:
                    if !isCurrentUser {
                        button(option: option,
                               title: "Revoke access",
                               image: IconProvider.circleSlash)
                    }

                case .confirmTransferOwnership:
                    if canTransferOwnership {
                        button(option: option,
                               title: "Transfer ownership",
                               image: IconProvider.shieldHalfFilled)
                    }

                default:
                    // There're several not applicable options (e.g: confirm access)
                    EmptyView()
                }
            }
        }, label: { Image(uiImage: IconProvider.threeDotsVertical)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(PassColor.textWeak.toColor)
        })
    }

    func button(option: ShareInviteeOption, title: LocalizedStringKey, image: UIImage) -> some View {
        Button(action: {
            onSelect(option)
        }, label: {
            Label(title: {
                Text(title)
            }, icon: {
                Image(uiImage: image)
                    .renderingMode(.template)
                    .foregroundStyle(PassColor.textWeak.toColor)
            })
        })
    }
}
