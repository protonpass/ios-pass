//
// PasskeyDetailRow.swift
// Proton Pass - Created on 23/02/2024.
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct PasskeyDetailRow: View {
    let passkey: Passkey
    var borderColor: UIColor = PassColor.inputBorderNorm
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.passkey,
                                  color: ItemContentType.login.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Passkey")
                    .sectionTitleText() +
                    Text(verbatim: " • ")
                    .sectionTitleText() +
                    Text(verbatim: passkey.domain)
                    .sectionTitleText()

                Text(passkey.userName)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            ItemDetailSectionIcon(icon: IconProvider.chevronRight, width: 12)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: ItemContentType.login.normMinor2Color,
                              borderColor: borderColor)
        .contentShape(.rect)
        .onTapGesture(perform: onTap)
    }
}
