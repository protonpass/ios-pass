//
// ContactRow.swift
// Proton Pass - Created on 05/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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

struct ContactRow: View {
    let contact: AliasContact
    let onSend: () -> Void
    let onCopyAddress: () -> Void
    let onToggleState: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            HStack {
                Text(verbatim: contact.email)
                    .foregroundStyle(PassColor.textNorm)

                Spacer()

                if !contact.blocked {
                    Button(action: onSend) {
                        Image(uiImage: IconProvider.paperPlane)
                            .foregroundStyle(PassColor.textWeak)
                    }
                    .padding(.trailing, DesignConstant.sectionPadding)
                }

                Menu(content: {
                    if !contact.blocked {
                        button(title: "Send email",
                               icon: IconProvider.paperPlane,
                               action: onSend)
                    }

                    button(title: "Copy forwarding address",
                           icon: IconProvider.squares,
                           action: onCopyAddress)

                    Divider()

                    button(title: contact.actionTitle,
                           icon: contact.actionIcon,
                           action: onToggleState)

                    button(title: "Delete",
                           icon: IconProvider.trash,
                           action: onDelete)
                }, label: {
                    IconProvider.threeDotsVertical
                        .foregroundStyle(PassColor.textWeak)
                })
            }

            VStack(alignment: .leading) {
                Text("Created \(contact.createTime.fullDateString)")
                Text(contact.activityText)
            }
            .font(.footnote)
            .foregroundStyle(PassColor.textWeak)

            Text(contact.actionTitle)
                .font(.callout)
                .foregroundStyle(PassColor.aliasInteractionNormMajor2)
                .frame(height: 40)
                .padding(.horizontal, 16)
                .background(contact.blocked ? .clear : PassColor.aliasInteractionNormMinor1)
                .clipShape(Capsule())
                .buttonEmbeded(action: onToggleState)
                .overlay(Capsule()
                    .stroke(PassColor.aliasInteractionNormMinor1, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.inputBackgroundNorm)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PassColor.inputBorderNorm, lineWidth: 1))
    }

    func button(title: LocalizedStringKey,
                icon: Image,
                action: @escaping () -> Void) -> some View {
        Button { action() } label: {
            Label(title: { Text(title) }, icon: { icon })
        }
    }
}

private extension AliasContact {
    var actionTitle: LocalizedStringKey {
        blocked ? "Unblock contact" : "Block contact"
    }

    var actionIcon: Image {
        blocked ? IconProvider.envelopeOpenText.toImage : IconProvider.circleSlash.toImage
    }

    var activityText: String {
        let forwarded = #localized("%lld forwarded", forwardedEmails)
        let replies = #localized("%lld replies", repliedEmails)
        let blocked = #localized("%lld blocked", blockedEmails)
        return noActivity ? #localized("No activity in the last 14 days.") :
            #localized("%1$@, %2$@, %3$@ in the last 14 days.", forwarded, replies, blocked)
    }
}
