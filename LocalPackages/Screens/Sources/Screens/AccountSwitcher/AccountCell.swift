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

public protocol AccountCellDetail: Sendable {
    var id: String { get }
    var initials: String { get }
    var displayName: String { get }
    var email: String { get }
}

public struct AccountCell: View {
    let detail: any AccountCellDetail
    let showSwitcher: Bool
    let animationNamespace: Namespace.ID

    enum EffectID: String {
        case initials
        case displayName
        case email
        case chevron
    }

    public init(detail: any AccountCellDetail,
                showSwitcher: Bool,
                animationNamespace: Namespace.ID) {
        self.detail = detail
        self.showSwitcher = showSwitcher
        self.animationNamespace = animationNamespace
    }

    public var body: some View {
        HStack {
            initials
                .opacity(0)
                .overlay {
                    if !showSwitcher {
                        initials
                            .matchedGeometryEffect(id: EffectID.initials, in: animationNamespace)
                    }
                }

            VStack(alignment: .leading) {
                displayName
                    .opacity(0)
                    .overlay {
                        if !showSwitcher {
                            displayName
                                .matchedGeometryEffect(id: EffectID.displayName, in: animationNamespace)
                        }
                    }

                email
                    .opacity(0)
                    .overlay {
                        if !showSwitcher {
                            email
                                .matchedGeometryEffect(id: EffectID.email, in: animationNamespace)
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            chevron
                .opacity(0)
                .overlay {
                    if !showSwitcher {
                        chevron
                            .matchedGeometryEffect(id: EffectID.chevron, in: animationNamespace)
                    }
                }
        }
        .padding()
        .roundedEditableSection()
        .animation(.default, value: showSwitcher)
    }
}

/// Reusable views for `AccountCell` & `AccountList`
extension AccountCell {
    static func viewForInitials(_ text: String) -> some View {
        ZStack {
            PassColor.interactionNormMajor2.toColor
            Text(verbatim: text)
                .foregroundStyle(PassColor.textInvert.toColor)
                .fontWeight(.medium)
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    static func viewForDisplayName(_ text: String) -> some View {
        Text(verbatim: text)
            .foregroundStyle(PassColor.textNorm.toColor)
    }

    static func viewForEmail(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.caption)
            .foregroundStyle(PassColor.textWeak.toColor)
    }
}

private extension AccountCell {
    var initials: some View {
        Self.viewForInitials(detail.initials)
    }

    var displayName: some View {
        Self.viewForDisplayName(detail.displayName)
    }

    var email: some View {
        Self.viewForEmail(detail.email)
    }

    var chevron: some View {
        SwiftUIImage(image: IconProvider.chevronDown,
                     width: 20,
                     tintColor: PassColor.textWeak)
    }
}
