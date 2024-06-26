//
// AccountList.swift
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

struct AccountList: View {
    let details: [any AccountCellDetail]
    let activeId: String
    let animationNamespace: Namespace.ID
    let onSelectAccountId: (String) -> Void
    let onAddAccount: () -> Void

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding / 2) {
            ForEach(details, id: \.id) { detail in
                row(for: detail)
                PassDivider()
                    .padding(.vertical, DesignConstant.sectionPadding / 2)
            }

            addAcountRow
        }
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.backgroundNorm.toColor)
        .roundedEditableSection()
    }
}

private extension AccountList {
    @ViewBuilder
    func row(for detail: any AccountCellDetail) -> some View {
        let isActive = detail.id == activeId
        HStack {
            HStack {
                ZStack {
                    PassColor.interactionNormMajor2.toColor
                    Text(verbatim: detail.initials)
                        .foregroundStyle(PassColor.textInvert.toColor)
                        .fontWeight(.medium)
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .if(isActive) { view in
                    view
                        .matchedGeometryEffect(id: AccountCell.EffectID.initials, in: animationNamespace)
                }

                VStack(alignment: .leading) {
                    Text(verbatim: detail.displayName)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .if(isActive) { view in
                            view
                                .matchedGeometryEffect(id: AccountCell.EffectID.displayName,
                                                       in: animationNamespace)
                        }

                    Text(verbatim: detail.email)
                        .font(.caption)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .if(isActive) { view in
                            view
                                .matchedGeometryEffect(id: AccountCell.EffectID.email, in: animationNamespace)
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if isActive {
                    icon(with: IconProvider.checkmark,
                         foregroundColor: PassColor.interactionNormMajor2)
                        .if(isActive) { view in
                            view
                                .matchedGeometryEffect(id: AccountCell.EffectID.chevron, in: animationNamespace)
                        }
                }
            }
            .contentShape(.rect)
            .onTapGesture {
                onSelectAccountId(detail.id)
            }

            Menu(content: {
                Button(action: {},
                       label: { Text(verbatim: "Action 1") })
                Button(action: {},
                       label: { Text(verbatim: "Action 2") })
            }, label: {
                icon(with: IconProvider.threeDotsVertical,
                     foregroundColor: PassColor.textWeak)
            })
        }
    }

    var addAcountRow: some View {
        HStack {
            icon(with: IconProvider.userPlus,
                 foregroundColor: PassColor.textNorm)
            Text(verbatim: "Add account")
                .foregroundStyle(PassColor.textNorm.toColor)
            Spacer()
        }
        .contentShape(.rect)
        .onTapGesture(perform: onAddAccount)
    }

    func icon(with uiImage: UIImage, foregroundColor: UIColor) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 24)
            .foregroundStyle(foregroundColor.toColor)
    }
}
