//
// AccountCell.swift
// Proton Pass - Created on 26/06/2024.
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
//

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public protocol AccountCellDetail: Sendable, Identifiable {
    var id: String { get }
    var initials: String { get }
    var displayName: String { get }
    var email: String { get }
}

public struct AccountCell: View {
    let detail: any AccountCellDetail
    let isActive: Bool
    let showInactiveIcon: Bool
    let animationNamespace: Namespace.ID

    enum EffectID: String {
        case initials
        case displayName
        case email
        case chevron

        func fullId(itemId: String) -> String {
            "\(rawValue)\(itemId)"
        }
    }

    public init(detail: any AccountCellDetail,
                isActive: Bool = false,
                showInactiveIcon: Bool = true,
                animationNamespace: Namespace.ID) {
        self.detail = detail
        self.isActive = isActive
        self.showInactiveIcon = showInactiveIcon
        self.animationNamespace = animationNamespace
    }

    public var body: some View {
        HStack {
            initials
                .matchedGeometryEffect(id: EffectID.initials.fullId(itemId: detail.id),
                                       in: animationNamespace)

            VStack(alignment: .leading) {
                displayName
                    .matchedGeometryEffect(id: EffectID.displayName.fullId(itemId: detail.id),
                                           in: animationNamespace)

                email
                    .matchedGeometryEffect(id: EffectID.email.fullId(itemId: detail.id),
                                           in: animationNamespace)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            SwiftUIImage(image: isActive ? IconProvider.checkmark : IconProvider.chevronDown,
                         width: isActive ? 24 : 20,
                         tintColor: isActive ? PassColor.interactionNormMajor2 : PassColor.textWeak)
                .matchedGeometryEffect(id: AccountCell.EffectID.chevron.fullId(itemId: detail.id),
                                       in: animationNamespace)
                .hidden(!showIcon)
        }
        .contentShape(.rect)
    }

    var showIcon: Bool {
        if isActive || showInactiveIcon {
            return true
        }

        return false
    }
}

private extension AccountCell {
    var initials: some View {
        ZStack {
            PassColor.interactionNormMajor2.toColor
            Text(verbatim: detail.initials)
                .foregroundStyle(PassColor.textInvert.toColor)
                .fontWeight(.medium)
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var displayName: some View {
        Text(verbatim: detail.displayName)
            .foregroundStyle(PassColor.textNorm.toColor)
    }

    var email: some View {
        Text(verbatim: detail.email)
            .font(.caption)
            .foregroundStyle(PassColor.textWeak.toColor)
    }
}
