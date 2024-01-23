//
// NotLoggedInView.swift
// Proton Pass - Created on 23/01/2024.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public extension NotLoggedInView {
    enum Variant {
        case autoFillExtension, shareExtension

        var message: String {
            switch self {
            case .autoFillExtension:
                #localized("Please log in in order to use Proton Pass AutoFill extension")
            case .shareExtension:
                #localized("Please log in in order to use Proton Pass Share extension")
            }
        }
    }
}

public struct NotLoggedInView: View {
    private let variant: Variant
    private let onCancel: () -> Void

    public init(variant: Variant, onCancel: @escaping () -> Void) {
        self.variant = variant
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack {
            Text(variant.message)
                .multilineTextAlignment(.center)
                .foregroundColor(PassColor.textNorm.toColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             action: onCancel)
            }
        }
        .navigationStackEmbeded()
    }
}
