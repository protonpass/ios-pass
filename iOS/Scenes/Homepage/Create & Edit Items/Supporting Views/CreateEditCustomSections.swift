//
// CreateEditCustomSections.swift
// Proton Pass - Created on 05/03/2025.
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditCustomSections<Field: Hashable>: View {
    let addFieldButtonTitle: String
    let contentType: ItemContentType
    let focusedField: FocusState<Field?>.Binding
    let field: (CustomField) -> Field
    @Binding var sections: [CustomSection]
    let onEditSectionTitle: (CustomSection) -> Void
    let onEditFieldTitle: (CustomField) -> Void
    let onAddMoreField: (CustomSection) -> Void

    var body: some View {
        ForEach($sections) { section in
            Section(content: {
                if !section.wrappedValue.isCollapsed {
                    content(for: section)
                }
            }, header: {
                CustomSectionHeader(title: .verbatim(section.wrappedValue.title),
                                    collapsed: section.wrappedValue.isCollapsed,
                                    editable: true,
                                    onToggle: { section.wrappedValue.isCollapsed.toggle() },
                                    onEditTitle: { onEditSectionTitle(section.wrappedValue) },
                                    onRemove: { sections.removeAll { $0.id == section.wrappedValue.id } })
            })
        }
    }
}

private extension CreateEditCustomSections {
    func content(for section: Binding<CustomSection>) -> some View {
        VStack(alignment: .leading) {
            if !section.wrappedValue.content.isEmpty {
                VStack(spacing: DesignConstant.sectionPadding) {
                    ForEach(Array(section.wrappedValue.content.enumerated()),
                            id: \.element.id) { index, customField in
                        VStack {
                            if index > 0 {
                                PassSectionDivider()
                            }
                            EditCustomFieldView(focusedField: focusedField,
                                                field: field(customField),
                                                contentType: contentType,
                                                value: section.content[index],
                                                showIcon: false,
                                                roundedSection: false,
                                                onEditTitle: { onEditFieldTitle(customField) },
                                                onRemove: { section.wrappedValue.content.remove(customField) })
                        }
                    }
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            }

            CapsuleLabelButton(icon: IconProvider.plus,
                               title: addFieldButtonTitle,
                               titleColor: contentType.normMajor2Color,
                               backgroundColor: contentType.normMinor1Color,
                               maxWidth: nil,
                               action: { onAddMoreField(section.wrappedValue) })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
