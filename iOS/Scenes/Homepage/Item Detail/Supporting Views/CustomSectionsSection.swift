//
// CustomSectionsSection.swift
// Proton Pass - Created on 10/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import SwiftUI

struct CustomSectionsSection: View {
    let sections: [CustomSection]
    let contentType: ItemContentType
    let isFreeUser: Bool
    let showIcon: Bool
    let onCopyHiddenText: (String) -> Void
    let onCopyTotpToken: (String) -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ForEach(sections) {
            view(for: $0)
        }
    }
}

private extension CustomSectionsSection {
    func view(for section: CustomSection) -> some View {
        Section {
            if section.content.isEmpty {
                Text("Empty section")
                    .font(.callout.italic())
                    .adaptiveForegroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                CustomFieldSections(itemContentType: contentType,
                                    fields: section.content,
                                    isFreeUser: isFreeUser,
                                    showIcon: showIcon,
                                    onSelectHiddenText: onCopyHiddenText,
                                    onSelectTotpToken: onCopyTotpToken,
                                    onUpgrade: onUpgrade)
            }
        } header: {
            Text(verbatim: section.title)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstant.sectionPadding)
                .padding(.vertical, DesignConstant.sectionPadding)
        }
    }
}
