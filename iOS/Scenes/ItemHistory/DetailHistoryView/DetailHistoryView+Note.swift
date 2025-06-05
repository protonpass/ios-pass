//
// DetailHistoryView+Note.swift
// Proton Pass - Created on 12/01/2024.
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
import SwiftUI

extension DetailHistoryView {
    var noteView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            HStack(alignment: .firstTextBaseline) {
                Text(itemContent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(DesignConstant.sectionPadding)
                    .roundedDetailSection(borderColor: borderColor(for: \.name))
                Spacer()
            }

            Spacer(minLength: 16)

            noteRow(item: itemContent)
                .padding(DesignConstant.sectionPadding)
                .roundedDetailSection(borderColor: borderColor(for: \.note))

            customFields(item: itemContent)
                .padding(.top, 8)

            attachmentsSection(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
