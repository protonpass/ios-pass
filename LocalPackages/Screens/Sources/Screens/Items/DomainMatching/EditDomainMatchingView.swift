//
// EditDomainMatchingView.swift
// Proton Pass - Created on 22/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

private enum DomainMatchingType: Int, Hashable {
    case basic = 0
    case advanced = 1

    var title: String {
        switch self {
        case .basic: #localized("Basic")
        case .advanced: #localized("Advanced")
        }
    }
}

public struct EditDomainMatchingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var url: IdentifiableObject<AutofillUrl>
    @State private var selectedType: DomainMatchingType
    let itemContentType: ItemContentType

    public init(url: IdentifiableObject<AutofillUrl>, itemContentType: ItemContentType) {
        _url = .init(initialValue: url)
        _selectedType = .init(initialValue: url.value.mode.isBasic ? .basic : .advanced)
        self.itemContentType = itemContentType
    }

    public var body: some View {
        NavigationStack {
            content
                .background(PassColor.backgroundNorm)
                .navigationTitle(Text("URL matching", bundle: .module))
                .tint(itemContentType.normMajor1Color)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CircleButton(icon: IconProvider.cross,
                                     iconColor: itemContentType.normMajor2Color,
                                     backgroundColor: itemContentType.normMinor1Color,
                                     accessibilityLabel: "Close",
                                     action: dismiss.callAsFunction)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        CapsuleTextButton(title: #localized("Save"),
                                          titleColor: PassColor.textInvert,
                                          backgroundColor: itemContentType.normMajor1Color,
                                          action: dismiss.callAsFunction)
                    }
                }
        }
    }
}

private extension EditDomainMatchingView {
    var content: some View {
        VStack {
            EnumSegmentedPicker(selection: $selectedType,
                                options: [
                                    DomainMatchingType.basic.title,
                                    DomainMatchingType.advanced.title
                                ])
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
