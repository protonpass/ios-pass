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

public struct AccountCellDetail: Identifiable, Hashable {
    public let id: String
    public let isPremium: Bool
    public let initial: String
    public let displayName: String
    public let planName: String?
    public let email: String

    public init(id: String,
                isPremium: Bool,
                initial: String,
                displayName: String,
                planName: String?,
                email: String) {
        self.id = id
        self.isPremium = isPremium
        self.initial = initial
        self.displayName = displayName
        self.planName = planName
        self.email = email
    }

    public static var empty: Self {
        .init(id: UUID().uuidString,
              isPremium: false,
              initial: "",
              displayName: "",
              planName: nil,
              email: "")
    }
}

public struct AccountCell: View {
    let detail: AccountCellDetail
    let isActive: Bool
    let showInactiveIcon: Bool
    let animationNamespace: Namespace.ID

    enum EffectID: String {
        case initial
        case displayName
        case planName
        case email
        case chevron

        func fullId(itemId: String) -> String {
            "\(rawValue)\(itemId)"
        }
    }

    public init(detail: AccountCellDetail,
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
            initial
                .matchedGeometryEffect(id: EffectID.initial.fullId(itemId: detail.id),
                                       in: animationNamespace)
                .padding(.trailing)

            VStack(alignment: .leading) {
                displayName
                    .matchedGeometryEffect(id: EffectID.displayName.fullId(itemId: detail.id),
                                           in: animationNamespace)

                planName
                    .matchedGeometryEffect(id: EffectID.planName.fullId(itemId: detail.id),
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
    var initial: some View {
        ZStack {
            PassColor.interactionNormMajor1
            Text(verbatim: detail.initial)
                .foregroundStyle(PassColor.textInvert)
                .fontWeight(.medium)
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    var displayName: some View {
        if detail.displayName.isEmpty {
            EmptyView()
        } else {
            Text(verbatim: detail.displayName)
                .foregroundStyle(PassColor.textNorm)
        }
    }

    @ViewBuilder
    var planName: some View {
        if let planName = detail.planName {
            Text(verbatim: planName)
                .font(.caption)
                .foregroundStyle(detail.isPremium ? PassColor.noteInteractionNormMajor2 : PassColor.textNorm)
        } else {
            EmptyView()
        }
    }

    var email: some View {
        Text(verbatim: detail.email)
            .font(.caption)
            .foregroundStyle(PassColor.textWeak)
    }
}
