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
import SwiftUI

struct SuggestedEmailView: View {
    private let email: String
    private let isSelected: Bool
    private let onSelect: () -> Void

    init(email: String, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.email = email
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    var body: some View {
        HStack {
            SquircleThumbnail(data: .initials(String(email.prefix(2).uppercased())),
                              tintColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1)

            Spacer()

            Text(email)
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            RoundedCircleCheckbox(isChecked: isSelected)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
    }
}
