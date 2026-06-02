//
// SuggestedEmailView.swift
// Proton Pass - Created on 15/12/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

public struct SuggestedEmailView: View {
    private let recommendation: InviteRecommendationType
    private let isSelected: Bool
    private let onSelect: () -> Void

    public init(recommendation: InviteRecommendationType, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.recommendation = recommendation
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack {
            SquircleThumbnail(data: recommendation
                .isEmail ? .initials(String(recommendation.name.prefix(2).uppercased())) :
                .icon(IconProvider.users),
                tintColor: PassColor.interactionNormMajor2,
                backgroundColor: PassColor.interactionNormMinor1)

            Spacer()

            Text(name)
                .foregroundStyle(PassColor.textNorm)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            RoundedCircleCheckbox(isChecked: isSelected)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
    }

    private var name: String {
        switch recommendation {
        case let .email(email):
            return email

        case .group:
            guard let memberCounts = recommendation.memberCount else {
                return recommendation.name
            }
            return recommendation.name + " " + #localized("(%lld members)", bundle: .module, memberCounts)
        }
    }
}
