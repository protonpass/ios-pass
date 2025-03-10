//
// AddCustomFieldAndSectionView.swift
// Proton Pass - Created on 04/03/2025.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct AddCustomFieldAndSectionView: View {
    let supportAddField: Bool
    let onAddField: (() -> Void)?
    let supportAddSection: Bool
    let onAddSection: (() -> Void)?

    public init(supportAddField: Bool = false,
                onAddField: (() -> Void)? = nil,
                supportAddSection: Bool = false,
                onAddSection: (() -> Void)? = nil) {
        self.supportAddField = supportAddField
        self.onAddField = onAddField
        self.supportAddSection = supportAddSection
        self.onAddSection = onAddSection
    }

    public var body: some View {
        HStack {
            if supportAddField, let onAddField {
                CapsuleLabelButton(icon: IconProvider.plus,
                                   title: #localized("Add field"),
                                   titleColor: PassColor.interactionNormMajor2,
                                   backgroundColor: PassColor.interactionNormMinor1,
                                   fontWeight: .medium,
                                   height: 44,
                                   action: onAddField)
            }

            if supportAddField, supportAddSection {
                Spacer()
            }

            if supportAddSection, let onAddSection {
                CapsuleLabelButton(icon: PassIcon.hamburgerPlus,
                                   title: #localized("Add section"),
                                   titleColor: PassColor.interactionNormMajor2,
                                   backgroundColor: .clear,
                                   border: .init(width: 1,
                                                 color: PassColor.interactionNormMinor1),
                                   fontWeight: .medium,
                                   height: 44,
                                   action: onAddSection)
            }
        }
    }
}
